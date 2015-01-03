#  This file is part of Docbook2Pod.
#
#  This software is copyright (c) 2015 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#


#  Convert Docbook to POD
#
package Docbook2Pod;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION);
use warnings;
no warnings qw(uninitialized);
sub BEGIN {local $^W=0}


#  External Packages
#
use Docbook2Pod::Util;
use Docbook2Pod::Constant;
use Data::Dumper;
use File::Temp;
use File::Find;
use Cwd;


#  Data Dumper formatting
#
$Data::Dumper::Indent=1;
$Data::Dumper::Terse=1;


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.002';


#  All done, init finished
#
1;


#===================================================================================================


sub docbook2pod_xml {


    #  Convert XML files to POD
    #
    my ($self, $xml_sr)=@_;
    
    
    #  Create temp dn
    #
    my $tmp_dn=File::Temp->newdir( CLEANUP=>1 ) ||
        return err("unable to create new temp dir, $!");
    eval {
        require IPC::Run3;
        IPC::Run3->import(qw(run3));
        1;
    } || return err('unable to load IPC::Run3');
    
    
    #  Run the XSLT conversion to man page
    #
    { 
        my $command_ar=
            $XSLTPROC_CMD_CR->($XSLTPROC_EXE, "$tmp_dn/", $XSLTPROC_XSL, '-');
        run3($command_ar, $xml_sr, \undef, \undef) ||
            return err('unable to run3 %s', Dumper($command_ar));
        if ((my $err=$?) >> 8) {
            return err("error $err on run3 of: %s", Dumper($command_ar));
        }
    }
    
    
    #  Look for output in temp dir (xsltproc will name based on docbook content - could be anything)
    #
    my $man_fn;
    my $wanted_cr=sub {
        return unless -f $File::Find::name;
        $man_fn=$File::Find::name;
    };
    find($wanted_cr, $tmp_dn);
    $man_fn ||
        return err('unable to find xsltproc output file');
    
    
    #  Run through groff to cleanup and send output to scalar
    #
    my $groff;
    { 
        my $command_ar=
            $GROFF_CMD_CR->($GROFF_EXE, $man_fn);
        run3($command_ar, \undef, \$groff, \undef) ||
            return err('unable to run3 %s', Dumper($command_ar));
        if ((my $err=$?) >> 8) {
            return err("error $err on run3 of: %s", Dumper($command_ar));
        }
    }
    
    
    #  Now through rman to create final POD file
    #
    my $pod;
    { 
        my $command_ar=
            $RMAN_CMD_CR->($RMAN_EXE);
        run3($command_ar, \$groff, \$pod, \undef) ||
            return err('unable to run3 %s', Dumper($command_ar));
        if ((my $err=$?) >> 8) {
            return err("error $err on run3 of: %s", Dumper($command_ar));
        }
    }
    
    
    #  Done
    #
    return \$pod;
    
}


sub pod_replace {

    
    #  Find and replace POD in a file
    #
    my ($self, $fn, $pod_sr)=@_;
    
    
    #  Try to load PPI
    #
    eval {
        require PPI;
        1;
    } || return err('unable to load PPI module - is it installed ?');


    #  Create new PPI documents from supplied file and new POD
    #
    my $ppi_doc_or=PPI::Document->new($fn);
    my $ppi_pod_or=PPI::Document->new($pod_sr);
    

    #  Prune existing POD
    #
    $ppi_doc_or->prune('PPI::Token::Pod');
    if (my $ppi_doc_end_or=$ppi_doc_or->find_first('PPI::Statement::End')) {
        $ppi_doc_end_or->prune('PPI::Token::Comment');
        $ppi_doc_end_or->prune('PPI::Token::Whitespace');
    }else {
        $ppi_doc_or->add_element(PPI::Token::Separator->new('__END__'));
        $ppi_doc_or->add_element(PPI::Token::Whitespace->new("\n"));
    }
    
    
    #  Append new POD
    #
    $ppi_doc_or->add_element($ppi_pod_or);
    
    
    #  Save
    #
    return $ppi_doc_or->save($fn);
    
} 

__END__

=head1 Name

Docbook2Pod - Convert Docbook to POD using xsltproc, groff and polyglot
rman utilities

=head1 B<Synopsis>

use Docbook2Pod

my $pod_sr=Docbook2Pod->docbook2pod_xml(\$docbook_xml);

print ${$pod_sr}


=over 5


=item ...






=back

my $fn=Docbook2Pod->pod_replace('some_file_name', $pod_sr);

=head1 B<Description>

This module provides methods to convert Docbook XML to POD and to merge
that POD into a Perl document.

=head1 B<Background>

This modules allows module documentation to be written as Docbook
refentry articles and then converted to POD - and optionally merged
into the module they are documenting. This allows for the use of
Docbook editors to maintain documentation as separate entities if
desired.

=head1 B<Author>

Written by Andrew Speer, <andrew.speer@isolutions.com.au>

=head1 B<Copying>

This file is part of Docbook2Pod.

This software is copyright (c) 2015 by Andrew Speer
<andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>

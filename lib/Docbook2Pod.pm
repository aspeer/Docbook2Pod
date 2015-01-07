#  #  This file is part of ExtUtils::Git.
#  #
#  #  This software is copyright (c) 2015 by Andrew Speer <andrew.speer@isolutions.com.au>.
#  #
#  #  This is free software; you can redistribute it and/or modify it under
#  #  the same terms as the Perl 5 programming language system itself.
#  #
#  #  Full license text is available at:
#  #
#  #  <http://dev.perl.org/licenses/>
#  #
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
use IPC::Run3;
use Markdown::Pod;
 

#  Data Dumper formatting
#
$Data::Dumper::Indent=1;
$Data::Dumper::Terse=1;


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.003';


#  All done, init finished
#
1;


#===================================================================================================


sub docbook2pod_xml {


    #  Convert XML files to POD
    #
    my ($self, $xml_sr)=@_;
    
    
    #  Run the Pandoc conversion to markup
    #
    my $markdown;
    { 
        my $command_ar=
            $PANDOC_CMD_CR->($PANDOC_EXE, '-');
        run3($command_ar, $xml_sr, \$markdown, \undef) ||
            return err('unable to run3 %s', Dumper($command_ar));
        if ((my $err=$?) >> 8) {
            return err("error $err on run3 of: %s", Dumper($command_ar));
        }
    }
    
    
    #  Now run through Markdown::Pod
    #
    my $m2p_or=Markdown::Pod->new() ||
        return err('unable to create new Markdown::Pod object');
    my $pod = $m2p_or->markdown_to_pod(
            dialect  => $MARKDOWN_DIALECT,
            markdown => $markdown,
    ) || return err('unable to created pod from markdown');


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
        $ppi_doc_or->add_element(PPI::Token::Separator->new("__END__\n\n"));
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
=head1 Docbook2Pod

Docbook2Pod -- convert Docbook XML files into POD using Pandoc and Markdown::Pod


=head1 Synopsis

    #  From command line
    #
    docbook2pod foo.xml
    
    
    #  From Perl script
    #
    use Docbook2Pod;
    my $pod_sr=Docbook2Pod->docbook2pod_xml(\$docbook_xml);
    print ${$pod_sr}
    ...
    my $fn=Docbook2Pod->pod_replace('some_file_name', $pod_sr);



=head1 Description

This module provides methods to convert Docbook XML to POD, and to merge POD into a Perl document.


=head1 Background

This modules allows module documentation to be written as Docbook article and then converted to POD - and optionally merged into the module being documented. This allows for the use of Docbook editors to maintain documentation as separate entities if desired.


=head1 Author

Written by Andrew Speer, 


=head1 Copying

This file is part of Docbook2Pod.

This software is copyright (c) 2015 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>

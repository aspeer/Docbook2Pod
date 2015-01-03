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
package Docbook2Pod::Constant;


#  Compiler Pragma
#
use strict qw(vars);
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);
use warnings;
no warnings qw(uninitialized);
local $^W=0;


#  Needed external utils
#
use File::Spec;
use File::Find;
use Cwd qw(abs_path);


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.001';


#===================================================================================================


#  Get module file name and path, derive name of file to store local constants
#
my $module_fn=abs_path(__FILE__);
my $local_fn="${module_fn}.local";


#  Get dn for path ref and make utility function to construct abs path for a file
#
(my $module_dn=$module_fn)=~s/\.pm$//;


sub fn {

    File::Spec->catfile($module_dn, @_)

}


#  Find file in path
#
sub bin_find {


    #  Find a binary file
    #
    my @bin_fn=@_;
    my $bin_fn;


    #  Find the bin file/files if given array ref. If not supplied as array ref
    #  convert.
    #
    my @dir=grep {-d $_} split(/:|;/, $ENV{'PATH'});
    my %dir=map {$_ => 1} @dir;
    DIR: foreach my $dir (@dir) {
        next unless delete $dir{$dir};
        next unless -d $dir;
        foreach my $bin (@bin_fn) {
            if (-f File::Spec->catfile($dir, $bin)) {
                $bin_fn=File::Spec->catfile($dir, $bin);
                last DIR;
            }
        }
    }


    #  Normalize fn
    #
    $bin_fn=File::Spec->canonpath($bin_fn) if $bin_fn;


    #  Return
    #
    return $bin_fn;

}



#  Find style sheets
#
sub fn_stylesheet_find {


    #  Get list of dirs to search
    #
    my @dn=@_;
    my $fn;
    my $wanted_cr=sub {
        return unless $File::Find::name=~/\Qmanpages\/docbook.xsl\E$/;
        $fn=$File::Find::name;
    };
    find($wanted_cr, @dn);
    return $fn;
    
}


#  Constants
#  <<<
%Constant=(

    XSLTPROC_EXE        => &bin_find(qw(xsltproc xsltproc.exe)), 

    GROFF_EXE           => &bin_find(qw(groff groff.exe)), 

    RMAN_EXE            => &bin_find(qw(rman rman.exe)),
        
    XSLTPROC_XSL        => &fn_stylesheet_find('/usr/share/sgml/docbook/'),
        
    XSLTPROC_CMD_CR     => sub {return [
        shift(),        # XSTLTPROC_EXE
        '-o',           # Output to temp dir
        shift(),        # Temp dn
        shift(),        # XSLTPROC_XSL
        shift(),        # File name
    ]},

    GROFF_CMD_CR        => sub {return [
        shift(),        # GROFF_EXE
        '-e',
        '-mandoc',
        '-Tascii',
        shift(),
    ]},

    RMAN_CMD_CR         => sub {return [
        shift(),        # RMAN_EXE
        '-fpod',
    ]},
    
    
    OPT_XMLSUFFIX       => '.xml',
    OPT_PODSUFFIX       => '.pod', 


    #  Local constants override anything above
    #
    %{do($local_fn)}

);
#  >>>


#  Export constants to namespace, place in export tags
#
require Exporter;
@ISA=qw(Exporter);
foreach (keys %Constant) {${$_}=$ENV{$_} ? $Constant{$_}=$ENV{$_} : $Constant{$_}}    ## no critic
@EXPORT=map {'$' . $_} keys %Constant;
@EXPORT_OK=@EXPORT;
%EXPORT_TAGS=(all => [@EXPORT_OK]);
$_=\%Constant;


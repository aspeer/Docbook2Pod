#
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
package Docbook2Pod::Util;


use strict;
use vars qw($VERSION @ISA @EXPORT);  ## no critic
use warnings;
no warnings qw(uninitialized);


#  External modules
#
require Exporter;
use Carp;


#  Export functions
#
@ISA=qw(Exporter);
@EXPORT=qw(err msg arg);


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.007';


#==================================================================================================


sub arg {

    #  Get args, does nothing but intercept distname for messages, convert to param
    #  hash
    #
    my (%param, @argv);
    (@param{qw(NAME NAME_SYM DISTNAME DISTVNAME VERSION VERSION_SYM VERSION_FROM LICENSE AUTHOR TO_INST_PM EXE_FILES DIST_DEFAULT_TARGET SUFFIX)}, @argv)=@_;
    $param{'TO_INST_PM_AR'}=[split /\s+/, $param{'TO_INST_PM'}];
    $param{'EXE_FILES_AR'}=[split /\s+/,  $param{'EXE_FILES'}];
    $param{'ARGV_AR'}=\@argv;
    return \%param

}


sub err {


    #  Quit on errors
    #
    my $msg=shift();
    return croak &fmt("*error*\n\n" . ucfirst($msg), @_);

}


sub fmt {


    #  Format message nicely. Always called by err or msg so caller=2
    #
    my $message=sprintf(shift(), @_);
    chomp($message);
    my $caller=(split(/:/, (caller(2))[3]))[-1];
    $caller=~s/^_?!(_)//;
    my $format=' @<<<<<<<<<<<<<<<<<<<<<< @<';
    formline $format, $caller . ':', undef;
    $message=$^A . $message; $^A=undef;
    return $message;

}


sub msg {


    #  Print message
    #
    return CORE::print &fmt(@_), "\n";

}

1;


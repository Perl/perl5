#!/usr/bin/perl

$JPL_SRC = "..";

use ExtUtils::MakeMaker;
use Config;

eval `$JPL_SRC/setvars -perl`;

$java = $ENV{JAVA_HOME};
$jpl = $ENV{JPL_HOME};

$ARCHNAME = $Config{archname};

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME	=> 'JNI',
    VERSION_FROM => 'JNI.pm',
    LIBS	=> ["-R$Config{archlib}/CORE -L$Config{archlib}/CORE -R$jpl/lib/$ARCHNAME -L$jpl/lib/$ARCHNAME -lperl -lPerlInterpreter"],
    DEFINE	=> '',
    LINKTYPE => 'dynamic',
    INC	=> "-I$java/include -I$java/include/$^O -I$java/include/genunix",
);

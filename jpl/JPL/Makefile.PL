#!/usr/bin/perl

$JPL_SRC = "..";

use Config;

eval `$JPL_SRC/setvars -perl`;

open(MAKEFILE, ">Makefile");

print MAKEFILE <<"SUBS";
PERL = perl$]
ARCHNAME = $Config{archname}
JAVA_HOME = $ENV{JAVA_HOME}
JPL_HOME = $ENV{JPL_HOME}
PERLARCHDIR = $Config{archlib}

SUBS

print MAKEFILE <<'NOSUBS';

all:

debug:

test:

install:
	mkdir -p $(JPL_HOME)/perl/JPL
	cp *.p[ml] $(JPL_HOME)/perl/JPL

clean:

NOSUBS

close MAKEFILE;

#!/usr/bin/perl

use strict;

BEGIN {
    # Get function prototypes
    require 'regen/regen_lib.pl';
    unshift @INC, 'ext/ExtUtils-Miniperl/lib';
}

use ExtUtils::Miniperl;

my $fh = open_new('miniperlmain.c');
writemain($fh);
close_and_rename($fh);

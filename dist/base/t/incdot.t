#!/usr/bin/perl -w

use strict;

use base ();

use Test::More tests => 2;

if ($INC[-1] ne '.') { push @INC, '.' }

my $inc = quotemeta "@INC[0..$#INC-1]";

eval { 'base'->import("foo") };
like $@, qr/\@INC contains: $inc\).\)/,
    'Error does not list final dot in @INC (or mention use lib)';
eval { 'base'->import('t::lib::Dummy') };
like $@, qr<\@INC contains: $inc\).\n(?x:
           )    If you mean to load t/lib/Dummy\.pm from the current >,
    'special cur dir message for existing files in . that are ignored';

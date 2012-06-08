#!/usr/bin/perl -Tw
#
# t/eval.t -- Test suite for $@ preservation with constants.
#
# Copyright 2012 Russ Allbery <rra@stanford.edu>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use Test::More tests => 5;

BEGIN {
    delete $ENV{ANSI_COLORS_DISABLED};
    use_ok ('Term::ANSIColor', qw/:constants/);
}

# Ensure that using a constant doesn't leak anything in $@.
is ((BOLD 'test'), "\e[1mtest", 'BOLD works');
is ($@, '', '... and $@ is empty');

# Store something in $@ and ensure it doesn't get clobbered.
eval 'sub { syntax';
is ((BLINK 'test'), "\e[5mtest", 'BLINK works after eval failure');
isnt ($@, '', '... and $@ still contains something useful');

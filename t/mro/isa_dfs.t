#!perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require "./test.pl";
}

use strict;

plan 'no_plan';

# package klonk doesn't have a stash.

package kapow;

# No parents

package urkkk;

# 1 parent
@urkkk::ISA = 'klonk';

package kayo;

# 2 parents
@urkkk::ISA = ('klonk', 'kapow');

package thwacke;

# No parents, has @ISA
@thwacke::ISA = ();

package zzzzzwap;

@zzzzzwap::ISA = ('thwacke', 'kapow');

package whamm;

@whamm::ISA = ('kapow', 'thwacke');

package main;

require mro;

foreach my $package (qw(klonk urkkk kapow kayo thwacke zzzzzwap whamm)) {
    my $ref = bless [], $package;
    my $isa = mro::get_linear_isa($package);

    foreach my $class ($package, @$isa, 'UNIVERSAL') {
	isa_ok($ref, $class, $package);
    }
}

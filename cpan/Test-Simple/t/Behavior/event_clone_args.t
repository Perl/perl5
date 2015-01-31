use Test::More;
use strict;
use warnings;

use B;
use Test::Stream::Tester qw/intercept/;

my @events;

my $x1 = \(my $y1);
push @events => intercept { note $x1 };
is(B::svref_2object($x1)->REFCNT, 2, "Note does not store a ref");

my $x2 = \(my $y2);
push @events => intercept { diag $x2 };
is(B::svref_2object($x2)->REFCNT, 2, "diag does not store a ref");

my $x3 = \(my $y3);
push @events => intercept { ok($x3, "Generating") };
is(B::svref_2object($x3)->REFCNT, 2, "ok does not store a ref");

done_testing;

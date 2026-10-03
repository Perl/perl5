#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

use strict;
use warnings;

my $truevar  = (5 == 5);
my $falsevar = (5 == 6);

cmp_ok($truevar, '==', 1);
cmp_ok($truevar, 'eq', "1");

cmp_ok($falsevar, '==', 0);
cmp_ok($falsevar, 'eq', "");

{
    # Check that boolean COW string buffer is safe to copy into new SVs and
    # doesn't get corrupted by inplace mutations
    my $x = $truevar;
    $x =~ s/1/t/;

    cmp_ok($x, 'eq', "t");
    cmp_ok($truevar, 'eq', "1");

    my $y = $truevar;
    substr($y, 0, 1, "T");

    cmp_ok($y, 'eq', "T");
    cmp_ok($truevar, 'eq', "1");
}

# GH #19987: these operations crashed with PERL_NO_COW.
for my $value (0, 1) {
    my $x = !!$value;
    $x .= "x";
    is($x, $value ? "1x" : "x", "append to boolean $value");

    $x = !!$value;
    undef $x;
    ok(!defined $x, "undef boolean $value");

    my $a = [!!$value];
    undef $a;
    ok(!defined $a, "free boolean $value");
}

done_testing();

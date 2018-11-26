#!perl
use strict;
use Test::More;

use XS::APItest;
use Config;

unless ($Config{d_double_has_inf} && $Config{d_double_has_nan}) {
    plan skip_all => "the doublekind $Config{doublekind} does not have inf/nan";
}

my $nan = "NaN" + 0;
my $large = 256 ** ($Config{ivsize}+1);
my $small = -$large;
my $max = int(~0 / 2);
my $min = -$max - 1;
my $umax = ~0;
my $i32_max = 0x7fffffff;
my $i32_min = -$i32_max - 1;
my $u32_max = 0xffffffff;
my $i32_min_as_u32 = 0x80000000;
my $iv_min_as_uv = 0x1 << ($Config{ivsize} * 8 - 1);

*U_32 = \&XS::APItest::numeric::U_32;
*I_32 = \&XS::APItest::numeric::I_32;
*U_V = \&XS::APItest::numeric::U_V;
*I_V = \&XS::APItest::numeric::I_V;

is(U_32(0.0), 0, "zero to u32");
is(U_32($nan), 0, "nan to u32");
is(U_32($large), $u32_max, "large to u32");
is(U_32($min), $i32_min_as_u32, "small to u32");
is(U_32($u32_max), $u32_max, "u32_max to u32");

is(I_32(0.0), 0, "zero to i32");
is(I_32($nan), 0, "nan to i32");
# this surprised me, but printf("%d"), which does iv = nv at the
# end produces the same value
is(I_32($large), -1, "large ($large) to i32");
is(I_32($min), $i32_min, "small to i32");
is(I_32($i32_max), $i32_max, "i32_max to i32");

is(U_V(0.0), 0, "zero to uv");
is(U_V($nan), 0, "nan to uv");
is(U_V($large), $umax, "large to uv");
is(U_V($min), $iv_min_as_uv, "small to uv");
# a large UV might not be exactly representable in a double
#is(U_V($umax), $umax, "u32_max to uv");

is(I_V(0.0), 0, "zero to iv");
is(I_V($nan), 0, "nan to iv");
# this surprised me, but printf("%d"), which does iv = nv at the
# end produces the same value
is(I_V($large), -1, "large ($large) to iv");
is(I_V($min), $iv_min, "small to iv");
# a large IV might not be exactly representable in a double
#is(I_V($iv_max), $iv_max, "iv_max to iv");

done_testing();

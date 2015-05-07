#!perl -w

use strict;

use POSIX ':math_h_c99';
use Test::More;

use Config;

# These tests are mainly to make sure that these arithmetic functions
# exist and are accessible.  They are not meant to be an exhaustive
# test for the interface.

sub between {
    my ($low, $have, $high, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    cmp_ok($have, '>=', $low, $desc);
    cmp_ok($have, '<=', $high, $desc);
}

is(acos(1), 0, "Basic acos(1) test");
between(3.14, acos(-1), 3.15, 'acos(-1)');
between(1.57, acos(0), 1.58, 'acos(0)');
is(asin(0), 0, "Basic asin(0) test");
cmp_ok(asin(1), '>', 1.57, "Basic asin(1) test");
cmp_ok(asin(-1), '<', -1.57, "Basic asin(-1) test");
cmp_ok(asin(1), '==', -asin(-1), 'asin(1) == -asin(-1)');
is(atan(0), 0, "Basic atan(0) test");
between(0.785, atan(1), 0.786, 'atan(1)');
between(-0.786, atan(-1), -0.785, 'atan(-1)');
cmp_ok(atan(1), '==', -atan(-1), 'atan(1) == -atan(-1)');
is(cosh(0), 1, "Basic cosh(0) test");  
between(1.54, cosh(1), 1.55, 'cosh(1)');
between(1.54, cosh(-1), 1.55, 'cosh(-1)');
is(cosh(1), cosh(-1), 'cosh(1) == cosh(-1)');
is(floor(1.23441242), 1, "Basic floor(1.23441242) test");
is(floor(-1.23441242), -2, "Basic floor(-1.23441242) test");
is(fmod(3.5, 2.0), 1.5, "Basic fmod(3.5, 2.0) test");
is(join(" ", frexp(1)), "0.5 1",  "Basic frexp(1) test");
is(ldexp(0,1), 0, "Basic ldexp(0,1) test");
is(log10(1), 0, "Basic log10(1) test"); 
is(log10(10), 1, "Basic log10(10) test");
is(join(" ", modf(1.76)), "0.76 1", "Basic modf(1.76) test");
is(sinh(0), 0, "Basic sinh(0) test"); 
between(1.17, sinh(1), 1.18, 'sinh(1)');
between(-1.18, sinh(-1), -1.17, 'sinh(-1)');
is(tan(0), 0, "Basic tan(0) test");
between(1.55, tan(1), 1.56, 'tan(1)');
between(1.55, tan(1), 1.56, 'tan(-1)');
cmp_ok(tan(1), '==', -tan(-1), 'tan(1) == -tan(-1)');
is(tanh(0), 0, "Basic tanh(0) test"); 
between(0.76, tanh(1), 0.77, 'tanh(1)');
between(-0.77, tanh(-1), -0.76, 'tanh(-1)');
cmp_ok(tanh(1), '==', -tanh(-1), 'tanh(1) == -tanh(-1)');

SKIP: {
    skip "no fpclassify", 4 unless $Config{d_fpclassify};
    is(fpclassify(1), FP_NORMAL, "fpclassify 1");
    is(fpclassify(0), FP_ZERO, "fpclassify 0");
    is(fpclassify(INFINITY), FP_INFINITE, "fpclassify INFINITY");
    is(fpclassify(NAN), FP_NAN, "fpclassify NAN");
}

sub near {
    my ($got, $want, $msg, $eps) = @_;
    $eps ||= 1e-6;
    cmp_ok(abs($got - $want), '<', $eps, $msg);
}

SKIP: {
    my $C99_SKIP = 59;

    unless ($Config{d_acosh}) {
        skip "no acosh, suspecting no C99 math", $C99_SKIP;
    }
    if ($^O =~ /Win32|VMS/) {
        skip "running in $^O, C99 math support uneven", $C99_SKIP;
    }
    near(M_SQRT2, 1.4142135623731, "M_SQRT2", 1e-9);
    near(M_E, 2.71828182845905, "M_E", 1e-9);
    near(M_PI, 3.14159265358979, "M_PI", 1e-9);
    near(acosh(2), 1.31695789692482, "acosh", 1e-9);
    near(asinh(1), 0.881373587019543, "asinh", 1e-9);
    near(atanh(0.5), 0.549306144334055, "atanh", 1e-9);
    near(cbrt(8), 2, "cbrt", 1e-9);
    near(cbrt(-27), -3, "cbrt", 1e-9);
    near(copysign(3.14, -2), -3.14, "copysign", 1e-9);
    near(expm1(2), 6.38905609893065, "expm1", 1e-9);
    near(expm1(1e-6), 1.00000050000017e-06, "expm1", 1e-9);
    is(fdim(12, 34), 0, "fdim 12 34");
    is(fdim(34, 12), 22, "fdim 34 12");
    is(fmax(12, 34), 34, "fmax 12 34");
    is(fmin(12, 34), 12, "fmin 12 34");
    is(hypot(3, 4), 5, "hypot 3 4");
    near(hypot(-2, 1), sqrt(5), "hypot -1 2", 1e-9);
    is(ilogb(255), 7, "ilogb 255");
    is(ilogb(256), 8, "ilogb 256");
    ok(isfinite(1), "isfinite 1");
    ok(!isfinite(Inf), "isfinite Inf");
    ok(!isfinite(NaN), "isfinite NaN");
    ok(isinf(INFINITY), "isinf INFINITY");
    ok(isinf(Inf), "isinf Inf");
    ok(!isinf(NaN), "isinf NaN");
    ok(!isinf(42), "isinf 42");
    ok(isnan(NAN), "isnan NAN");
    ok(isnan(NaN), "isnan NaN");
    ok(!isnan(Inf), "isnan Inf");
    ok(!isnan(42), "isnan Inf");
    cmp_ok(nan(), '!=', nan(), 'nan');
    near(log1p(2), 1.09861228866811, "log1p", 1e-9);
    near(log1p(1e-6), 9.99999500000333e-07, "log1p", 1e-9);
    near(log2(8), 3, "log2", 1e-9);
    is(signbit(2), 0, "signbit 2"); # zero
    ok(signbit(-2), "signbit -2"); # non-zero
    is(round(2.25), 2, "round 2.25");
    is(round(-2.25), -2, "round -2.25");
    is(round(2.5), 3, "round 2.5");
    is(round(-2.5), -3, "round -2.5");
    is(round(2.75), 3, "round 2.75");
    is(round(-2.75), -3, "round 2.75");
    is(trunc(2.25), 2, "trunc 2.25");
    is(trunc(-2.25), -2, "trunc -2.25");
    is(trunc(2.5), 2, "trunc 2.5");
    is(trunc(-2.5), -2, "trunc -2.5");
    is(trunc(2.75), 2, "trunc 2.75");
    is(trunc(-2.75), -2, "trunc -2.75");
    ok(isless(1, 2), "isless 1 2");
    ok(!isless(2, 1), "isless 2 1");
    ok(!isless(1, 1), "isless 1 1");
    ok(!isless(1, NaN), "isless 1 NaN");
    ok(isgreater(2, 1), "isgreater 2 1");
    ok(islessequal(1, 1), "islessequal 1 1");
    ok(isunordered(1, NaN), "isunordered 1 NaN");
    near(erf(1), 0.842700792949715, "erf 1", 1.5e-7);
    near(erfc(1), 0.157299207050285, "erfc 1", 1.5e-7);
    near(tgamma(9), 40320, "tgamma 9", 1.5e-7);
    near(lgamma(9), 10.6046029027452, "lgamma 9", 1.5e-7);

    # If adding more tests here, update also the $C99_SKIP
    # at the beginning of this SKIP block.
} # SKIP

done_testing();

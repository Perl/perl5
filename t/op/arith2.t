#!./perl

# These Config-dependent tests were originally in t/opbasic/arith.t,
# but moved here because t/opbasic/* should not depend on sophisticated
# constructs like "use Config;".

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

use Config;
use strict;

SKIP:
{
    if ($^O eq 'vos') {
        skip "VOS raises SIGFPE instead of producing infinity", 1;
    }
    elsif (!$Config{d_double_has_inf}) {
        skip "the IEEE infinity model is unavailable in this configuration", 1;
    }
    # The computation of $v should overflow and produce "infinity"
    # on any system whose max exponent is less than 10**1506.
    # The exact string used to represent infinity varies by OS,
    # so we don't test for it; all we care is that we don't die.
    #
    # Perl considers it to be an error if SIGFPE is raised.
    # Chances are the interpreter will die, since it doesn't set
    # up a handler for SIGFPE.  That's why this test is last; to
    # minimize the number of test failures.  --PG

    my $n = 5000;
    my $v = 2;
    while (--$n) {
        $v *= 2;
    }
    pass("infinity");
}


# [perl #120426]
# small numbers shouldn't round to zero if they have extra floating digits

SKIP:
{
    skip "not IEEE", 8 unless $Config{d_double_style_ieee};
    ok 0.153e-305 != 0.0,              '0.153e-305';
    ok 0.1530e-305 != 0.0,             '0.1530e-305';
    ok 0.15300e-305 != 0.0,            '0.15300e-305';
    ok 0.153000e-305 != 0.0,           '0.153000e-305';
    ok 0.1530000e-305 != 0.0,          '0.1530000e-305';
    ok 0.1530001e-305 != 0.0,          '0.1530001e-305';
    ok 1.17549435100e-38 != 0.0,       'min single';
    # For flush-to-zero systems this may flush-to-zero, see PERL_SYS_FPU_INIT
    ok 2.2250738585072014e-308 != 0.0, 'min double';
}

{
    my $nv_is_doubledouble = 0;
    if( $Config{nvtype} eq 'long double' &&
        $Config{longdblkind} >= 5 &&
        $Config{longdblkind} <= 8 ) { $nv_is_doubledouble = 1 }

    my @v = (2.5e-310); # Known to have sometimes been assigned as 0.
                        # See https://github.com/Perl/perl5/issues/9338.

    push @v, 4.9406564584124654e-324; # denorm_min when nvsize == 8 or
                                      # when nvtype is DoubleDouble.

    unless( $Config{nvsize} == 8 || $nv_is_doubledouble ) {
       # Append, to @v, the smallest positive value that's subnormal
       # for all remaining NV types. (This value is DENORM_MIN when
       # the NV is the 80-bit extended precision long double.)
       push @v, 3.64519953188247460253e-4951;
    }

    for my $n(@v) {
      # Check that $n has not been constant-folded to 0.
      cmp_ok($n, '>', 0, "$n > 0");
    }
}

done_testing();

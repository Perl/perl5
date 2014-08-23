#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

my $PInf = "Inf"  + 0;
my $NInf = "-Inf" + 0;
my $NaN  = "NaN"  + 0;

my @PInf = ("Inf", "inf", "INF", "Infinity", "INFINITY",
            "1.#INF", "1#INF");
my @NInf = map { "-$_" } @PInf;

my @NaN = ("NAN", "nan", "qnan", "SNAN", "NanQ", "NANS",
           "1.#QNAN", "1#SNAN", "1.#NAN", "1#IND",
           "NaN123", "NAN(123)", "nan%",
           "nanonano"); # RIP, Robin Williams.

my $inf_tests = 6 + 6 * @PInf + 5;
my $nan_tests = 5 + 2 * @NaN + 3;
my $infnan_tests = 4;

plan tests => $inf_tests + $nan_tests + $infnan_tests;

my $has_inf;
my $has_nan;

SKIP: {
  if ($PInf == 1 && $NINf == 1) {
    skip $inf_tests, "no infinity found";
  }

  $has_inf = 1;

  ok($PInf > 0, "positive infinity");
  ok($NInf < 0, "negative infinity");

  is($PInf,  "Inf", "$PInf value stringifies as Inf");
  is($NInf, "-Inf", "$PInf value stringifies as -Inf");

  is(sprintf("%g", $PInf), "Inf", "$PInf sprintf %g is Inf");
  is(sprintf("%a", $PInf), "Inf", "$PInf sprintf %a is Inf");

  for my $i (@PInf) {
    is($i + 0, $PInf, "$i is +Inf");
    ok($i > 0, "$i is positive");
    is("@{[$i+0]}", "Inf", "$i value stringifies as Inf");
  }

  for my $i (@NInf) {
    is($i + 0, $NInf, "$i is -Inf");
    ok($i < 0, "$i is negative");
    is("@{[$i+0]}", "-Inf", "$i value stringifies as -Inf");
  }

  is($PInf + $PInf, $PInf, "+inf plus +inf is +inf");
  is($NInf + $NInf, $NInf, "-inf plus -inf is -inf");

  is(1/$PInf, 0, "one per +Inf is zero");
  is(1/$NInf, 0, "one per -Inf is zero");

  is(9**9**9, $Inf, "9**9**9 is Inf");
}

SKIP: {
  if ($NaN == 1) {
    skip $nan_tests, "no nan found";
  }

  $has_nan = 1;

  ok($NaN != $NaN, "nan is not nan numerically");
  ok($NaN eq $NaN, "nan is nan stringifically");

  is("$NaN", "NaN", "$NaN value stringies as NaN");

  is(sprintf("%g", $NaN), "NaN", "$NaN sprintf %g is NaN");
  is(sprintf("%a", $NaN), "NaN", "$NaN sprintf %a is Inf");

  for my $i (@NaN) {
    cmp_ok($i + 0, '!=', $i + 0, "$i is nan");
    is("@{[$i+0]}", "NaN", "$i value stringifies as NaN");
  }

  # is() okay with $NaN because eq is used.
  is($NaN * 0, $NaN, "NaN times zero is NaN");
  is($NaN * 2, $NaN, "NaN times two is NaN");

  is(sin(9**9**9), $NaN, "sin(9**9**9) is NaN");
}

SKIP: {
  unless ($has_inf && $has_nan) {
    skip $infnan_tests, "no both inf and nan";
  }

  # is() okay with $NaN because eq is used.
  is($PInf * 0,     $NaN, "inf times zero is nan");
  is($PInf * $NaN,  $NaN, "inf times nan is nan");
  is($PInf + $NaN,  $NaN, "inf plus nan is nan");
  is($PInf - $PInf, $NaN, "inf minus inf is nan");
}

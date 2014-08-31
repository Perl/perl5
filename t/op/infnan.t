#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;

my $PInf = "Inf"  + 0;
my $NInf = "-Inf" + 0;
my $NaN  = "NaN"  + 0;

my @PInf = ("Inf", "inf", "INF", "+Inf",
            "Infinity", "INFINITE",
            "1.#INF", "1#INF");
my @NInf = map { "-$_" } grep { ! /^\+/ } @PInf;

my @NaN = ("NAN", "nan", "qnan", "SNAN", "NanQ", "NANS",
           "1.#QNAN", "+1#SNAN", "-1.#NAN", "1#IND",
           "NaN123", "NAN(123)", "nan%",
           "nanonano"); # RIP, Robin Williams.

my @num_fmt = qw(e f g a d u o b x p);

my $inf_tests = 13 + @num_fmt + 8 + 3 * @PInf + 3 * @NInf + 5 + 3;
my $nan_tests =  8 + @num_fmt + 4 + 2 * @NaN + 3;

my $infnan_tests = 4;

plan tests => $inf_tests + $nan_tests + $infnan_tests;

my $has_inf;
my $has_nan;

SKIP: {
  if ($PInf == 1 && $NInf == 1) {
    skip $inf_tests, "no infinity found";
  }

  $has_inf = 1;

  cmp_ok($PInf, '>', 0, "positive infinity");
  cmp_ok($NInf, '<', 0, "negative infinity");

  cmp_ok($PInf, '>', $NInf, "positive > negative");
  cmp_ok($NInf, '==', -$PInf, "negative == -positive");
  cmp_ok(-$NInf, '==', $PInf, "--negative == positive");

  is($PInf,  "Inf", "$PInf value stringifies as Inf");
  is($NInf, "-Inf", "$NInf value stringifies as -Inf");

  cmp_ok($PInf * 2, '==', $PInf, "twice Inf is Inf");
  cmp_ok($PInf / 2, '==', $PInf, "half of Inf is Inf");

  cmp_ok($PInf + 1, '==', $PInf, "Inf + one is Inf");
  cmp_ok($NInf + 1, '==', $NInf, "-Inf + one is -Inf");

  is(sprintf("%g", $PInf), "Inf", "$PInf sprintf %g is Inf");
  is(sprintf("%a", $PInf), "Inf", "$PInf sprintf %a is Inf");

  for my $f (@num_fmt) {
      is(sprintf("%$f", $PInf), "Inf", "$PInf sprintf %$f is Inf");
  }

  {
      local $^W = 0;

      is(sprintf("%c", $PInf), chr(0xFFFD), "$PInf sprintf %c is Inf");
      is(chr($PInf), chr(0xFFFD), "$PInf chr() is U+FFFD");

      is(sprintf("%c", $NInf), chr(0xFFFD), "$NInf sprintf %c is Inf");
      is(chr($NInf), chr(0xFFFD), "$NInf chr() is U+FFFD");

      is(pack('C', $PInf), chr(0xFF), "$PInf pack C is 0xFF byte");
      is(pack('c', $PInf), chr(0xFF), "$PInf pack c is 0xFF byte");

      is(pack('C', $NInf), chr(0xFF), "$NInf pack C is 0xFF byte");
      is(pack('c', $NInf), chr(0xFF), "$NInf pack c is 0xFF byte");
  }

  for my $i (@PInf) {
    cmp_ok($i + 0 , '==', $PInf, "$i is +Inf");
    cmp_ok($i, '>', 0, "$i is positive");
    is("@{[$i+0]}", "Inf", "$i value stringifies as Inf");
  }

  for my $i (@NInf) {
    cmp_ok($i + 0, '==', $NInf, "$i is -Inf");
    cmp_ok($i, '<', 0, "$i is negative");
    is("@{[$i+0]}", "-Inf", "$i value stringifies as -Inf");
  }

  is($PInf + $PInf, $PInf, "+inf plus +inf is +inf");
  is($NInf + $NInf, $NInf, "-inf plus -inf is -inf");

  is(1/$PInf, 0, "one per +Inf is zero");
  is(1/$NInf, 0, "one per -Inf is zero");

  is(9**9**9, $PInf, "9**9**9 is Inf");
}

{
    # Silence "isn't numeric in addition", that's kind of the point.
    local $^W = 0;
    for my $i (qw(Info Infiniti Infinityz)) {
        cmp_ok("$i" + 0, '==', 0, "false infinity $i");
    }
}

SKIP: {
  if ($NaN == 1) {
    skip $nan_tests, "no nan found";
  }

  $has_nan = 1;

  cmp_ok($NaN, '!=', $NaN, "NaN is NaN numerically (by not being NaN)");
  ok($NaN eq $NaN, "NaN is NaN stringifically");

  is("$NaN", "NaN", "$NaN value stringifies as NaN");

  is("+NaN" + 0, "NaN", "+NaN is NaN");
  is("-NaN" + 0, "NaN", "-NaN is NaN");

  is($NaN * 2, $NaN, "twice NaN is NaN");
  is($NaN / 2, $NaN, "half of NaN is NaN");

  is($NaN + 1, $NaN, "NaN + one is NaN");

  for my $f (@num_fmt) {
      is(sprintf("%$f", $NaN), "NaN", "$NaN sprintf %$f is NaN");
  }

  {
      local $^W = 0;

      is(sprintf("%c", $NaN), chr(0xFFFD), "$NaN sprintf %c is Inf");
      is(chr($NaN), chr(0xFFFD), "$NaN chr() is U+FFFD");

      is(pack('C', $NaN), chr(0xFF), "$NaN pack C is 0xFF byte");
      is(pack('c', $NaN), chr(0xFF), "$NaN pack c is 0xFF");
  }

  for my $i (@NaN) {
    cmp_ok($i + 0, '!=', $i + 0, "$i is NaN numerically (by not being NaN)");
    is("@{[$i+0]}", "NaN", "$i value stringifies as NaN");
  }

  # is() okay with $NaN because it uses eq.
  is($NaN * 0, $NaN, "NaN times zero is NaN");
  is($NaN * 2, $NaN, "NaN times two is NaN");

  is(sin(9**9**9), $NaN, "sin(9**9**9) is NaN");
}

SKIP: {
  unless ($has_inf && $has_nan) {
    skip $infnan_tests, "no both Inf and Nan";
  }

  # is() okay with $NaN because it uses eq.
  is($PInf * 0,     $NaN, "Inf times zero is NaN");
  is($PInf * $NaN,  $NaN, "Inf times NaN is NaN");
  is($PInf + $NaN,  $NaN, "Inf plus NaN is NaN");
  is($PInf - $PInf, $NaN, "Inf minus inf is NaN");
}

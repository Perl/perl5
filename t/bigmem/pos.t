#!perl
BEGIN {
    chdir 't';
    unshift @INC, "../lib";
    require './test.pl';
}

use Config qw(%Config);

$ENV{PERL_TEST_MEMORY} >= 2
    or skip_all("Need ~2Gb for this test");
$Config{ptrsize} >= 8
    or skip_all("Need 64-bit pointers for this test");

plan(2);

# [perl #116907]
my $x=" "x(2**31+20);
pos $x = 2**31-5;
is pos $x, 2147483643, 'setting pos on large string';
pos $x += 10;
is pos $x, 2147483653, 'setting pos > 2**31 on large string';

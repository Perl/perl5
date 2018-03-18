use strict;

use Test::More tests => 13;

BEGIN { require_ok "Time::HiRes"; }

my $d0 = Time::HiRes::tv_interval [5, 100_000], [10, 500_000];
ok(abs($d0 - 5.4) < 0.001, "10.5 - 5.1 = $d0");

my $d1 = Time::HiRes::tv_interval([], []);
is($d1, 0, "[] - [] = $d1");

my $t0 = [Time::HiRes::gettimeofday()];
Time::HiRes::sleep 0.1;
my $t1 = [Time::HiRes::gettimeofday()];
my $d2 = Time::HiRes::tv_interval($t1); # NOTE: only one arg. 

# This test will fail if between the $t1 and $d2 the time goes backwards:
# this will happen if the clock is adjusted for example by NTP.
ok($d2 >= 0, "now - [@$t0] = $d2 >= 0");

my $d3 = Time::HiRes::tv_interval($t0, $t0);
is($d3, 0, "[@$t0] - [@$t0] = $d3");

my $d4 = Time::HiRes::tv_interval($t0, $t1);

# Compute in Perl what tv_interval() used to do pre-1.9754. 
# This test will fail if too much wallclock time passes between
# the $t0 and $t1: this can happen in a heavily loaded system.
my $d5 = ($t1->[0] - $t0->[0]) + ($t1->[1] - $t0->[1]) / 1e6;
if ($d4 > 0) {
  my $rd4d5 = $d5 / $d4;
  ok(abs($rd4d5 - 1) < 0.001, "[@$t1] - [@$t0] = $d4 ($d5, $rd4d5)");
} else {
  is($d4, $d5, "$d4 == $d5");
}

# Then test errorneous inputs.

eval 'Time::HiRes::tv_interval()';
like($@, qr/Not enough arguments/, "at least one arg");

eval 'Time::HiRes::tv_interval(1)';
like($@, qr/1st argument should be an array reference/, "1st arg aref");

eval 'Time::HiRes::tv_interval(undef)';
like($@, qr/1st argument should be an array reference/, "1st arg aref");

eval 'Time::HiRes::tv_interval({})';
like($@, qr/1st argument should be an array reference/, "1st arg aref");

eval 'Time::HiRes::tv_interval([], 1)';
like($@, qr/2nd argument should be an array reference/, "2nd arg aref");

eval 'Time::HiRes::tv_interval([], {})';
like($@, qr/2nd argument should be an array reference/, "2nd arg aref");

# Would be tempting but would probably break some code.
# eval 'Time::HiRes::tv_interval([], [], [])';
# like($@, qr/expects two arguments/, "two args");

my $t2 = [Time::HiRes::gettimeofday];
Time::HiRes::sleep 0.1;
my $d6 = Time::HiRes::tv_interval($t2);
# This test originally for long double builds,
# has considerable flakness potential:
# (1) if the sleep takes exactly one second (or two, ...)
# (2) if the floating point operations in tv_interval()
#     come up with a floating point result that does not
#     format as a nicely "terminating" decimal number
like($d6, qr/\.\d{1,6}$/, "no extra decimals");

1;

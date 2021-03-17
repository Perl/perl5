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

sub try ($$$) {
   print +($_[1] ? "ok" : "not ok") . " $_[0] - $_[2]\n";
}

my $T = 1;
print "1..9\n";

my $vms_no_ieee;
if ($^O eq 'VMS') {
  $vms_no_ieee = 1 unless defined($Config{useieee});
}

if ($^O eq 'vos') {
  print "not ok ", $T++, " # TODO VOS raises SIGFPE instead of producing infinity.\n";
}
elsif ($vms_no_ieee || !$Config{d_double_has_inf}) {
 print "ok ", $T++, " # SKIP -- the IEEE infinity model is unavailable in this configuration.\n"
}
elsif ($^O eq 'ultrix') {
  print "not ok ", $T++, " # TODO Ultrix enters deep nirvana instead of producing infinity.\n";
}
else {
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
  while (--$n)
  {
    $v *= 2;
  }
  print "ok ", $T++, " - infinity\n";
}


# [perl #120426]
# small numbers shouldn't round to zero if they have extra floating digits

unless ($Config{d_double_style_ieee}) {
for (1..8) { print "ok ", $T++, " # SKIP -- not IEEE\n" }
} else {
try $T++,  0.153e-305 != 0.0,              '0.153e-305';
try $T++,  0.1530e-305 != 0.0,             '0.1530e-305';
try $T++,  0.15300e-305 != 0.0,            '0.15300e-305';
try $T++,  0.153000e-305 != 0.0,           '0.153000e-305';
try $T++,  0.1530000e-305 != 0.0,          '0.1530000e-305';
try $T++,  0.1530001e-305 != 0.0,          '0.1530001e-305';
try $T++,  1.17549435100e-38 != 0.0,       'min single';
# For flush-to-zero systems this may flush-to-zero, see PERL_SYS_FPU_INIT
try $T++,  2.2250738585072014e-308 != 0.0, 'min double';
}

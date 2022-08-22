#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require "./test.pl";
    require Config;
    $Config::Config{d_pseudofork}
        or skip_all("no pseudo-fork");
    eval 'use Errno';
    die $@ if $@ and !is_miniperl();
}

# [perl #77672] backticks capture text printed to stdout when working
# with multiple threads on windows
# As documented in https://github.com/Perl/perl5/issues/20081 (but as
# what seems to a problem not related to that issue per se) it appears
# that the use of the watchdog actually introduces a problem by itself
# when building on Win11. Running the test without a watchdogs succeeds.
# As the real cause is as yet unclear, for anyone experiencing the problem,
# the watchdog can be set to a longer time by setting PERL_TEST_TIME_OUT_FACTOR
my $time_out_factor = $ENV{PERL_TEST_TIME_OUT_FACTOR} || 1;
$time_out_factor = 1 if $time_out_factor < 1;
watchdog(20 * $time_out_factor); # before the fix this would often lock up

fresh_perl_like(<<'PERL', qr/\A[z\n]+\z/, {}, "popen and threads");
if (!defined fork) { die "can't fork" }
for(1..100) {
  print "zzzzzzzzzzzzz\n";
  my $r=`perl -v`;
  print $r if($r=~/zzzzzzzzzzzzz/);
}
PERL

done_testing();

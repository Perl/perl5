# cond_wait and cond_timedwait extended tests
# adapted from cond.t

use warnings;

BEGIN {
    chdir 't' if -d 't';
    push @INC ,'../lib';
    require Config; import Config;
    unless ($Config{'useithreads'}) {
        print "1..0 # Skip: no threads\n";
        exit 0;
    }
}
$|++;
print "1..90\n";
use strict;

use threads;
use threads::shared;
use ExtUtils::testlib;

my $Base = 0;

sub ok {
    my ($offset, $bool, $text) = @_;
    my $not = '';
    $not = "not " unless $bool;
    print "${not}ok " . ($Base + $offset) . " - $text\n";
}

# - TEST basics

ok(1, defined &cond_wait, "cond_wait() present");
ok(2, (prototype(\&cond_wait) eq '\[$@%];\[$@%]'),
    q|cond_wait() prototype '\[$@%];\[$@%]'|);
ok(3, defined &cond_timedwait, "cond_timedwait() present");
ok(4, (prototype(\&cond_timedwait) eq '\[$@%]$;\[$@%]'),
    q|cond_timedwait() prototype '\[$@%]$;\[$@%]'|);

$Base += 4;

my @wait_how = (
   "simple",  # cond var == lock var; implicit lock; e.g.: cond_wait($c)
   "repeat",  # cond var == lock var; explicit lock; e.g.: cond_wait($c, $c)
   "twain"    # cond var != lock var; explicit lock; e.g.: cond_wait($c, $l)
);

SYNC_SHARED: {
  my $test : shared;  # simple|repeat|twain
  my $cond : shared;
  my $lock : shared;

  ok(1, 1, "Shared synchronization tests preparation");
  $Base += 1;

  sub signaller {
    ok(2,1,"$test: child before lock");
    $test =~ /twain/ ? lock($lock) : lock($cond);
    ok(3,1,"$test: child obtained lock");
    if ($test =~ 'twain') {
      no warnings 'threads';   # lock var != cond var, so disable warnings
      cond_signal($cond);
    } else {
      cond_signal($cond);
    }
    ok(4,1,"$test: child signalled condition");
  }

  # - TEST cond_wait
  foreach (@wait_how) {
    $test = "cond_wait [$_]";
    threads->create(\&cw)->join;
    $Base += 5;
  }

  sub cw {
    ## which lock to obtain in this scope?
    $test =~ /twain/ ? lock($lock) : lock($cond);
    ok(1,1, "$test: obtained initial lock");

    my $thr = threads->create(\&signaller);
    for ($test) {
      cond_wait($cond), last        if    /simple/;
      cond_wait($cond, $cond), last if    /repeat/;
      cond_wait($cond, $lock), last if    /twain/;
      die "$test: unknown test\n"; 
    }
    $thr->join;
    ok(5,1, "$test: condition obtained");
  }

  # - TEST cond_timedwait success

  foreach (@wait_how) {
    $test = "cond_timedwait [$_]";
    threads->create(\&ctw, 5)->join;
    $Base += 5;
  }

  sub ctw($) {
    my $to = shift;

    ## which lock to obtain in this scope?
    $test =~ /twain/ ? lock($lock) : lock($cond);
    ok(1,1, "$test: obtained initial lock");

    my $thr = threads->create(\&signaller);
    ### N.B.: RACE!  If $timeout is very soon and/or we are unlucky, we
    ###       might timeout on the cond_timedwait before the signaller
    ###       thread even attempts lock()ing.
    ###       Upshot:  $thr->join() never completes, because signaller is
    ###       stuck attempting to lock the mutex we regained after waiting.
    my $ok = 0;
    for ($test) {
      $ok=cond_timedwait($cond, time() + $to), last        if    /simple/;
      $ok=cond_timedwait($cond, time() + $to, $cond), last if    /repeat/;
      $ok=cond_timedwait($cond, time() + $to, $lock), last if    /twain/;
      die "$test: unknown test\n"; 
    }
    print "# back from cond_timedwait; join()ing\n";
    $thr->join;
    ok(5,$ok, "$test: condition obtained");
  }

  # - TEST cond_timedwait timeout

  foreach (@wait_how) {
    $test = "cond_timedwait pause, timeout [$_]";
    threads->create(\&ctw_fail, 3)->join;
    $Base += 2;
  }

  foreach (@wait_how) {
    $test = "cond_timedwait instant timeout [$_]";
    threads->create(\&ctw_fail, -60)->join;
    $Base += 2;
  }

  # cond_timedwait timeout (relative timeout)
  sub ctw_fail {
    my $to = shift;

    $test =~ /twain/ ? lock($lock) : lock($cond);
    ok(1,1, "$test: obtained initial lock");
    my $ok;
    for ($test) {
      $ok=cond_timedwait($cond, time() + $to), last        if    /simple/;
      $ok=cond_timedwait($cond, time() + $to, $cond), last if    /repeat/;
      $ok=cond_timedwait($cond, time() + $to, $lock), last if    /twain/;
      die "$test: unknown test\n"; 
    }
    ok(2,!defined($ok), "$test: timeout");
  }

} # -- SYNCH_SHARED block


# same as above, but with references to lock and cond vars

SYNCH_REFS: {
  my $test : shared;  # simple|repeat|twain
  
  my $true_cond; share($true_cond);
  my $true_lock; share($true_lock);

  my $cond = \$true_cond;
  my $lock = \$true_lock;

  ok(1, 1, "Synchronization reference tests preparation");
  $Base += 1;

  sub signaller2 {
    ok(2,1,"$test: child before lock");
    $test =~ /twain/ ? lock($lock) : lock($cond);
    ok(3,1,"$test: child obtained lock");
    if ($test =~ 'twain') {
      no warnings 'threads';   # lock var != cond var, so disable warnings
      cond_signal($cond);
    } else {
      cond_signal($cond);
    }
    ok(4,1,"$test: child signalled condition");
  }

  # - TEST cond_wait
  foreach (@wait_how) {
    $test = "cond_wait [$_]";
    threads->create(\&cw2)->join;
    $Base += 5;
  }

  sub cw2 {
    ## which lock to obtain in this scope?
    $test =~ /twain/ ? lock($lock) : lock($cond);
    ok(1,1, "$test: obtained initial lock");

    my $thr = threads->create(\&signaller2);
    for ($test) {
      cond_wait($cond), last        if    /simple/;
      cond_wait($cond, $cond), last if    /repeat/;
      cond_wait($cond, $lock), last if    /twain/;
      die "$test: unknown test\n"; 
    }
    $thr->join;
    ok(5,1, "$test: condition obtained");
  }

  # - TEST cond_timedwait success

  foreach (@wait_how) {
    $test = "cond_timedwait [$_]";
    threads->create(\&ctw2, 5)->join;
    $Base += 5;
  }

  sub ctw2($) {
    my $to = shift;

    ## which lock to obtain in this scope?
    $test =~ /twain/ ? lock($lock) : lock($cond);
    ok(1,1, "$test: obtained initial lock");

    my $thr = threads->create(\&signaller2);
    ###  N.B.:  RACE!  as above, with ctw()
    my $ok = 0;
    for ($test) {
      $ok=cond_timedwait($cond, time() + $to), last        if    /simple/;
      $ok=cond_timedwait($cond, time() + $to, $cond), last if    /repeat/;
      $ok=cond_timedwait($cond, time() + $to, $lock), last if    /twain/;
      die "$test: unknown test\n"; 
    }
    $thr->join;
    ok(5,$ok, "$test: condition obtained");
  }

  # - TEST cond_timedwait timeout

  foreach (@wait_how) {
    $test = "cond_timedwait pause, timeout [$_]";
    threads->create(\&ctw_fail2, 3)->join;
    $Base += 2;
  }

  foreach (@wait_how) {
    $test = "cond_timedwait instant timeout [$_]";
    threads->create(\&ctw_fail2, -60)->join;
    $Base += 2;
  }

  sub ctw_fail2 {
    my $to = shift;

    $test =~ /twain/ ? lock($lock) : lock($cond);
    ok(1,1, "$test: obtained initial lock");
    my $ok;
    for ($test) {
      $ok=cond_timedwait($cond, time() + $to), last        if    /simple/;
      $ok=cond_timedwait($cond, time() + $to, $cond), last if    /repeat/;
      $ok=cond_timedwait($cond, time() + $to, $lock), last if    /twain/;
      die "$test: unknown test\n"; 
    }
    ok(2,!$ok, "$test: timeout");
  }

} # -- SYNCH_REFS block


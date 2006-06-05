use strict;
use warnings;

BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        unshift @INC, '../lib';
    }
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

use ExtUtils::testlib;

use threads;

BEGIN {
    eval {
        require threads::shared;
        import threads::shared;
    };
    if ($@ || ! $threads::shared::threads_shared) {
        print("1..0 # Skip: threads::shared not available\n");
        exit(0);
    }

    if (($] < 5.008002) && ($threads::shared::VERSION < 0.92)) {
        print("1..0 # Skip: Needs threads::shared 0.92 or later\n");
        exit(0);
    }

    $| = 1;
    print("1..74\n");   ### Number of tests that will be run ###
};

my $TEST = 1;
share($TEST);

ok(1, 'Loaded');

sub ok {
    my ($ok, $name) = @_;

    lock($TEST);
    my $id = $TEST++;

    # You have to do it this way or VMS will get confused.
    if ($ok) {
        print("ok $id - $name\n");
    } else {
        print("not ok $id - $name\n");
        printf("# Failed test at line %d\n", (caller)[2]);
    }

    return ($ok);
}


### Start of Testing ###

# Tests freeing the Perl interperter for each thread
# See http://www.nntp.perl.org/group/perl.perl5.porters/110772 for details

my $COUNT;
share($COUNT);
my %READY;
share(%READY);

# Init a thread
sub th_start {
    my $tid = threads->tid();
    ok($tid, "Thread $tid started");

    # Create next thread
    if ($tid < 17) {
        my $next = 'th' . ($tid+1);
        my $th = threads->create($next);
    } else {
        # Last thread signals first
        th_signal(1);
    }
    th_wait();
}

# Thread terminating
sub th_done {
    my $tid = threads->tid();

    lock($COUNT);
    $COUNT++;
    cond_signal($COUNT);

    ok($tid, "Thread $tid done");
}

# Wait until signalled by another thread
sub th_wait
{
    my $tid = threads->tid();

    lock(%READY);
    while (! exists($READY{$tid})) {
        cond_wait(%READY);
    }
    my $other = delete($READY{$tid});
    ok($tid, "Thread $tid received signal from $other");
}

# Signal another thread to go
sub th_signal
{
    my $other = shift;
    my $tid = threads->tid();

    ok($tid, "Thread $tid signalling $other");

    lock(%READY);
    $READY{$other} = $tid;
    cond_broadcast(%READY);
}

#####

sub th1 {
    th_start();

    threads->detach();

    th_signal(2);
    th_signal(6);
    th_signal(10);
    th_signal(14);

    th_done();
}

sub th2 {
    th_start();
    threads->detach();
    th_signal(4);
    th_done();
}

sub th6 {
    th_start();
    threads->detach();
    th_signal(8);
    th_done();
}

sub th10 {
    th_start();
    threads->detach();
    th_signal(12);
    th_done();
}

sub th14 {
    th_start();
    threads->detach();
    th_signal(16);
    th_done();
}

sub th4 {
    th_start();
    threads->detach();
    th_signal(3);
    th_done();
}

sub th8 {
    th_start();
    threads->detach();
    th_signal(7);
    th_done();
}

sub th12 {
    th_start();
    threads->detach();
    th_signal(13);
    th_done();
}

sub th16 {
    th_start();
    threads->detach();
    th_signal(17);
    th_done();
}

sub th3 {
    my $other = 5;

    th_start();
    threads->detach();
    th_signal($other);
    threads->yield();
    sleep(1);
    my $ret = threads->object($other)->join();
    ok($ret == $other, "Thread $other returned $ret");
    th_done();
}

sub th5 {
    th_start();
    th_done();
    return (threads->tid());
}


sub th7 {
    my $other = 9;

    th_start();
    threads->detach();
    th_signal($other);
    my $ret = threads->object($other)->join();
    ok($ret == $other, "Thread $other returned $ret");
    th_done();
}

sub th9 {
    th_start();
    threads->yield();
    sleep(1);
    th_done();
    return (threads->tid());
}


sub th13 {
    my $other = 11;

    th_start();
    threads->detach();
    th_signal($other);
    threads->yield();
    sleep(1);
    my $ret = threads->object($other)->join();
    ok($ret == $other, "Thread $other returned $ret");
    th_done();
}

sub th11 {
    th_start();
    th_done();
    return (threads->tid());
}


sub th17 {
    my $other = 15;

    th_start();
    threads->detach();
    th_signal($other);
    my $ret = threads->object($other)->join();
    ok($ret == $other, "Thread $other returned $ret");
    th_done();
}

sub th15 {
    th_start();
    threads->yield();
    sleep(1);
    th_done();
    return (threads->tid());
}






TEST_STARTS_HERE:
{
    $COUNT = 0;
    threads->create('th1');
    {
        lock($COUNT);
        while ($COUNT < 17) {
            cond_wait($COUNT);
        }
    }
    threads->yield();
    sleep(1);
}
ok($COUNT == 17, "Done - $COUNT threads");

# EOF

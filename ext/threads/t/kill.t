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
use threads::shared;

{
    package Thread::Semaphore;
    use threads::shared;

    sub new {
        my $class = shift;
        my $val : shared = @_ ? shift : 1;
        bless \$val, $class;
    }

    sub down {
        my $s = shift;
        lock($$s);
        my $inc = @_ ? shift : 1;
        cond_wait $$s until $$s >= $inc;
        $$s -= $inc;
    }

    sub up {
        my $s = shift;
        lock($$s);
        my $inc = @_ ? shift : 1;
        ($$s += $inc) > 0 and cond_broadcast $$s;
    }
}

BEGIN {
    $| = 1;
    print("1..18\n");   ### Number of tests that will be run ###
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

### Thread cancel ###

# Set up to capture warning when thread terminates
my @errs :shared;
$SIG{__WARN__} = sub { push(@errs, @_); };


sub thr_func {
    # Thread 'cancellation' signal handler
    $SIG{'KILL'} = sub {
        ok(1, 'Thread received signal');
        die("Thread killed\n");
    };

    # Thread sleeps until signalled
    ok(1, 'Thread sleeping');
    {
	local $SIG{'INT'} = sub {};
	sleep(5);
    }
    # Should not go past here
    ok(0, 'Thread terminated normally');
    return ('ERROR');
}


# Create thread
my $thr = threads->create('thr_func');
ok($thr && $thr->tid() == 1, 'Created thread');
threads->yield();
sleep(1);

# Signal thread
ok($thr->kill('KILL'), 'Signalled thread');
threads->yield();

# Interrupt thread's sleep call
{
    # We can't be sure whether the signal itself will get delivered to this
    # thread or the sleeping thread
    local $SIG{'INT'} = sub {};
    ok(kill('INT', $$) || $^O eq 'MSWin32', q/Interrupt thread's sleep call/);
}

# Cleanup
my $rc = $thr->join();
ok(! $rc, 'No thread return value');

# Check for thread termination message
ok(@errs && $errs[0] =~ /Thread killed/, 'Thread termination warning');


### Thread suspend/resume ###

sub thr_func2
{
    my $sema = shift;
    ok($sema, 'Thread received semaphore');

    # Set up the signal handler for suspension/resumption
    $SIG{'STOP'} = sub {
        ok(1, 'Thread suspending');
        $sema->down();
        ok(1, 'Thread resuming');
        $sema->up();
    };

    # Set up the signal handler for graceful termination
    my $term = 0;
    $SIG{'TERM'} = sub {
        ok(1, 'Thread caught termination signal');
        $term = 1;
    };

    # Do work until signalled to terminate
    while (! $term) {
        sleep(1);
    }

    ok(1, 'Thread done');
    return ('OKAY');
}


# Create a semaphore for use in suspending the thread
my $sema = Thread::Semaphore->new();
ok($sema, 'Semaphore created');

# Create a thread and send it the semaphore
$thr = threads->create('thr_func2', $sema);
ok($thr && $thr->tid() == 2, 'Created thread');
threads->yield();
sleep(1);

# Suspend the thread
$sema->down();
ok($thr->kill('STOP'), 'Suspended thread');

threads->yield();
sleep(1);

# Allow the thread to continue
$sema->up();

threads->yield();
sleep(1);

# Terminate the thread
ok($thr->kill('TERM'), 'Signalled thread to terminate');

$rc = $thr->join();
ok($rc eq 'OKAY', 'Thread return value');

# EOF

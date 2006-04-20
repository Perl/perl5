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

sub ok {
    my ($id, $ok, $name) = @_;

    # You have to do it this way or VMS will get confused.
    if ($ok) {
        print("ok $id - $name\n");
    } else {
        print("not ok $id - $name\n");
        printf("# Failed test at line %d\n", (caller)[2]);
    }

    return ($ok);
}

BEGIN {
    $| = 1;
    print("1..29\n");   ### Number of tests that will be run ###
};

use threads;
use threads::shared;
ok(1, 1, 'Loaded');

### Start of Testing ###

# Tests freeing the Perl interperter for each thread
# See http://www.nntp.perl.org/group/perl.perl5.porters/110772 for details

my $COUNT;
share($COUNT);
my $TEST = 2;
share($TEST);

sub threading_1 {
    my $tid = threads->tid();
    ok($TEST++, $tid, "Thread $tid started");

    if ($tid < 5) {
        sleep(1);
        threads->create('threading_1')->detach();
    }

    threads->yield();

    if ($tid == 1) {
        sleep(2);
    } elsif ($tid == 2) {
        sleep(6);
    } elsif ($tid == 3) {
        sleep(3);
    } elsif ($tid == 4) {
        sleep(1);
    } else {
        sleep(2);
    }

    lock($COUNT);
    $COUNT++;
    cond_signal($COUNT);
    ok($TEST++, $tid, "Thread $tid done");
}

{
    $COUNT = 0;
    threads->create('threading_1')->detach();
    {
        lock($COUNT);
        while ($COUNT < 3) {
            cond_wait($COUNT);
        }
    }
}
{
    {
        lock($COUNT);
        while ($COUNT < 5) {
            cond_wait($COUNT);
        }
    }
    threads->yield();
    sleep(1);
}
ok($TEST++, $COUNT == 5, "Done - $COUNT threads");


sub threading_2 {
    my $tid = threads->tid();
    ok($TEST++, $tid, "Thread $tid started");

    if ($tid < 10) {
        threads->create('threading_2')->detach();
    }

    threads->yield();

    lock($COUNT);
    $COUNT++;
    cond_signal($COUNT);

    ok($TEST++, $tid, "Thread $tid done");
}

{
    $COUNT = 0;
    threads->create('threading_2')->detach();
    {
        lock($COUNT);
        while ($COUNT < 3) {
            cond_wait($COUNT);
        }
    }
    threads->yield();
    sleep(1);
}
ok($TEST++, $COUNT == 5, "Done - $COUNT threads");


{
    threads->create(sub { })->join();
}
ok($TEST++, 1, 'Join');


sub threading_3 {
    my $tid = threads->tid();
    ok($TEST++, $tid, "Thread $tid started");

    {
        threads->create(sub {
            my $tid = threads->tid();
            ok($TEST++, $tid, "Thread $tid started");

            threads->yield();
            sleep(1);

            lock($COUNT);
            $COUNT++;
            cond_signal($COUNT);

            ok($TEST++, $tid, "Thread $tid done");
        })->join();
    }

    lock($COUNT);
    $COUNT++;
    cond_signal($COUNT);

    ok($TEST++, $tid, "Thread $tid done");
}

{
    $COUNT = 0;
    threads->create(sub {
        threads->create('threading_3')->detach();
        {
            lock($COUNT);
            while ($COUNT < 2) {
                cond_wait($COUNT);
            }
        }
    })->join();
    threads->yield();
    sleep(1);
}
ok($TEST++, $COUNT == 2, "Done - $COUNT threads");

# EOF

#!perl
#
# Test for expected error and warning messages
#
# Fairly comprehensive, but doesn't check panics and portability
# issues, which are hard/impossible to portably test for.

use strict;
use warnings;

use ExtUtils::testlib;
use Test::More;

BEGIN {
    use Config;
    plan(skip_all => "Perl not compiled with 'useithreads'")
        unless $Config{'useithreads'};
}

use threads;
use threads::shared;

pass("loaded");

# Check warnings

{
    my $w;
    local $SIG{__WARN__} = sub { $w .= $_[0]; };

    my $lock :shared;

    # shared.xs warnings

    {
        undef $w;
        my $x :shared;
        &threads::shared::bless(\$x, '');
        like($w, qr/\QExplicit blessing to '' (assuming package main)/,
                    "warn bless main");
    }

    {
        my $s;
        undef $w;
        is threads::shared::_refcnt($s), undef,  "warn _refcnt undef retval";
        like($w, qr/SCALAR\(0x[0-9a-f]+\) is not shared/, "warn _refcnt");
    }

    undef $w;
    cond_signal($lock);
    like($w, qr/\Qcond_signal() called on unlocked variable/,
                                    "warn cond_signal not locked");

    undef $w;
    cond_broadcast($lock);
    like($w, qr/\Qcond_broadcast() called on unlocked variable/,
                                    "warn cond_broadcast not locked");

    {
        # Test whether using separate cond and lock vars triggers
        # an 'unlocked var' warning.
        my $cond :shared; # used for actual test
        my $sig  :shared; # used to sync threads ready for test
        undef $w;
        my $t = threads->new(
            sub {
                lock $lock;
                {
                    # tell parent we have $lock
                    lock $sig;
                    $sig = 1;
                    cond_signal($sig);
                }
                cond_wait($cond, $lock);
            }
        );

        # wait until child has $lock
        {
            lock $sig;
            while (!$sig) {
                cond_wait($sig);
            }
        }
        pass("\$lock acquired");

        {
            # the actual test
            lock $lock;
            cond_signal($cond);
        }
        is($w, undef, "no warn cond_signal not locked");
        $t->join;
    }

    # Test for the "cond_wait() called on multiple locks" warning.
    # To trigger this, we need to start two threads, which wait on the
    # same condition variable but using different locks.
    # We must make sure they aren't signalled (and thus run to
    # completion) until after *both* are in wait() with their lock
    # unlocked
    #
    # We skip this test if running under helgrind, because otherwise it
    # triggers these false positives:
    #     "cond is associated with a different mutex"
    #     "dubious: associated lock is not held by any thread"

    SKIP: {
        skip "running under helgrind", 2
            if (($ENV{LD_PRELOAD} || "") =~ /valgrind/);
        my $cond :shared = 0;

        my $t1 = threads->new(sub {
                    lock $cond;
                    $cond = 1;
                    undef $w;
                    cond_wait($cond);
                    return $w;
                }
             );

        # Pause until t1 is in wait and has unlocked
        SYNC1:
        while (1) {
            {
                lock $cond;
                last SYNC1 if $cond == 1;
            }
            note "sleeping for 1 second to acquire \$cond";
            sleep 1;
        }

        my $t2 = threads->new(sub {
                    lock $lock;
                    $lock = 2;
                    undef $w;
                    cond_wait($cond, $lock);
                    return $w;
                }
             );

        # Pause until t2 is in wait and has unlocked
        SYNC2:
        while (1) {
            {
                lock $lock;
                last SYNC2 if $lock == 2;
                last if $lock == 2;
            }
            note "sleeping for 1 second to acquire \$lock";
            sleep 1;
        }

        # wake up both threads

        cond_signal($cond);
        cond_signal($cond);

        my $w1 = $t1->join();
        my $w2 = $t2->join();

        is   $w1, undef,        "multiple locks: no warn on first";
        like $w2, qr/\Qcond_wait() called on multiple locks/,
                                "multiple locks: warn on second";
    }

}


# Check errors

{
    my $lock :shared;

    # shared.pm errors

    eval q{my @a :shared; splice(@a,1);};
    like($@, qr/Splice not implemented for shared arrays/, "err splice");

    eval q{shared_clone(1,2)};
    like($@, qr/\QUsage: shared_clone(REF)/, "err shared_clone usage");

    eval q{shared_clone(\*foo)};
    like($@, qr/Unsupported ref type: GLOB/, "err shared_clone ref GLOB");

    eval q{shared_clone(*foo)};
    like($@, qr/Unsupported scalar type: GLOB/, "err shared_clone scalar GLOB");

    # shared.xs errors

    eval q{&share(\*x99)};
    like($@, qr/Cannot share globs yet/, "err glob share");

    eval q{&share(sub {})};
    like($@, qr/Cannot share subs yet/, "err sub share");

    eval q{&threads::shared::_id(1)};
    like($@, qr/Argument to _id needs to be passed as ref/,
                "err _id not ref");

    eval q{&threads::shared::_refcnt(1)};
    like($@, qr/Argument to _refcnt needs to be passed as ref/,
                "err _refcnt not ref");

    eval q{&share(1)};
    like($@, qr/Argument to share needs to be passed as ref/,
                "err share not ref");

    eval q{my $x: shared; $x = sub{};};
    like($@, qr/Invalid value for shared scalar/, "err share invalid assign");

    eval q{my $x; lock($x);};
    like($@, qr/lock can only be used on shared values/, "err unshared lock");

    eval q{&threads::shared::bless($lock, []);};
    like($@, qr/Attempt to bless into a reference/, "err bless ref");


    eval q{&cond_wait(1);};
    like($@, qr/Argument to cond_wait needs to be passed as ref/,
                                    "err cond_wait ref");

    eval q{&cond_timedwait(1, 0.0);};
    like($@, qr/Argument to cond_timedwait needs to be passed as ref/,
                                    "err cond_timedwait ref");

    eval q{&cond_wait(\1);};
    like($@, qr/cond_wait can only be used on shared values/,
                                    "err cond_wait shared");

    eval q{&cond_timedwait(\1, 0.0);};
    like($@, qr/cond_timedwait can only be used on shared values/,
                                    "err cond_timedwait shared");

    eval q{&cond_wait(\$lock, 1);};
    like($@, qr/cond_wait lock needs to be passed as ref/,
                                    "err cond_wait lock ref");

    eval q{&cond_timedwait(\$lock, 0.0, 1);};
    like($@, qr/cond_timedwait lock needs to be passed as ref/,
                                    "err cond_timedwait lock ref");

    eval q{&cond_wait(\$lock, \1);};
    like($@, qr/cond_wait lock must be a shared value/,
                                    "err cond_wait lock shared");

    eval q{&cond_timedwait(\$lock, 0.0, \1);};
    like($@, qr/cond_timedwait lock must be a shared value/,
                                    "err cond_timedwait lock shared");

    eval q{&cond_wait(\$lock);};
    like($@, qr/You need a lock before you can cond_wait/,
                                    "err cond_wait not locked");

    eval q{&cond_timedwait(\$lock, 0.0);};
    like($@, qr/You need a lock before you can cond_timedwait/,
                                    "err cond_timedwait not locked");

    eval q{&cond_signal(1);};
    like($@, qr/Argument to cond_signal needs to be passed as ref/,
                                    "err cond_signal not ref");

    eval q{&cond_broadcast(1);};
    like($@, qr/Argument to cond_broadcast needs to be passed as ref/,
                                    "err cond_broadcast not ref");

    eval q{&cond_signal(\1);};
    like($@, qr/cond_signal can only be used on shared values/,
                                    "err cond_signal not shared");

    eval q{&cond_broadcast(\1);};
    like($@, qr/cond_broadcast can only be used on shared values/,
                                    "err cond_broadcast not shared");
}

done_testing;


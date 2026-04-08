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
    like($@, qr/Unsupported ref type: GLOB/, "err shared_clone ref type");

    # shared.xs errors

    eval q{&share(\*x99)};
    like($@, qr/Cannot share globs yet/, "err glob share");

    eval q{&share(sub {})};
    like($@, qr/Cannot share subs yet/, "err sub share");

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


#!perl -w

# We assume that TestInit has been used.

BEGIN {
      require './test.pl';
}

use strict;
use Config;

plan tests => 17;

watchdog(15);

$SIG{ALRM} = sub {
    die "Alarm!\n";
};

pass('before the first loop');

alarm 2;

eval {
    1 while 1;
};

is($@, "Alarm!\n", 'after the first loop');

pass('before the second loop');

alarm 2;

eval {
    while (1) {
    }
};

is($@, "Alarm!\n", 'after the second loop');

SKIP: {
    skip('We can\'t test blocking without sigprocmask', 11)
	if is_miniperl() || !$Config{d_sigprocmask};
    skip('This doesn\'t work on OpenBSD threaded builds RT#88814', 11)
        if $^O eq 'openbsd' && $Config{useithreads};

    require POSIX;
    my $new = POSIX::SigSet->new(&POSIX::SIGUSR1);
    POSIX::sigprocmask(&POSIX::SIG_BLOCK, $new);
    
    my $gotit = 0;
    $SIG{USR1} = sub { $gotit++ };
    kill SIGUSR1, $$;
    is $gotit, 0, 'Haven\'t received third signal yet';
    
    my $old = POSIX::SigSet->new();
    POSIX::sigsuspend($old);
    is $gotit, 1, 'Received third signal';
    
	{
		kill SIGUSR1, $$;
		local $SIG{USR1} = sub { die "FAIL\n" };
		POSIX::sigprocmask(&POSIX::SIG_BLOCK, undef, $old);
		ok $old->ismember(&POSIX::SIGUSR1), 'SIGUSR1 is blocked';
		eval { POSIX::sigsuspend(POSIX::SigSet->new) };
		is $@, "FAIL\n", 'Exception is thrown, so received fourth signal';
		POSIX::sigprocmask(&POSIX::SIG_BLOCK, undef, $old);
TODO:
	    {
		local $::TODO = "Needs investigation" if $^O eq 'VMS';
		ok $old->ismember(&POSIX::SIGUSR1), 'SIGUSR1 is still blocked';
	    }
	}

TODO:
    {
	local $::TODO = "Needs investigation" if $^O eq 'VMS';
	kill SIGUSR1, $$;
	is $gotit, 1, 'Haven\'t received fifth signal yet';
	POSIX::sigprocmask(&POSIX::SIG_UNBLOCK, $new, $old);
	ok $old->ismember(&POSIX::SIGUSR1), 'SIGUSR1 was still blocked';
    }
    is $gotit, 2, 'Received fifth signal';

    # test unsafe signal handlers in combination with exceptions
    my $action = POSIX::SigAction->new(sub { $gotit--, die }, POSIX::SigSet->new, 0);
    POSIX::sigaction(&POSIX::SIGALRM, $action);
    eval {
        alarm 1;
        my $set = POSIX::SigSet->new;
        POSIX::sigprocmask(&POSIX::SIG_BLOCK, undef, $set);
        is $set->ismember(&POSIX::SIGALRM), 0, "SIGALRM is not blocked on attempt $_";
        POSIX::sigsuspend($set);
    } for 1..2;
    is $gotit, 0, 'Received both signals';
}

SKIP: {
    skip("alarm cannot interrupt blocking system calls on $^O", 2)
	if ($^O eq 'MSWin32' || $^O eq 'VMS');
    # RT #88774
    # make sure the signal handler's called in an eval block *before*
    # the eval is popped

    $SIG{'ALRM'} = sub { die "HANDLER CALLED\n" };

    eval {
	alarm(2);
	select(undef,undef,undef,10);
    };
    alarm(0);
    is($@, "HANDLER CALLED\n", 'block eval');

    eval q{
	alarm(2);
	select(undef,undef,undef,10);
    };
    alarm(0);
    is($@, "HANDLER CALLED\n", 'string eval');
}

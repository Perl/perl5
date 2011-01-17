#!perl -w

# We assume that TestInit has been used.

BEGIN {
      require './test.pl';
}

use strict;
use Config;

plan tests => 9;

watchdog(10);

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
    skip('We can\'t test blocking without sigprocmask', 3) if $ENV{PERL_CORE_MINITEST} || !$Config{d_sigprocmask};

    require POSIX;
    my $new = POSIX::SigSet->new(&POSIX::SIGUSR1);
    POSIX::sigprocmask(&POSIX::SIG_BLOCK, $new);
    
    my $gotit = 0;
    $SIG{USR1} = sub { $gotit++ };
    kill SIGUSR1, $$;
    is $gotit, 0, 'Haven\'t third received signal yet';
    
    my $old = POSIX::SigSet->new();
    POSIX::sigsuspend($old);
    is $gotit, 1, 'Received third signal';
    
    kill SIGUSR1, $$;
    is $gotit, 1, 'Haven\'t fourth received signal yet';
    POSIX::sigprocmask(&POSIX::SIG_UNBLOCK, $new, $old);
    ok $old->ismember(&POSIX::SIGUSR1), 'SIGUSR1 was still blocked';
    is $gotit, 2, 'Received fourth signal';
}

use strict;
use warnings;

BEGIN {
    eval { require threads; };
}
use Test2::Tools::Tiny;
use Test2::Util qw/CAN_THREAD CAN_REALLY_FORK/;
use Test2::IPC;
use Test2::API qw/test2_ipc_set_timeout test2_ipc_get_timeout/;

is(test2_ipc_get_timeout(), 30, "got default timeout");
test2_ipc_set_timeout(10);
is(test2_ipc_get_timeout(), 10, "hanged the timeout");

if (CAN_REALLY_FORK) {
    note "Testing process waiting";
    my ($ppiper, $ppipew);
    pipe($ppiper, $ppipew) or die "Could not create pipe for fork";

    my $proc = fork();
    die "Could not fork!" unless defined $proc;

    unless ($proc) {
        local $SIG{ALRM} = sub { die "PROCESS TIMEOUT" };
        alarm 15;
        my $ignore = <$ppiper>;
        exit 0;
    }

    my $exit;
    my $warnings = warnings {
        $exit = Test2::API::Instance::_ipc_wait(1);
    };
    is($exit, 255, "Exited 255");
    like($warnings->[0], qr/Timeout waiting on child processes/, "Warned about timeout");
    print $ppipew "end\n";

    close($ppiper);
    close($ppipew);
}

if (CAN_THREAD) {
    note "Testing thread waiting";
    my ($tpiper, $tpipew);
    pipe($tpiper, $tpipew) or die "Could not create pipe for threads";

    my $thread = threads->create(
        sub {
            local $SIG{ALRM} = sub { die "THREAD TIMEOUT" };
            alarm 15;
            my $ignore = <$tpiper>;
        }
    );

    if ($thread->can('is_joinable')) {
        my $exit;
        my $warnings = warnings {
            $exit = Test2::API::Instance::_ipc_wait(1);
        };
        is($exit, 255, "Exited 255");
        like($warnings->[0], qr/Timeout waiting on child thread/, "Warned about timeout");
    }
    else {
        note "threads.pm is too old for a thread joining timeout :-(";
    }
    print $tpipew "end\n";

    close($tpiper);
    close($tpipew);
}

done_testing;

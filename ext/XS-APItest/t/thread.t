#!perl
use warnings;
use strict;
use Test2::IPC;
use Test2::V0;
use Config;

BEGIN {
    skip_all "Not pthreads or is win32"
      if !$Config{usethreads} || $^O eq "MSWin32";
}

use XS::APItest qw(thread_id_matches make_signal_thread join_signal_thread);

ok(thread_id_matches(),
   "check main thread id saved and is current thread");

# This test isn't too useful on Linux, it passes without the fix.
#
# thread ids are unique only within a process, so it's valid for Linux
# pthread_self() to return the same id for the main thread after a
# fork.
#
# This may be different on other POSIX-likes.
SKIP:
{
    $Config{d_fork}
      or skip "Need fork", 1;
    my $pid = fork;
    defined $pid
      or skip "Fork failed", 1;
    if ($pid == 0) {
        ok(thread_id_matches(), "check main thread id is updated by fork");
        exit;
    }
    else {
        waitpid($pid, 0);
    }
}

{
    $Config{d_fork}
      or skip "Need fork", 1;
    my $pid = fork;
    defined $pid
      or skip "Fork failed", 1;
    if ($pid == 0) {
        # ensure the main thread saved is valid after fork
        my $saw_signal;
        local $SIG{USR1} = sub { ++$saw_signal };
        my $pid = make_signal_thread();
        join_signal_thread($pid);
        ok($saw_signal, "saw signal sent to non-perl thread in child");
        exit 0;
    }
    else {
        is(waitpid($pid, 0), $pid, "wait child");
        # catches the child segfaulting for example
        is($?, 0, "child success");
    }
}

{
    my $saw_signal;
    local $SIG{USR1} = sub { ++$saw_signal };
    my $pid = make_signal_thread();
    join_signal_thread($pid);
    ok($saw_signal, "saw signal sent to non-perl thread");
}


done_testing();

use strict;
use Config qw(%Config);
use Test::More;
use Win32;

# Cygwin builds set useithreads=define but use the OS's real fork(),
# not the Win32 fork emulation — so gate on $^O as well.
my $fork_emulation = $^O eq 'MSWin32' && ($Config{useithreads} // '') eq 'define';

plan tests => $fork_emulation ? 4 : 2;

my $pid = $$+0; # make sure we don't copy any magic to $pid

if ($^O eq "cygwin") {
    SKIP: {
        skip 'Cygwin::pid_to_winpid is not available', 1
            if !defined &Cygwin::pid_to_winpid;

        is(Cygwin::pid_to_winpid($pid), Win32::GetCurrentProcessId());
    }
}
else {
    is($pid, Win32::GetCurrentProcessId());
}

if ($fork_emulation) {
    # This test relies on the implementation detail that the fork() emulation
    # uses the negative value of the thread id as a pseudo process id.
    if (my $child = fork) {
        Test::More->builder->no_ending(1);
        waitpid($child, 0);
        exit $?;
    }
    is(-$$, Win32::GetCurrentThreadId());

    # GetCurrentProcessId() should still return the real PID
    is($pid, Win32::GetCurrentProcessId());
    isnt($$, Win32::GetCurrentProcessId());
}
else {
    # here we just want to see something.
    cmp_ok(Win32::GetCurrentThreadId(), '>', 0);
}

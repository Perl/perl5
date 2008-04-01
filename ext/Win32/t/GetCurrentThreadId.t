use strict;
use Config qw(%Config);
use Test;
use Win32;

plan tests => 1;

# This test relies on the implementation detail that the fork() emulation
# uses the negative value of the thread id as a pseudo process id.
if ($Config{ccflags} =~ /PERL_IMPLICIT_SYS/) {
    if (my $pid = fork) {
	waitpid($pid, 0);
	exit 0;
    }
    ok(-$$, Win32::GetCurrentThreadId());
}
else {
    # here we just want to see something.
    ok(Win32::GetCurrentThreadId() > 0);
}

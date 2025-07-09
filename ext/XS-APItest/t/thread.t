#!perl
use warnings;
use strict;
use Test2::IPC;
use Test2::Tools::Basic;
use Config;

BEGIN {
    skip_all "Not pthreads or is win32"
      if !$Config{usethreads} || $^O eq "MSWin32";
}

use XS::APItest qw(thread_id_matches);

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

done_testing();

package t::Watchdog;

use strict;

use Config;
use Test::More;

my $waitfor = 360; # 30-45 seconds is normal (load affects this).
my $watchdog_pid;
my $TheEnd;

if ($Config{d_fork}) {
    print("# I am the main process $$, starting the watchdog process...\n");
    $watchdog_pid = fork();
    if (defined $watchdog_pid) {
        if ($watchdog_pid == 0) { # We are the kid, set up the watchdog.
            my $ppid = getppid();
            print("# I am the watchdog process $$, sleeping for $waitfor seconds...\n");
            sleep($waitfor - 2);    # Workaround for perlbug #49073
            sleep(2);               # Wait for parent to exit
            if (kill(0, $ppid)) {   # Check if parent still exists
                warn "\n$0: overall time allowed for tests (${waitfor}s) exceeded!\n";
                print("Terminating main process $ppid...\n");
                kill('KILL', $ppid);
                print("# This is the watchdog process $$, over and out.\n");
            }
            exit(0);
        } else {
            print("# The watchdog process $watchdog_pid launched, continuing testing...\n");
            $TheEnd = time() + $waitfor;
        }
    } else {
        warn "$0: fork failed: $!\n";
    }
} else {
    print("# No watchdog process (need fork)\n");
}

END {
    if ($watchdog_pid) { # Only in the main process.
        my $left = $TheEnd - time();
        printf("# I am the main process $$, terminating the watchdog process $watchdog_pid before it terminates me in %d seconds (testing took %d seconds).\n", $left, $waitfor - $left);
        if (kill(0, $watchdog_pid)) {
            local $? = 0;
            my $kill = kill('KILL', $watchdog_pid); # We are done, the watchdog can go.
            wait();
            printf("# kill KILL $watchdog_pid = %d\n", $kill);
        }
        unlink("ktrace.out"); # Used in BSD system call tracing.
        print("# All done.\n");
    }
}

1;

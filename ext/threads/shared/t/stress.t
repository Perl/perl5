use strict;
use warnings;

BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        unshift @INC, '../lib';
    }
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

use ExtUtils::testlib;

my $Base = 0;
sub ok {
    my ($id, $ok, $why) = @_;
    $id += $Base;

    # You have to do it this way or VMS will get confused.
    if ($ok) {
        print("ok $id\n");
    } else {
        print ("not ok $id\n");
        printf("# Failed test at line %d\n", (caller)[2]);
        print ("#   Reason: $why\n");
    }

    return ($ok);
}

BEGIN {
    $| = 1;
    print("1..50\n");   ### Number of tests that will be run ###
};

use threads;
use threads::shared;

### Start of Testing ###

#####
#
# Launches a bunch of threads which are then
# restricted to finishing in numerical order
#
# Frequently fails under MSWin32 due to deadlocking bug in Windows
#   http://rt.perl.org/rt3/Public/Bug/Display.html?id=41574
#   http://support.microsoft.com/kb/175332
#
#####
{
    my $cnt = 50;

    my $TIMEOUT = 30;

    my $mutex = 1;
    share($mutex);

    my @threads;
    for (1..$cnt) {
        $threads[$_] = threads->create(sub {
                            my $tnum = shift;
                            my $timeout = time() + $TIMEOUT;

                            # Randomize the amount of work the thread does
                            my $sum;
                            for (0..(500000+int(rand(500000)))) {
                                $sum++
                            }

                            # Lock the mutex
                            lock($mutex);

                            # Wait for my turn to finish
                            while ($mutex != $tnum) {
                                if (! cond_timedwait($mutex, $timeout)) {
                                    if ($mutex == $tnum) {
                                        return ('timed out - cond_broadcast not received');
                                    } else {
                                        return ('timed out');
                                    }
                                }
                            }

                            # Finish up
                            $mutex++;
                            cond_broadcast($mutex);
                            return ('okay');
                      }, $_);
    }

    # Gather thread results
    for (1..$cnt) {
        my $rc = $threads[$_]->join() || 'Thread failed';
        ok($_, ($rc eq 'okay'), $rc);
    }

    $Base += $cnt;
}

# EOF

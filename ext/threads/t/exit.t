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

use threads;

BEGIN {
    eval {
        require threads::shared;
        import threads::shared;
    };
    if ($@ || ! $threads::shared::threads_shared) {
        print("1..0 # Skip: threads::shared not available\n");
        exit(0);
    }

    $| = 1;
    print("1..226\n");   ### Number of tests that will be run ###
};

my $TEST;
BEGIN {
    share($TEST);
    $TEST = 1;
}

ok(1, 'Loaded');

sub ok {
    my ($ok, $name) = @_;
    if (! defined($name)) {
        # Bug in test
        $name = $ok;
        $ok = 0;
    }
    chomp($name);

    lock($TEST);
    my $id = $TEST++;

    # You have to do it this way or VMS will get confused.
    if ($ok) {
        print("ok $id - $name\n");
    } else {
        print("not ok $id - $name\n");
        printf("# Failed test at line %d\n", (caller)[2]);
        print(STDERR "# FAIL: $name\n") if (! exists($ENV{'PERL_CORE'}));
    }

    return ($ok);
}


### Start of Testing ###

$SIG{'__WARN__'} = sub {
    my $msg = shift;
    ok(0, "WARN in main: $msg");
};
$SIG{'__DIE__'} = sub {
    my $msg = shift;
    ok(0, "DIE in main: $msg");
};


sub nasty
{
    my ($term, $warn, $die) = @_;
    my $tid = threads->tid();

    $SIG{'__WARN__'} = sub {
        my $msg = $_[0];
        ok($msg =~ /Thread \d+ terminated abnormally/, "WARN: $msg");
        if ($warn eq 'return') {
            return ('# __WARN__ returned');
        } elsif ($warn eq 'die') {
            die('# __WARN__ dying');
        } elsif ($warn eq 'exit') {
            CORE::exit(20);
        } else {
            threads->exit(21);
        }
    };

    $SIG{'__DIE__'} = sub {
        my $msg = $_[0];
        ok(1, "DIE: $msg");
        if ($die eq 'return') {
            return ('# __DIE__ returned');
        } elsif ($die eq 'die') {
            die('# __DIE__ dying');
        } elsif ($die eq 'exit') {
            CORE::exit(30);
        } else {
            threads->exit(31);
        }
    };

    ok(1, "Thread $tid");
    if ($term eq 'return') {
        return ('# Thread returned');
    } elsif ($term eq 'die') {
        die('# Thread dying');
    } elsif ($term eq 'exit') {
        CORE::exit(10);
    } else {
        threads->exit(11);
    }
}


my @exit_types = qw(return die exit threads->exit);

# Test (non-trivial) combinations of termination methods
#   WRT the thread and its handlers
foreach my $die (@exit_types) {
    foreach my $wrn (@exit_types) {
        foreach my $thr (@exit_types) {
            # Things are well behaved if the thread just returns
            next if ($thr eq 'return');

            # Skip combos with the die handler
            #   if neither the thread nor the warn handler dies
            next if ($thr ne 'die' && $wrn ne 'die' && $die ne 'return');

            # Must send STDERR to file to filter out 'un-capturable' output
            my $rc;
            eval {
                local *STDERR;
                if (! open(STDERR, '>tmp.stderr')) {
                    die('Failed to create "tmp.stderr"');
                }

                $rc = threads->create('nasty', $thr, $wrn, $die)->join();

                close(STDERR);
            };

            # Filter out 'un-capturable' output
            if (open(IN, 'tmp.stderr')) {
                while (my $line = <IN>) {
                    if ($line !~ /^#/) {
                        print(STDERR $line);
                    }
                }
                close(IN);
            } else {
                ok(0, "Failed to open 'tmp.stderr': $!");
            }
            unlink('tmp.stderr');

            ok(! $@, ($@) ? "Thread problem: $@" : "Thread ran okay");
            ok(! defined($rc), "Thread returned 'undef'");
        }
    }
}


# Again with:
no warnings 'threads';

sub less_nasty
{
    my ($term, $warn, $die) = @_;
    my $tid = threads->tid();

    $SIG{'__WARN__'} = sub {
        my $msg = $_[0];
        ok(0, "WARN: $msg");
        if ($warn eq 'return') {
            return ('# __WARN__ returned');
        } elsif ($warn eq 'die') {
            die('# __WARN__ dying');
        } elsif ($warn eq 'exit') {
            CORE::exit(20);
        } else {
            threads->exit(21);
        }
    };

    $SIG{'__DIE__'} = sub {
        my $msg = $_[0];
        ok(1, "DIE: $msg");
        if ($die eq 'return') {
            return ('# __DIE__ returned');
        } elsif ($die eq 'die') {
            die('# __DIE__ dying');
        } elsif ($die eq 'exit') {
            CORE::exit(30);
        } else {
            threads->exit(31);
        }
    };

    ok(1, "Thread $tid");
    if ($term eq 'return') {
        return ('# Thread returned');
    } elsif ($term eq 'die') {
        die('# Thread dying');
    } elsif ($term eq 'exit') {
        CORE::exit(10);
    } else {
        threads->exit(11);
    }
}

foreach my $die (@exit_types) {
    foreach my $wrn (@exit_types) {
        foreach my $thr (@exit_types) {
            # Things are well behaved if the thread just returns
            next if ($thr eq 'return');

            # Skip combos with the die handler
            #   if neither the thread nor the warn handler dies
            next if ($thr ne 'die' && $wrn ne 'die' && $die ne 'return');

            my $rc;
            eval { $rc = threads->create('less_nasty', $thr, $wrn, $die)->join() };
            ok(! $@, ($@) ? "Thread problem: $@" : "Thread ran okay");
            ok(! defined($rc), "Thread returned 'undef'");
        }
    }
}


# Check termination warning concerning running threads
$SIG{'__WARN__'} = sub {
    my $msg = shift;
    if ($^O eq 'VMS') {
        ok($msg =~ /0 running and unjoined/,  '0 running and unjoined (VMS)');
        ok($msg =~ /3 finished and unjoined/, '3 finished and unjoined (VMS)');
        ok($msg =~ /0 running and detached/,  '0 finished and detached (VMS)');
    } else {
        ok($msg =~ /1 running and unjoined/,  '1 running and unjoined');
        ok($msg =~ /2 finished and unjoined/, '2 finished and unjoined');
        ok($msg =~ /3 running and detached/,  '3 finished and detached');
    }
};

threads->create(sub { sleep(100); });
threads->create(sub {});
threads->create(sub {});
threads->create(sub { sleep(100); })->detach();
threads->create(sub { sleep(100); })->detach();
threads->create(sub { sleep(100); })->detach();
threads->yield();
sleep(1);

# EOF

use strict;
use warnings;

# This test file contains code which sometimes used to deadlock.
# The only test result it gives is that the file ran to completion.
# There aren't any watchdog timers set because once two threads
# own locks 1 and 2 and are waiting on locks 2 and 1, nothing is
# going to cleanly free those locks and allow global cleanup to run to
# completion: such cleanup would try to free objects containing
# threads etc and would try to lock when freeing such objects and itself
# deadlock.

BEGIN {
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}


sub pass {
    my ($id, $name) = @_;
    print("ok $id - $name\n");
}

BEGIN {
    $| = 1;
    print("1..2\n");   ### Number of tests that will be run ###
};

use threads;

if ($threads::VERSION && ! $ENV{'PERL_CORE'}) {
    print(STDERR "# Testing threads $threads::VERSION\n");
}

pass(1, 'Loaded');

### Start of Testing ###


# A child thread, which does nothing except to ensure that on exit, it
# has a global variable which is a threads object which has been joined,
# (so no interpreter) but still needs to be freed.
#
sub child {
    # using package variable means child thread object is only freed
    # during global destruction of parent
    our $t = threads->new(sub {});
    $t->join();
}

# start and join a thread few times. We're interested in the freeing
# of the interpreter which happens during the joining of the thread.

sub joiner {
    for (1..10) {
        threads->new(\&child)->join();
        1;
    }
}

# Repeatedly walk the list of pool objects: each iteration involves
# locking the pool, then in turn locking each thread object in the list.

sub lister {
    my $i = 0;
    while (1) {
        my $c = threads->list();
        $i++;
        last if $i > 10000;
    }
}


{
    my @t;
    push @t, threads->new(\&lister, $_);
    push @t, threads->new(\&joiner, $_);
    $_->join() for @t;
}

pass(2, 'ran to completion');

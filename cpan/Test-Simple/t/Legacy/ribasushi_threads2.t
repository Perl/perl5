use Config;

BEGIN {
    if ($] == 5.010000) {
        print "1..0 # Threads are broken on 5.10.0\n";
        exit 0;
    }

    my $works = 1;
    $works &&= $] >= 5.008001;
    $works &&= $Config{'useithreads'};
    $works &&= eval { require threads; 'threads'->import; 1 };

    unless ($works) {
        print "1..0 # Skip no working threads\n";
        exit 0;
    }

    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # Skip many perls have broken threads.  Enable with AUTHOR_TESTING.\n";
        exit 0;
    }

    if ($INC{'Devel/Cover.pm'}) {
        print "1..0 # SKIP Devel::Cover does not work with threads yet\n";
        exit 0;
    }
}

use threads;

use strict;
use warnings;

use Test::More;

{
    my $todo = sub {
        my $out;
        ok(1);
        42;
    };

    is(
        threads->create($todo)->join,
        42,
        "Correct result after do-er",
    );
}

done_testing;

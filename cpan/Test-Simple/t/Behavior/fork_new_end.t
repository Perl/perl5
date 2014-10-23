use strict;
use warnings;

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}

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

    unless ( $ENV{AUTHOR_TESTING} ) {
        print "1..0 # Skip many perls have broken threads.  Enable with AUTHOR_TESTING.\n";
        exit 0;
    }
}

use Test::More tests => 4;

ok(1, "outside before");

my $run = sub {
    ok(1, 'in thread1');
    ok(1, 'in thread2');
};


my $t = threads->create($run);

ok(1, "outside after");

$t->join;

END {
    print "XXX: " . Test::Builder->new->is_passing . "\n";
}

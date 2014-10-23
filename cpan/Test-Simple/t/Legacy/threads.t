#!/usr/bin/perl -w

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

use strict;
use Test::Builder;

my $Test = Test::Builder->new;
$Test->exported_to('main');
$Test->plan(tests => 6);

for(1..5) {
	'threads'->create(sub {
          $Test->ok(1,"Each of these should app the test number")
    })->join;
}

$Test->is_num($Test->current_test(), 5,"Should be five");

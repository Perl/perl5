use strict;
use warnings;

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}

use Test::CanThread qw/AUTHOR_TESTING/;
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

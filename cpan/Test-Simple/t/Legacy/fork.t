#!/usr/bin/perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}

use Test::CanFork;

use Test::More tests => 1;

my $pid = fork;
if( $pid ) { # parent
    pass("Only the parent should process the ending, not the child");
    waitpid($pid, 0);
}
else {
    exit;   # child
}


#!perl -w

# Tests if $$ and getppid return consistent values across threads

BEGIN {
    chdir 't' if -d 't';
    @INC = qw(../lib);
    require './test.pl';
}

use strict;
use Config;

plan tests => 2;

BEGIN {
    if (!$Config{useithreads}) {
	print "1..0 # Skip: no ithreads\n";
	exit;
    }
    if (!$Config{d_getppid}) {
	print "1..0 # Skip: no getppid\n";
	exit;
    }
}

use threads;
use threads::shared;

my ($pid, $ppid) = ($$, getppid());
my $pid2 : shared = 0;
my $ppid2 : shared = 0;

new threads( sub { ($pid2, $ppid2) = ($$, getppid()); } ) -> join();

is($pid,  $pid2,  'pids');
is($ppid, $ppid2, 'ppids');

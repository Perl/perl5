#!perl -w

# Tests if $$ and getppid return consistent values across threads

BEGIN {
    chdir 't' if -d 't';
    @INC = qw(../lib);
}

use strict;
use Config;

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

print "1..2\n";
print "not " if $pid  != $pid2;  print "ok 1 - pids\n";
print "not " if $ppid != $ppid2; print "ok 2 - ppids\n";

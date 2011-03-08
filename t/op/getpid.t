#!perl -w

# Tests if $$ and getppid return consistent values across threads

BEGIN {
    chdir 't' if -d 't';
    @INC = qw(../lib);
    require './test.pl';
}

use strict;
use Config;

BEGIN {
    skip_all_without_config(qw(useithreads d_getppid));
    skip_all_if_miniperl("no dynamic loading on miniperl, no threads");
    eval 'use threads; use threads::shared';
    plan tests => 3;
    if ($@) {
	fail("unable to load thread modules");
    }
    else {
	pass("thread modules loaded");
    }
}

my ($pid, $ppid) = ($$, getppid());
my $pid2 : shared = 0;
my $ppid2 : shared = 0;

new threads( sub { ($pid2, $ppid2) = ($$, getppid()); } ) -> join();

is($pid,  $pid2,  'pids');
is($ppid, $ppid2, 'ppids');

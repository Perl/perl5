#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    skip_all_if_miniperl("miniperl can't load IO::File");
}

$|  = 1;
use warnings;
use Config;
use threads;

use constant thread_count => 20;

plan tests => thread_count;

my @threads;
for (1..thread_count) {
    push @threads, threads->create(sub {
        require IO::Handle;
        return 1;
    });
}
ok $_->join for @threads;

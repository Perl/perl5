
BEGIN {
    chdir 't' if -d 't';
    @INC = qw(../lib .);
    require Config; import Config;
    unless ($Config{'useithreads'}) {
        print "1..0 # Skip: no useithreads\n";
        exit 0;
    }
    require "test.pl";
}

use ExtUtils::testlib;

use strict;


BEGIN { $| = 1; print "1..8\n" };

use_ok('threads');

ok(threads->self == (threads->list)[0]);


threads->create(sub {})->join();
ok(scalar @{[threads->list]} == 1);

my $thread = threads->create(sub {});
ok(scalar @{[threads->list]} == 2);
$thread->join();
ok(scalar @{[threads->list]} == 1);

curr_test(6);

# Just a sleep() would not guarantee that we sleep and will not
# wake up before the just created thread finishes.  Instead, let's
# use the filesystem as a semaphore.  Creating a directory and removing
# it should be a reasonably atomic operation even over NFS. 
# Also, we do not want to depend here on shared variables.

mkdir "thrsem", 0700;

$thread = threads->create(sub { my $ret = threads->self == (threads->list)[1];
			        rmdir "thrsem";
			        return $ret });

sleep 1 while -d "thrsem";

ok($thread == (threads->list)[1]);
ok($thread->join());
ok(scalar @{[threads->list]} == 1);

END {
    1 while rmdir "thrsem";
}

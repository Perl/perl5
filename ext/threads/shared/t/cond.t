BEGIN {
    chdir 't' if -d 't';
    push @INC ,'../lib';
    require Config; import Config;
    unless ($Config{'useithreads'}) {
        print "1..0 # Skip: no threads\n";
        exit 0;
    }
}
$|++;
print "1..5\n";
use strict;


use threads;

use threads::shared;

my $lock : shared;

sub foo {
    lock($lock);
    print "ok 1\n";
    my $tr2 = threads->create(\&bar);
    cond_wait($lock);
    $tr2->join();
    print "ok 5\n";
}

sub bar {
    print "ok 2\n";
    lock($lock);
    print "ok 3\n";
    cond_signal($lock);
    print "ok 4\n";
}

my $tr  = threads->create(\&foo);
$tr->join();


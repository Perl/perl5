BEGIN {
    chdir 't' if -d 't';
    @INC = qw(../lib .);
    require Config; import Config;
    unless ($Config{'useithreads'}) {
        print "1..0 # Skip: no threads\n";
        exit 0;
    }
    require "test.pl";
}
print "1..4\n";
use strict;

use threads;

use threads::shared;

my $lock : shared;

sub foo {
    my $ret = 0;	
    lock($lock);
    $ret += 1;
    cond_wait($lock);
    $ret += 2;
    return $ret;
}

sub bar {
    my $ret = 0;	
    lock($lock);
    $ret += 1;
    cond_signal($lock);
    $ret += 2;
    return $ret;
}

my $tr1  = threads->create(\&foo);
my $tr2 = threads->create(\&bar);
my $rt1 = $tr1->join();
my $rt2 = $tr2->join();
ok($rt1 & 1);
ok($rt1 & 2);
ok($rt2 & 1);
ok($rt2 & 2);



# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use ExtUtils::testlib;
use Test;
use strict;
BEGIN { plan tests => 16 };
use threads;


ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
#my $bar;

skip('The ignores are here to keep test numbers correct','The ignores are here to keep test numbers correct');

#test passing of simple argument
my $thread = threads->create(sub { ok('bar',$_[0]) },"bar");
$thread->join();
skip('Ignore','Ignore');

#test passing of complex argument

$thread = threads->create(sub { ok('bar',$_[0]->[0]->{foo})},[{foo => 'bar'}]);

$thread->join();
skip('Ignore','Ignore');

#test execuion of normal sub
sub bar { ok(1,shift()) }
threads->create(\&bar,1)->join();
skip('Ignore','Ignore');

#check Config
ok("1", "$Config::threads");

#test trying to detach thread

my $thread1 = threads->create(sub {ok(1);});

$thread1->detach();
skip('Ignore','Ignore');
sleep 1;
ok(1);
#create nested threads
unless($^O eq 'MSWin32') {
	my $thread3 = threads->create(sub { threads->create(sub {})})->join();
	ok(1);
} else {
	skip('thread trees are unsafe under win32','thread trees are unsafe under win32');
}
skip('Ignore','Ignore');

my @threads;
my $i;
unless($^O eq 'MSWin32') {
for(1..25) {	
	push @threads, threads->create(sub { for(1..100000) { my $i  } threads->create(sub { sleep 2})->join() });
}
foreach my $thread (@threads) {
	$thread->join();
}
}
ok(1);
threads->create(sub { 
    my $self = threads->self();
    ok($self->tid(),57);
})->join();
skip('Ignore','Ignore');
threads->create(sub { 
    my $self = threads->self();
    ok($self->tid(),58);
})->join();
skip('Ignore','Ignore');

#check support for threads->self() in main thread
ok(0,threads->self->tid());
ok(0,threads->tid());











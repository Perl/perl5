

#
# The reason this does not use a Test module is that
# they mess up test numbers between threads
#
# And even when that will be fixed, this is a basic
# test and should not rely on shared variables
# 
#
#########################


use ExtUtils::testlib;
use strict;
BEGIN { print "1..12\n" };
use threads;



print "ok 1\n";


#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
#my $bar;
sub ok {	
    my ($id, $ok, $name) = @_;
    
    # You have to do it this way or VMS will get confused.
    print $ok ? "ok $id - $name\n" : "not ok $id - $name\n";

    printf "# Failed test at line %d\n", (caller)[2] unless $ok;
    
    return $ok;
}




#test passing of simple argument
my $thread = threads->create(sub { ok(2, 'bar' eq $_[0]),"" },"bar");
$thread->join();


#test passing of complex argument

$thread = threads->create(sub { ok(3, 'bar' eq $_[0]->[0]->{foo})},[{foo => 'bar'}]);

$thread->join();


#test execuion of normal sub
sub bar { ok(4,shift() == 1,"") }
threads->create(\&bar,1)->join();


#check Config
ok(5, 1 == $Config::threads,"");

#test trying to detach thread

my $thread1 = threads->create(sub {ok(6,1,"")});

$thread1->detach();
sleep 1;
ok(7,1,"");
#create nested threads
unless($^O eq 'MSWin32') {
	my $thread3 = threads->create(sub { threads->create(sub {})})->join();
}


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
ok(8,1,"");
threads->create(sub { 
    my $self = threads->self();
    ok(9,$self->tid() == 57,"");
})->join();
threads->create(sub { 
    my $self = threads->self();
    ok(10,$self->tid() == 58,"");
})->join();

#check support for threads->self() in main thread
ok(11, 0 == threads->self->tid(),"");
ok(12, 0 == threads->tid(),"Check so that tid for threads work for current tid");













BEGIN {
#    chdir 't' if -d 't';
#    push @INC ,'../lib';
#    require Config; import Config;
#    unless ($Config{'useithreads'}) {
        print "1..0 # Skip: might still hang\n";
        exit 0;
#    }
}


use threads;
use threads::queue;

$q = new threads::shared::queue;

sub reader {
    my $tid = threads->self->tid;
    my $i = 0;
    while (1) {
	$i++;
#	print "reader (tid $tid): waiting for element $i...\n";
	my $el = $q->dequeue;
#	print "reader (tid $tid): dequeued element $i: value $el\n";
	select(undef, undef, undef, rand(2));
	if ($el == -1) {
	    # end marker
#	    print "reader (tid $tid) returning\n";
	    return;
	}
    }
}

my $nthreads = 1;
my @threads;

for (my $i = 0; $i < $nthreads; $i++) {
    push @threads, threads->new(\&reader, $i);
}

for (my $i = 1; $i <= 10; $i++) {
    my $el = int(rand(100));
    select(undef, undef, undef, rand(2));
#    print "writer: enqueuing value $el\n";
    $q->enqueue($el);
}

$q->enqueue((-1) x $nthreads); # one end marker for each thread

for(@threads) {
	print "waiting for join\n";
	$_->join();
	
}




use Thread;
use Thread::Queue;

$q = new Thread::Queue;

sub reader {
    my $i;
    for ($i = 1; $i <= 10; $i++) {
	print "reader: waiting for element $i...\n";
	my $el = $q->dequeue;
	print "reader: dequeued element $i: value $el\n";
    }
}

new Thread \&reader;
my $i;
for ($i = 1; $i <= 10; $i++) {
    my $el = int(rand(100));
    select(undef, undef, undef, rand(2));
    print "writer: enqueuing value $el\n";
    $q->enqueue($el);
}

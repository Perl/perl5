use Thread 'fast';

sub printstuff {
    my $count = 2000;
    while ($count--) {
	$lock->waituntil(sub { $inuse ? 0 : ($inuse = 1) });
	print "A";
	$lock->signal(sub { $inuse = 0 });
    }
    $lock->signal(sub { $inuse = 42 });
}

$|  = 1;
$inuse = 0;
$lock = new Thread::Cond;
$t = new Thread \&printstuff;
PAUSE: while (!$done) {
    sleep 3;
    $lock->waituntil(sub {
	$inuse != 42 ? $inuse ? 0 : ($inuse = 1) : ($done = 1, 0)
    });
    last PAUSE if $done;
    sleep 1;
    $lock->signal(sub { $inuse = 0 });
}
print "main exiting\n";

use Thread;

sub reader {
    my $line;
    while ($line = <STDIN>) {
	print "reader: $line";
    }
    print "End of input in reader\n";
    return 0;
}

$r = new Thread \&reader;
$count = 20;
while ($count--) {
    sleep 1;
    print "ping $count\n";
}



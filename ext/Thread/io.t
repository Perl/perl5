use Thread;

sub reader {
    my $line;
    while ($line = <STDIN>) {
	print "reader: $line";
    }
    print "End of input in reader\n";
    return 0;
}

print <<'EOT';
This test starts up a thread to read and echo whatever is typed on
the keyboard/stdin, line by line, while the main thread counts down
to zero. The test stays running until both the main thread has
finished counting down and the I/O thread has seen end-of-file on
the terminal/stdin.
EOT

$r = new Thread \&reader;
$count = 10;
while ($count--) {
    sleep 1;
    print "ping $count\n";
}

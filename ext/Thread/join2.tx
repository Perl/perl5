BEGIN {
    eval { require Config; import Config };
    if ($@) {
	print "1..0 # Skip: no Config\n";
	exit(0);
    }
    if ($Config{extensions} !~ /\bThread\b/) {
	print "1..0 # Skip: no use5005threads\n";
	exit(0);
    }
}

use Thread;
sub foo {
    print "In foo with args: @_\n";
    return (7, 8, 9);
}

print "Starting thread\n";
$t = new Thread \&foo, qw(foo bar baz);
sleep 2;
print "Joining with $t\n";
@results = $t->join();
print "Joining returned @results\n";

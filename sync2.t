use Thread;

$global = undef;

sub single_file {
    my $who = shift;
    my $i;

    print "Uh oh: $who entered while locked by $global\n" if $global;
    $global = $who;
    print "[";
    for ($i = 0; $i < int(50 * rand); $i++) {
	print $who;
    }
    print "]";
    $global = undef;
}

sub start_a {
    my ($i, $j);
    for ($j = 0; $j < 50; $j++) {
	single_file("A");
	for ($i = 0; $i < int(50 * rand); $i++) {
	    print "a";
	}
    }
}

sub start_b {
    my ($i, $j);
    for ($j = 0; $j < 50; $j++) {
	single_file("A");
	for ($i = 0; $i < int(50 * rand); $i++) {
	    print "b";
	}
    }
}

sub start_c {
    my ($i, $j);
    for ($j = 0; $j < 50; $j++) {
	single_file("c");
	for ($i = 0; $i < int(50 * rand); $i++) {
	    print "C";
	}
    }
}

$| = 1;
srand($$^$^T);
Thread::sync(\&single_file);

$foo = new Thread \&start_a;
$bar = new Thread \&start_b;
$baz = new Thread \&start_c;
print "\nmain: joining...\n";
$foo->join;
$bar->join;
$baz->join;

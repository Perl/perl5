#!./perl

# On platforms that don't support all of the filetest operators the code
# that faked the results of missing tests used to leave the test's
# argument on the stack.

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

my @ops = split //, 'rwxoRWXOezsfdlpSbctugkTMBAC';

plan( tests => @ops * 3 );

for my $op (@ops) {
    ok( 1 == @{ [ eval "-$op 'TEST'" ] }, "-$op returns single value" );

    my $count = 0;
    my $t;
    for my $m ("a", "b") {
	if ($count == 0) {
	    $t = eval "-$op _" ? 0 : "foo";
	}
	elsif ($count == 1) {
	    is($m, "b", "-$op did not remove too many values from the stack");
	}
	$count++;
    }

    $count = 0;
    for my $m ("c", "d") {
	if ($count == 0) {
	    $t = eval "-$op -e \$^X" ? 0 : "bar";
	}
	elsif ($count == 1) {
	    local $TODO;
	    if ($op eq 'T' or $op eq 't' or $op eq 'B') {
		$TODO = "[perl #77388] stacked file test does not work with -$op";
	    }
	    is($m, "d", "-$op -e \$^X did not remove too many values from the stack");
	}
	$count++;
    }
}

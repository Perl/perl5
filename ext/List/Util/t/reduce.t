BEGIN {
	chdir 't' if -d 't';
	@INC = '../lib';
	require Config; import Config;
	if ($Config{extensions} !~ /\bList\/Util\b/) {
	    print "1..0 # Skip: List::Util was not built\n";
	    exit 0;
	}
}

use List::Util qw(reduce min);

print "1..5\n";

print "not " if defined reduce {};
print "ok 1\n";

print "not " unless 9 == reduce { $a / $b } 756,3,7,4;
print "ok 2\n";

print "not " unless 9 == reduce { $a / $b } 9;
print "ok 3\n";

@a = map { rand } 0 .. 20;
print "not " unless min(@a) == reduce { $a < $b ? $a : $b } @a;
print "ok 4\n";

@a = map { pack("C", int(rand(256))) } 0 .. 20;
print "not " unless join("",@a) eq reduce { $a . $b } @a;
print "ok 5\n";

#!./perl

BEGIN {
    unless (-d 'blib') {
	chdir 't' if -d 't';
	@INC = '../lib';
	require Config; import Config;
	keys %Config; # Silence warning
	if ($Config{extensions} !~ /\bList\/Util\b/) {
	    print "1..0 # Skip: List::Util was not built\n";
	    exit 0;
	}
    }
}


use List::Util qw(reduce min);
use Test::More tests => 14;

my $v = reduce {};

is( $v,	undef,	'no args');

$v = reduce { $a / $b } 756,3,7,4;
is( $v,	9,	'4-arg divide');

$v = reduce { $a / $b } 6;
is( $v,	6,	'one arg');

@a = map { rand } 0 .. 20;
$v = reduce { $a < $b ? $a : $b } @a;
is( $v,	min(@a),	'min');

@a = map { pack("C", int(rand(256))) } 0 .. 20;
$v = reduce { $a . $b } @a;
is( $v,	join("",@a),	'concat');

sub add {
  my($aa, $bb) = @_;
  return $aa + $bb;
}

$v = reduce { my $t="$a $b\n"; 0+add($a, $b) } 3, 2, 1;
is( $v,	6,	'call sub');

# Check that eval{} inside the block works correctly
$v = reduce { eval { die }; $a + $b } 0,1,2,3,4;
is( $v,	10,	'use eval{}');

$v = !defined eval { reduce { die if $b > 2; $a + $b } 0,1,2,3,4 };
ok($v, 'die');

sub foobar { reduce { (defined(wantarray) && !wantarray) ? $a+1 : 0 } 0,1,2,3 }
($v) = foobar();
is( $v,	3,	'scalar context');

sub add2 { $a + $b }

$v = reduce \&add2, 1,2,3;
is( $v,	6,	'sub reference');

$v = reduce { add2() } 3,4,5;
is( $v, 12,	'call sub');


$v = reduce { eval "$a + $b" } 1,2,3;
is( $v, 6, 'eval string');

$a = 8; $b = 9;
$v = reduce { $a * $b } 1,2,3;
is( $a, 8, 'restore $a');
is( $b, 9, 'restore $b');

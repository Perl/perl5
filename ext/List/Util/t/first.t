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

use Test::More tests => 8;
use List::Util qw(first);
my $v;

ok(defined &first,	'defined');

$v = first { 8 == ($_ - 1) } 9,4,5,6;
is($v, 9, 'one more than 8');

$v = first { 0 } 1,2,3,4;
is($v, undef, 'none match');

$v = first { 0 };
is($v, undef, 'no args');

$v = first { $_->[1] le "e" and "e" le $_->[2] }
		[qw(a b c)], [qw(d e f)], [qw(g h i)];
is_deeply($v, [qw(d e f)], 'reference args');

# Check that eval{} inside the block works correctly
my $i = 0;
$v = first { eval { die }; ($i == 5, $i = $_)[0] } 0,1,2,3,4,5,5;
is($v, 5, 'use of eval');

$v = eval { first { die if $_ } 0,0,1 };
is($v, undef, 'use of die');

sub foobar {  first { !defined(wantarray) || wantarray } "not ","not ","not " }

($v) = foobar();
is($v, undef, 'wantarray');



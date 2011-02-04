#!./perl -w

BEGIN {
	unshift @INC, 't';
	require Config;
	if (($Config::Config{'extensions'} !~ /\bB\b/) ){
		print "1..0 # Skip -- Perl configured without B module\n";
		exit 0;
	}
}

use strict;
use Config;
use File::Spec;
use File::Path;
use Test::More tests => 9;
use Test::PerlRun 'perlrun';

my $path = File::Spec->catdir( 'lib', 'B' );
unless (-d $path) {
	mkpath( $path ) or skip_all( 'Cannot create fake module path' );
}

my $file = File::Spec->catfile( $path, 'success.pm' );
local *OUT;
open(OUT, '>', $file) or skip_all( 'Cannot write fake backend module');
print OUT while <DATA>;
close *OUT;

# use() makes it difficult to avoid O::import()
require_ok( 'O' );

my ($out, $err) = get_lines( '-MO=success,foo,bar' );

is( $out->[0], 'Compiling!', 'Output should not be saved without -q switch' );
is( $out->[1], '(foo) <bar>', 'O.pm should call backend compile() method' );
is( $out->[2], '[]', 'Nothing should be in $O::BEGIN_output without -q' );
is( $err->[0], '-e syntax OK', 'O.pm should not munge perl output without -qq');

($out) = get_lines( '-MO=-q,success,foo,bar' );
isnt( $out->[1], 'Compiling!', 'Output should not be printed with -q switch' );

SKIP: {
	skip( '-q redirection does not work without PerlIO', 2)
		unless $Config{useperlio};
	is( $out->[1], "[Compiling!", '... but should be in $O::BEGIN_output' );

	($out) = get_lines( '-MO=-qq,success,foo,bar' );
	is( scalar @$out, 3, '-qq should suppress even the syntax OK message' );
}

($out, $err) = get_lines( '-MO=success,fail' );
like( $err->[0], qr/fail at .eval/,
	'O.pm should die if backend compile() does not return a subref' );

sub get_lines {
    my $compile = shift;
    my ($out, $err) = perlrun({ switches => [ '-Ilib', $compile ], code => 1 });
    return [split /[\r\n]+/, $out], [split /[\r\n]+/, $err];
}

END {
	1 while unlink($file);
	rmdir($path); # not "1 while" since there might be more in there
}

__END__
package B::success;

$| = 1;
print "Compiling!\n";

sub compile {
	return 'fail' if ($_[0] eq 'fail');
	print "($_[0]) <$_[1]>\n";
	return sub { print "[$O::BEGIN_output]\n" };
}

1;

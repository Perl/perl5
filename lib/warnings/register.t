#!./perl

BEGIN {
	chdir 't' if -d 't';
	@INC = '../lib';
}

# this package has to be compiled first
package WarnTest;

use warnings;
use warnings::register;

my $status;
sub report {
	$status = warnings::enabled() ? 1 : 0;
}

sub odd_even {
	my $num = shift;
	warnings::warn('Odd number') if warnings::enabled() and $num % 2;
}

sub odd_even_strict {
	warnings::warnif('numeric', 'Odd number') if $_[0] % 2;
}

sub disabled {
	! warnings::enabled();
}

sub category {
	warnings::warnif('closure', 'closures are neat');
	warnings::warnif('misc', 'Larry was here');
	warnings::warnif('void', '3.2 kilograms');
}

package main;

use Test::More tests => 10;

use_ok( 'warnings', 'WarnTest' );
use_ok( 'warnings::register' );

my $err;

# it's nice to trap these
local $SIG{__WARN__} = sub {
	$err = $_[0];
};

# try to trigger warning condition, first should not warn, second should
WarnTest::odd_even(2);
is( $err, '', 'no unexpected warning' );
WarnTest::odd_even(3);
like( $err, qr/^Odd number/, 'expected warning' );

$err = '';

# now disable warnings
no warnings 'WarnTest';
WarnTest::odd_even(5);
is( $err, '', 'no unexpected warning with disabled warnings' );

# check to see if warnings really are disabled
ok( WarnTest::disabled(), 'yep, warnings really are disabled' );

# now let's check lexical warnings
no warnings;
use warnings 'numeric';

# enable only one category
{
	use warnings 'misc';
	WarnTest::category();
	like( $err, qr/^Larry/, 'warning category works' );

	# now enable this category, it should overwrite the Larry warning
	use warnings 'void';
	WarnTest::category();
	like( $err, qr/^3.2 kilograms/, 'warning category still works' );
}

# and outside of the block, we should only get the odd_even warning
WarnTest::odd_even_strict(7);
WarnTest::category();
like( $err, qr/^Odd number/, 'warning scope appears to work' );

# and finally, fatal warnings
use warnings FATAL => 'WarnTest';
eval { WarnTest::odd_even(9) };
like( $@, qr/^Odd number/, 'fatal warnings work too' );


#!./perl

BEGIN {
	chdir 't' if -d 't';
	@INC = '../lib';
}

use Test::More tests => 12;

# open::import expects 'open' as its first argument, but it clashes with open()
sub import {
	open::import( 'open', @_ );
}

# can't use require_ok() here, with a name like 'open'
ok( require 'open.pm', 'requiring open' );

# this should fail
eval { import() };
like( $@, qr/needs explicit list of disciplines/, 
	'import should fail without args' );

# the hint bits shouldn't be set yet
is( $^H & $open::hint_bits, 0, 
	'hint bits should not be set in $^H before open import' );

# prevent it from loading I18N::Langinfo, so we can test encoding failures
local @INC;
$ENV{LC_ALL} = $ENV{LANG} = '';
eval { import( 'IN', 'locale' ) };
like( $@, qr/Cannot figure out an encoding/, 
	'no encoding should be found without $ENV{LANG} or $ENV{LC_ALL}' );

my $warn;
local $SIG{__WARN__} = sub {
	$warn .= shift;
};

# and it shouldn't be able to find this discipline
eval{ import( 'IN', 'macguffin' ) };
like( $warn, qr/Unknown discipline layer/, 
	'should warn about unknown discipline with bad discipline provided' );

# now load a real-looking locale
$ENV{LC_ALL} = ' .utf8';
import( 'IN', 'locale' );
is( ${^OPEN}, ':utf8\0', 
	'should set a valid locale layer' );

# and see if it sets the magic variables appropriately
import( 'IN', ':crlf' );
ok( $^H & $open::hint_bits, 
	'hint bits should be set in $^H after open import' );
is( $^H{'open_IN'}, 'crlf', 'should have set crlf layer' );

# it should reset them appropriately, too
import( 'IN', ':raw' );
is( $^H{'open_IN'}, 'raw', 'should have reset to raw layer' );

# it dies if you don't set IN, OUT, or INOUT
eval { import( 'sideways', ':raw' ) };
like( $@, qr/Unknown discipline class/, 'should croak with unknown class' );

# but it handles them all so well together
import( 'INOUT', ':raw :crlf' );
is( ${^OPEN}, ':raw :crlf\0:raw :crlf', 
	'should set multi types, multi disciplines' );
is( $^H{'open_INOUT'}, 'crlf', 'should record last layer set in %^H' );

__END__
# this one won't run as $locale_encoding is already set
# perhaps qx{} it, if it's important to run
$ENV{LC_ALL} = 'nonexistent.euc';
eval { open::_get_locale_encoding() };
like( $@, qr/too ambiguous/, 'should die with ambiguous locale encoding' );

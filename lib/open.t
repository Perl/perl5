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
ok( require 'open.pm', 'required okay!' );

# this should fail
eval { import() };
like( $@, qr/needs explicit list of disciplines/, 'import fails without args' );

# the hint bits shouldn't be set yet
is( $^H & $open::hint_bits, 0, '$^H is okay before open import runs' );

# prevent it from loading I18N::Langinfo, so we can test encoding failures
local @INC;
$ENV{LC_ALL} = '';
eval { import( 'IN', 'locale' ) };
like( $@, qr/Cannot figure out an encoding/, 'no encoding found' );

my $warn;
local $SIG{__WARN__} = sub {
	$warn .= shift;
};

# and it shouldn't be able to find this discipline
eval{ import( 'IN', 'macguffin' ) };
like( $warn, qr/Unknown discipline layer/, 'warned about unknown discipline' );

# now load a real-looking locale
$ENV{LC_ALL} = ' .utf8';
import( 'IN', 'locale' );
is( ${^OPEN}, ':utf8\0', 'set locale layer okay!' );

# and see if it sets the magic variables appropriately
import( 'IN', ':crlf' );
ok( $^H & $open::hint_bits, '$^H is set after open import runs' );
is( $^H{'open_IN'}, 'crlf', 'set crlf layer okay!' );

# it should reset them appropriately, too
import( 'IN', ':raw' );
is( $^H{'open_IN'}, 'raw', 'set raw layer okay!' );

# it dies if you don't set IN, OUT, or INOUT
eval { import( 'sideways', ':raw' ) };
like( $@, qr/Unknown discipline class/, 'croaked with unknown class' );

# but it handles them all so well together
import( 'INOUT', ':raw :crlf' );
is( ${^OPEN}, ':raw :crlf\0:raw :crlf', 'multi types, multi disciplines' );
is( $^H{'open_INOUT'}, 'crlf', 'last layer set in %^H' );

__END__
# this one won't run as $locale_encoding is already set
# perhaps qx{} it, if it's important to run
$ENV{LC_ALL} = 'nonexistent.euc';
eval { open::_get_locale_encoding() };
like( $@, qr/too ambiguous/, 'died with ambiguous locale encoding' );

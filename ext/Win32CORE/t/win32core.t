#!perl

use Test::More;
BEGIN {
    if ( $ENV{PERL_CORE} ) {
    require Config;
	if ( $Config::Config{extensions} !~ /(?<!\S)Win32CORE(?!\S)/ ) {
	    plan skip_all => "Win32CORE extension not built";
	    exit();
	}
    }

    plan tests => 2;
};
use_ok( "Win32CORE" );

# [perl #42925] - Loading Win32::GetLastError() via the forwarder function
# should not affect the last error being retrieved
$^E = 42;
is(Win32::GetLastError(), 42, 'GetLastError() works on the first call');

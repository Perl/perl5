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

    plan tests => 1;
};
use_ok( "Win32CORE" );

#!perl -wT
use strict;
use Test::More tests => 1;

BEGIN {
	use_ok( 'Sys::Syslog' );
}

diag( "Testing Sys::Syslog $Sys::Syslog::VERSION, Perl $], $^X" )
    if (! exists($ENV{'PERL_CORE'}));

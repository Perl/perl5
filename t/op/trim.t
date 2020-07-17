#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';	# for which_perl() etc
    set_up_inc('../lib');
}

use strict;
use warnings;

is( trim("    Hello world!   ")       , "Hello world!"  , 'Trim spaces' );
is( trim("\tHello world!\t")          , "Hello world!"  , 'Trim tabs' );
is( trim("\n\n\nHello\nworld!\n")     , "Hello\nworld!" , 'Trim \n' );
is( trim("\t\n\n\nHello world!\n \t") , "Hello world!"  , 'Trim all three' );
is( trim("Perl")                      , "Perl"          , 'Trim nothing' );
is( trim(undef)                       , ""              , 'Trim undef' );
is( trim('')                          , ""              , 'Trim empty string' );

is( trim("    Hello world!    "), trim_regexp_compare("    Hello world!    "), 'Trim compared to regexp' );
is( trim("\n\nHello world!    "), trim_regexp_compare("\n\nHello world!    "), 'Trim compared to regexp' );
is( trim("    Hello world!\t\t"), trim_regexp_compare("    Hello world!\t\t"), 'Trim compared to regexp' );

sub trim_regexp_compare {
	my $s = shift();

	$s =~ s/\A\s+|\s+\z//ug;

	return $s;
}

# vim: tabstop=4 shiftwidth=4 expandtab autoindent softtabstop=4

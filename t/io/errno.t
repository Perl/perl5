#!./perl
# vim: ts=4 sts=4 sw=4:

# $! may not be set if EOF was reached without any error.
# http://rt.perl.org/rt3/Ticket/Display.html?id=39060

use strict;
require './test.pl';

plan( tests => 16 );

my $test_prog = 'while(<>){print}; print $!';

for my $perlio ('perlio', 'stdio') {
    $ENV{PERLIO} = $perlio;
    for my $test_in ("test\n", "test") {
		my $test_in_esc = $test_in;
		$test_in_esc =~ s/\n/\\n/g;
		for my $rs_code ('', '$/=undef', '$/=\2', '$/=\1024') {
			is( runperl( prog => "$rs_code; $test_prog",
						 stdin => $test_in, stderr => 1),
				$test_in,
				"Wrong errno, PERLIO=$ENV{PERLIO} stdin='$test_in_esc'");
		}
	}
}

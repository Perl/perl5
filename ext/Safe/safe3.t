#!perl

BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = '../lib';
	require Config; import Config;
	if ($Config{'extensions'} !~ /\bOpcode\b/
	    && $Config{'extensions'} !~ /\bPOSIX\b/
	    && $Config{'osname'} ne 'VMS')
	{
	    print "1..0\n";
	    exit 0;
	}
    }
}

use strict;
use warnings;
use POSIX qw(ceil);
use Test::More tests => 1;
use Safe;

my $safe = new Safe;
$safe->deny('add');

# Attempt to change the opmask from within the safe compartment
$safe->reval( qq{\$_[1] = q/\0/ x } . ceil( Opcode::opcodes / 8 ) );

# Check that it didn't work
$safe->reval( q{$x + $y} );
like( $@, qr/^'?addition \(\+\)'? trapped by operation mask/,
	    'opmask still in place' );

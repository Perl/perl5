#!./perl

BEGIN {
	chdir 't' if -d 't';
	@INC = '../lib';
}

use strict;
use Config;

my $can_catch_kill = 0;

use Test::More tests => 18;

use_ok( 'sigtrap' );

package main;
local %SIG;

# use a version of sigtrap.pm somewhat too high
eval{ sigtrap->import(99999) };
like( $@, qr/version 99999 required,/, 'import excessive version number' );

# use an invalid signal name
eval{ sigtrap->import('abadsignal') };
like( $@, qr/^Unrecognized argument abadsignal/, 'send bad signame to import' );

eval{ sigtrap->import('handler') };
like( $@, qr/^No argument specified/, 'send handler without subref' );

sigtrap->import('AFAKE');
is( $SIG{AFAKE}, \&sigtrap::handler_traceback, 'install normal handler' );

sigtrap->import('die', 'AFAKE', 'stack-trace', 'FAKE2');
is( $SIG{AFAKE}, \&sigtrap::handler_die, 'install the die handler' );
is( $SIG{FAKE2}, \&sigtrap::handler_traceback, 'install traceback handler' );

my @normal = qw( HUP INT PIPE TERM );
@SIG{@normal} = 1 x @normal;
sigtrap->import('normal-signals');
is( (grep { ref $_ } @SIG{@normal}), @normal, 'check normal-signals set' );

my @error = qw( ABRT BUS EMT FPE ILL QUIT SEGV SYS TRAP );
@SIG{@error} = 1 x @error;
sigtrap->import('error-signals');
is( (grep { ref $_ } @SIG{@error}), @error, 'check error-signals set' );

my @old = qw( ABRT BUS EMT FPE ILL PIPE QUIT SEGV SYS TERM TRAP );
@SIG{@old} = 1 x @old;
sigtrap->import('old-interface-signals');
is( (grep { ref $_ } @SIG{@old}), @old, 'check old-interface-signals set' );

my $handler = sub {};
sigtrap->import(handler => $handler, 'FAKE3');
is( $SIG{FAKE3}, $handler, 'install custom handler' );

$SIG{FAKE} = 'IGNORE';
sigtrap->import('untrapped', 'FAKE');
is( $SIG{FAKE}, 'IGNORE', 'respect existing handler set to IGNORE' );

my $out = tie *STDOUT, 'TieOut';
$SIG{FAKE} = 'DEFAULT';
$sigtrap::Verbose = 1;
sigtrap->import('any', 'FAKE');
is( $SIG{FAKE}, \&sigtrap::handler_traceback, 'should set default handler' );
like( $out->read, qr/^Installing handler/, 'does it talk with $Verbose set?' );

# handler_die croaks with first argument
eval { sigtrap::handler_die('FAKE') };
like( $@, qr/^Caught a SIGFAKE/, 'does handler_die() croak?' );
 
SKIP: {
	skip( 'kill not implemented', 3) unless $can_catch_kill and
		$Config{sig_name} =~ 'ABRT';

	$out = tie *STDERR, 'TieOut';
	my $line = __LINE__ + 1;
	eval { sigtrap::handler_traceback('kudra') };
	is( $@, '', 'handler_traceback() should not die' );
	my $trace = $out->read();
	like( $trace, qr/^Caught a SIGkudra/, 'check traceback message' );
	like( $trace, qr/eval.+sigtrap.t.+$line/, 'check trace in traceback' );
} # end of SKIP

package TieOut;

sub TIEHANDLE {
	bless(\(my $scalar), $_[0]);
}

sub PRINT {
	my $self = shift;
	$$self .= join '', @_;
}

sub WRITE {
	my ($self, $msg, $length) = @_;
	$$self .= $msg;
}

sub read {
	my $self = shift;
	substr($$self, 0, length($$self), '');
}

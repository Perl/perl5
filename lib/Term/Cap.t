#!./perl

BEGIN {
	chdir 't' if -d 't';
	@INC = '../lib';
}

END {
	# let VMS whack all versions
	1 while unlink('tcout');
}

use Test::More tests => 43;

use_ok( 'Term::Cap' );

local (*TCOUT, *OUT);
my $out = tie *OUT, 'TieOut';
my $writable = 1;

if (open(TCOUT, ">tcout")) {
	print TCOUT <DATA>;
	close TCOUT;
} else {
	$writable = 0;
}

# termcap_path -- the names are hardcoded in Term::Cap
$ENV{TERMCAP} = '';
my $path = join '', Term::Cap::termcap_path();
my $files = join '', grep { -f $_ } ( $ENV{HOME} . '/.termcap', '/etc/termcap', 
	'/usr/share/misc/termcap' );
is( $path, $files, 'termcap_path() found default files okay' );

SKIP: {
	# this is ugly, but -f $0 really *ought* to work
	skip("-f $0 fails, some tests difficult now", 2) unless -f $0;

	$ENV{TERMCAP} = $0;
	ok( grep($0, Term::Cap::termcap_path()), 'found file from $ENV{TERMCAP}' );

	$ENV{TERMCAP} = (grep { $^O eq $_ } qw( os2 MSWin32 dos )) ? 'a:/' : '/';
	$ENV{TERMPATH} = $0;
	ok( grep($0, Term::Cap::termcap_path()), 'found file from $ENV{TERMPATH}' );
}


# make a Term::Cap "object"
my $t = {
	PADDING => 1,
	_pc => 'pc',
};
bless($t, 'Term::Cap' );

# see if Tpad() works
is( $t->Tpad(), undef, 'Tpad() is undef with no string' );
is( $t->Tpad('x'), 'x', 'Tpad() returns strings with no match' );
is( $t->Tpad( '1*a', 2 ), 'apcpc', 'Tpad() pads string fine' );

$t->{PADDING} = 2;
is( $t->Tpad( '1*a', 3, *OUT ), 'apcpc', 'Tpad() pad math is okay' );
is( $out->read(), 'apcpc', 'Tpad() writes to filehandle fine' );

is( $t->Tputs('PADDING'), 2, 'Tputs() returns existing value file' );
is( $t->Tputs('pc', 2), 'pc', 'Tputs() delegates to Tpad() fine' );
$t->Tputs('pc', 1, *OUT);
is( $t->{pc}, 'pc', 'Tputs() caches fine when asked' );
is( $out->read(), 'pc', 'Tputs() writes to filehandle fine' );

eval { $t->Trequire( 'pc' ) };
is( $@, '', 'Trequire() finds existing cap fine' );
eval { $t->Trequire( 'nonsense' ) };
like( $@, qr/support: \(nonsense\)/, 'Trequire() croaks with unsupported cap' );

my $warn;
local $SIG{__WARN__} = sub {
	$warn = $_[0];
};

# test the first few features by forcing Tgetent() to croak (line 156)
undef $ENV{TERM};
my $vals = {};
eval { $t = Term::Cap->Tgetent($vals) };
like( $@, qr/TERM not set/, 'Tgetent() croaks without TERM' );
like( $warn, qr/OSPEED was not set/, 'Tgetent() set default OSPEED value' );
is( $vals->{PADDING}, 10000/9600, 'Default OSPEED implies default PADDING' );

# check values for very slow speeds
$vals->{OSPEED} = 1;
$warn = '';
eval { $t = Term::Cap->Tgetent($vals) };
is( $warn, '', 'no warning when passing OSPEED to Tgetent()' );
is( $vals->{PADDING}, 200, 'Tgetent() set slow PADDING when needed' );

# now see if lines 177 or 180 will fail
$ENV{TERM} = 'foo';
$ENV{TERMPATH} = '!';
$ENV{TERMCAP} = '';
eval { $t = Term::Cap->Tgetent($vals) };
isn't( $@, '', 'Tgetent() caught bad termcap file' );

# if there's no valid termcap file found, it should croak
$vals->{TERM} = '';
$ENV{TERMPATH} = $0;
eval { $t = Term::Cap->Tgetent($vals) };
like( $@, qr/failed termcap lookup/, 'Tgetent() dies with bad termcap file' );

SKIP: {
	skip( "Can't write 'tcout' file for tests", 8 ) unless $writable;

	# it shouldn't try to read one file more than 32(!) times
	# see __END__ for a really awful termcap example

	$ENV{TERMPATH} = join(' ', ('tcout') x 33);
	$vals->{TERM} = 'bar';
	eval { $t = Term::Cap->Tgetent($vals) };
	like( $@, qr/failed termcap loop/, 'Tgetent() dies with much recursion' );

	# now let it read a fake termcap file, and see if it sets properties 
	$ENV{TERMPATH} = 'tcout';
	$vals->{TERM} = 'baz';
	$t = Term::Cap->Tgetent($vals);
	is( $t->{_f1}, 1, 'Tgetent() set a single field correctly' );
	is( $t->{_f2}, 1, 'Tgetent() set another field on the same line' );
	is( $t->{_no}, '', 'Tgetent() set a blank field correctly' );
	is( $t->{_k1}, 'v1', 'Tgetent() set a key value pair correctly' );
	like( $t->{_k2}, qr/v2\\\n2/, 'Tgetent() set and translated a pair right' );

	# and it should have set these two fields
	is( $t->{_pc}, "\0", 'set _pc field correctly' );
	is( $t->{_bc}, "\b", 'set _bc field correctly' );
}

# Tgoto has comments on the expected formats
$t->{_test} = "a%d";
is( $t->Tgoto('test', '', 1, *OUT), 'a1', 'Tgoto() works with %d code' );
is( $out->read(), 'a1', 'Tgoto() printed to filehandle fine' );

$t->{_test} = "a%.";
like( $t->Tgoto('test', '', 1), qr/^a\x01/, 'Tgoto() works with %.' );
like( $t->Tgoto('test', '', 0), qr/\x61\x01\x08/, 'Tgoto() %. and magic work' );

$t->{_test} = 'a%+';
like( $t->Tgoto('test', '', 1), qr/a\x01/, 'Tgoto() works with %+' );
$t->{_test} = 'a%+a';
is( $t->Tgoto('test', '', 1), 'ab', 'Tgoto() works with %+ and a character' );
$t->{_test} .= 'a' x 99;
like( $t->Tgoto('test', '', 1), qr/ba{98}/, 'Tgoto() substr()s %+ if needed' );

$t->{_test} = '%ra%d';
is( $t->Tgoto('test', 1, ''), 'a1', 'Tgoto() swaps params with %r set' );

$t->{_test} = 'a%>11bc';
is( $t->Tgoto('test', '', 1), 'abc', 'Tgoto() unpacks with %> set' );

$t->{_test} = 'a%21';
is( $t->Tgoto('test'), 'a001', 'Tgoto() formats with %2 set' );

$t->{_test} = 'a%31';
is( $t->Tgoto('test'), 'a0001', 'Tgoto() also formats with %3 set' );

$t->{_test} = '%ia%21';
is( $t->Tgoto('test', '', 1), 'a021', 'Tgoto() incremented args with %i set ');

$t->{_test} = '%z';
is( $t->Tgoto('test'), 'OOPS', 'Tgoto() handled invalid arg fine' );

# and this is pretty standard
package TieOut;

sub TIEHANDLE {
	bless( \(my $self), $_[0] );
}

sub PRINT {
	my $self = shift;
	$$self .= join('', @_);
}

sub read {
	my $self = shift;
	substr( $$self, 0, length($$self), '' );
}

__END__
bar: :tc=bar: \
baz: \
:f1: :f2: \
:no@ \
:k1#v1\
:k2=v2\\n2

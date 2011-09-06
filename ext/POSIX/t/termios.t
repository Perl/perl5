#!perl -Tw

use strict;
use Config;
use Test::More;

BEGIN {
    plan skip_all => "POSIX is unavailable"
	if $Config{extensions} !~ m!\bPOSIX\b!;
}

use POSIX ':termios_h';

plan skip_all => $@
    if !eval "POSIX::Termios->new; 1" && $@ =~ /termios not implemented/;


# A termios struct that we've successfully read from a terminal device:
my $termios;

foreach (undef, qw(STDIN STDOUT STDERR)) {
 SKIP:
    {
	my ($name, $handle);
	if (defined $_) {
	    $name = $_;
	    $handle = $::{$name};
	} else {
	    $name = POSIX::ctermid();
	    skip("Can't get name of controlling terminal", 4)
		unless defined $name;
	    open $handle, '<', $name or skip("can't open $name: $!", 4);
	}

	skip("$name not a tty", 4) unless -t $handle;

	my $t = eval { POSIX::Termios->new };
	is($@, '', "calling POSIX::Termios->new");
	isa_ok($t, "POSIX::Termios", "checking the type of the object");

	my $fileno = fileno $handle;
	my $r = eval { $t->getattr($fileno) };
	is($@, '', "calling getattr($fileno) for $name");
	if(isnt($r, undef, "returned value ($r) is defined")) {
	    $termios = $t;
	}
    }
}

if (defined $termios) {
    # testing getcc()
    for my $i (0 .. NCCS-1) {
	my $r = eval { $termios->getcc($i) };
	is($@, '', "calling getcc($i)");
	like($r, qr/\A-?[0-9]+\z/, 'returns an integer');
    }

    for my $method (qw(getcflag getiflag getispeed getlflag getoflag getospeed)) {
	my $r = eval { $termios->$method() };
	is($@, '', "calling $method()");
	like($r, qr/\A-?[0-9]+\z/, 'returns an integer');
    }
}

done_testing();

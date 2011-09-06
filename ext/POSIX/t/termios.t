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


# create a new object
my $termios = eval { POSIX::Termios->new };
is( $@, '', "calling POSIX::Termios->new" );
isa_ok( $termios, "POSIX::Termios", "\tchecking the type of the object" );

# testing getattr()
foreach my $name (qw(STDIN STDOUT STDERR)) {
    my $handle = $::{$name};
 SKIP: {
	skip("$name not a tty", 2) unless -t $handle;
	my $fileno = fileno $handle;
	my $r = eval { $termios->getattr($fileno) };
	is($@, '', "calling getattr($fileno) for $name");
	isnt($r, undef, "returned value ($r) is defined");
    }
}

# testing getcc()
for my $i (0..NCCS-1) {
    my $r = eval { $termios->getcc($i) };
    is( $@, '', "calling getcc($i)" );
    like($r, qr/\A-?[0-9]+\z/, 'returns an integer');
}

for my $method (qw(getcflag getiflag getispeed getlflag getoflag getospeed)) {
    my $r = eval { $termios->$method() };
    is( $@, '', "calling $method()" );
    like($r, qr/\A-?[0-9]+\z/, 'returns an integer');
}

done_testing();

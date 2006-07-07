#!perl -T

BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't';
        @INC = '../lib';
    }

    use Config;
    use Test::More;
    plan skip_all => "POSIX is unavailable" if $Config{'extensions'} !~ m!\bPOSIX\b!;
}

use strict;
use POSIX;

my @getters = qw(getcflag getiflag getispeed getlflag getoflag getospeed);

plan tests => 3 + 2 * (3 + NCCS() + @getters);

my $r;

# create a new object
my $termios = eval { POSIX::Termios->new };
is( $@, '', "calling POSIX::Termios->new" );
ok( defined $termios, "\tchecking if the object is defined" );
isa_ok( $termios, "POSIX::Termios", "\tchecking the type of the object" );

# testing getattr()
for my $i (0..2) {
    $r = eval { $termios->getattr($i) };
    is( $@, '', "calling getattr($i)" );
    ok( defined $r, "\tchecking if the returned value is defined: $r" );
}

# testing getcc()
for my $i (0..NCCS()-1) {
    $r = eval { $termios->getcc($i) };
    is( $@, '', "calling getcc($i)" );
    ok( defined $r, "\tchecking if the returned value is defined: $r" );
}

# testing getcflag()
for my $method (@getters) {
    $r = eval { $termios->$method() };
    is( $@, '', "calling $method()" );
    ok( defined $r, "\tchecking if the returned value is defined: $r" );
}


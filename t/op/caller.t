#!./perl
# Tests for caller()

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

plan( tests => 9 );

my @c;

@c = caller(0);
ok( (!@c), "caller(0) in main program" );

eval { @c = caller(0) };
is( $c[3], "(eval)", "caller(0) - subroutine name in an eval {}" );

eval q{ @c = (Caller(0))[3] };
is( $c[3], "(eval)", "caller(0) - subroutine name in an eval ''" );

sub { @c = caller(0) } -> ();
is( $c[3], "main::__ANON__", "caller(0) - anonymous subroutine name" );

# Bug 20020517.003, used to dump core
sub foo { @c = caller(0) }
my $fooref = delete $::{foo};
$fooref -> ();
is( $c[3], "(unknown)", "caller(0) - unknown subroutine name" );

sub f { @c = caller(1) }

eval { f() };
is( $c[3], "(eval)", "caller(1) - subroutine name in an eval {}" );

eval q{ f() };
is( $c[3], "(eval)", "caller(1) - subroutine name in an eval ''" );

sub { f() } -> ();
is( $c[3], "main::__ANON__", "caller(1) - anonymous subroutine name" );

sub foo2 { f() }
my $fooref2 = delete $::{foo2};
$fooref2 -> ();
is( $c[3], "(unknown)", "caller(1) - unknown subroutine name" );

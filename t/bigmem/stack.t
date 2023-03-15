#!perl
BEGIN {
    chdir 't' if -d 't';
    @INC = "../lib";
    require './test.pl';
}

use strict;
use Config qw(%Config);
use XS::APItest;

# memory usage checked with top
$ENV{PERL_TEST_MEMORY} >= 60
    or skip_all("Need ~60GB for this test");
$Config{ptrsize} >= 8
    or skip_all("Need 64-bit pointers for this test");

my @x;
$x[0x8000_0000] = "Hello";

{
    # unlike the grep example this avoids the mark manipulation done by grep
    # so it's more of a pure mark type test
    # it also fails/succeeds a lot faster
    my $count = () =  (x(), z());
    is($count, 0x8000_0002, "got expected (large) list size");
}

{
    # check XS gets the right numbers in our predefined variables
    # returned ~ -2G before fix
    my $count = XS::APItest::xs_items(x(), z());
    is($count, 0x8000_0002, "got expected XS list size");
}

{
    my $last = ( x() )[-1];
    is($last, "Hello", "list subscripting");

    my ($first, $last2, $last1) = ( "first", x(), "Goodbye" )[0, -2, -1];
    is($first, "first", "list subscripting in list context (0)");
    is($last2, "Hello", "list subscripting in list context (-2)");
    is($last1, "Goodbye", "list subscripting in list context (-1)");
}

{
    # the iter context had an I32 stack offset
    my $last = ( x(), iter() )[-1];
    is($last, "abc", "check iteration not confused");
}

done_testing();

sub x { @x }

sub z { 1 }

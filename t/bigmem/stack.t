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

done_testing();

sub x { @x }

sub z { 1 }

#!perl
BEGIN {
    chdir 't';
    unshift @INC, "../lib";
    require './test.pl';
}

use Config qw(%Config);

$ENV{PERL_TEST_MEMORY} >= 2
    or skip_all("Need ~2Gb for this test");
$Config{ptrsize} >= 8
    or skip_all("Need 64-bit pointers for this test");

plan(2);

# [perl #116907]
# ${\2} to defeat constant folding, which in this case actually slows
# things down
my $x=" "x(${\2}**31);
ok $x =~ /./, 'match against long string succeeded';
is "$-[0]-$+[0]", '0-1', '@-/@+ after match against long string';

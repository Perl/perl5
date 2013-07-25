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

plan(3);

# [perl #116907]
# ${\2} to defeat constant folding, which in this case actually slows
# things down
my $x=" "x(${\2}**31) . "abcdefg";
ok $x =~ /./, 'match against long string succeeded';
is "$-[0]-$+[0]", '0-1', '@-/@+ after match against long string';

pos $x = 2**31-1;
my $result;
for(1..5) {
    $x =~ /./g;
    $result .= "$&-";
}
is $result," -a-b-c-d-", 'scalar //g hopping past the 2**31 threshold';

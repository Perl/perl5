#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require Config;
    if (($Config::Config{'extensions'} !~ /\bre\b/) ){
	print "1..0 # Skip -- Perl configured without re module\n";
	exit 0;
    }
}

use strict;
require "./test.pl";

chomp(my @strs=grep { !/^\s*\#/ } <DATA>);
my $out = runperl(progfile => "../ext/re/t/regop.pl", stderr => 1);
my @tests = grep { /\S/ && !/EXECUTING/ } split /(?=Compiling REx)/,$out;

plan(2 + (@strs - grep { !$_ or /^---/ } @strs) + @tests);

my $numtests=4;
is(scalar @tests, $numtests, "Expecting output for $numtests patterns");
ok(defined $out,'regop.pl');
$out||="";
my $test=1;
foreach my $testout (@tests) {
    my ($pattern)=$testout=~/Compiling REx "([^"]+)"/;
    ok($pattern, "Pattern found for test ".($test++));
    while (@strs) {
        my $str=shift @strs;
        last if !$str or $str=~/^---/;
        next if $str=~/^\s*#/;
        ok($testout=~/\Q$str\E/,"$str: /$pattern/");
    }
}

__END__
#Compiling REx "X(A|[B]Q||C|D)Y"
#size 34
#first at 1
#   1: EXACT <X>(3)
#   3: OPEN1(5)
#   5:   TRIE-EXACT(21)
#        [Words:5 Chars:5 Unique:5 States:6 Start-Class:A-D]
#          <A>
#          <BQ>
#          <>
#          <C>
#          <D>
#  21: CLOSE1(23)
#  23: EXACT <Y>(25)
#  25: END(0)
#anchored "X" at 0 floating "Y" at 1..3 (checking floating) minlen 2
#Guessing start of match, REx "X(A|[B]Q||C|D)Y" against "XY"...
#Found floating substr "Y" at offset 1...
#Found anchored substr "X" at offset 0...
#Guessed: match at offset 0
#Matching REx "X(A|[B]Q||C|D)Y" against "XY"
#  Setting an EVAL scope, savestack=140
#   0 <> <XY>              |  1:  EXACT <X>
#   1 <X> <Y>              |  3:  OPEN1
#   1 <X> <Y>              |  5:  TRIE-EXACT
#                                 matched empty string...
#   1 <X> <Y>              | 21:  CLOSE1
#   1 <X> <Y>              | 23:  EXACT <Y>
#   2 <XY> <>              | 25:  END
#Match successful!
#%MATCHED%
#Freeing REx: "X(A|[B]Q||C|D)Y"
Compiling REx "X(A|[B]Q||C|D)Y"
Start-Class:A-D]
TRIE-EXACT
<BQ>
matched empty string
Match successful!
Found floating substr "Y" at offset 1...
Found anchored substr "X" at offset 0...
Guessed: match at offset 0
checking floating
minlen 2
Words:5
Unique:5
States:6
%MATCHED%
---
#Compiling REx "[f][o][o][b][a][r]"
#size 67
#first at 1
#   1: EXACT <foobar>(13)
#  13: END(0)
#anchored "foobar" at 0 (checking anchored isall) minlen 6
#Guessing start of match, REx "[f][o][o][b][a][r]" against "foobar"...
#Found anchored substr "foobar" at offset 0...
#Guessed: match at offset 0
#Freeing REx: "[f][o][o][b][a][r]"
foobar
checking anchored isall
minlen 6
anchored "foobar" at 0
Guessed: match at offset 0
Compiling REx "[f][o][o][b][a][r]"
Freeing REx: "[f][o][o][b][a][r]"
%MATCHED%
---
#Compiling REx ".[XY]."
#size 14
#first at 1
#   1: REG_ANY(2)
#   2: ANYOF[XY](13)
#  13: REG_ANY(14)
#  14: END(0)
#minlen 3
#%FAILED%
#Freeing REx: ".[XY]."
%FAILED%
minlen 3
---
#Compiling REx "(?:ABCP|ABCG|ABCE|ABCB|ABCA|ABCD)"
#size 20 nodes
#   1: EXACT <ABC>(3)
#   3: TRIE-EXACT(20)
#      [Start:4 Words:6 Chars:24 Unique:7 States:10 Minlen:1 Maxlen:1 Start-Class:A-EGP]
#        <ABCP>
#        <ABCG>
#        <ABCE>
#        <ABCB>
#        <ABCA>
#        <ABCD>
#  19: TAIL(20)
#  20: END(0)
#minlen 4
#Matching REx "(?:ABCP|ABCG|ABCE|ABCB|ABCA|ABCD)" against "ABCD"
#  Setting an EVAL scope, savestack=140
#   0 <> <ABCD>            |  1:  EXACT <ABC>
#   3 <ABC> <D>            |  3:  TRIE-EXACT
#                                 only one match : #6 <ABCD>
#   4 <ABCD> <>            | 20:    END
#Match successful!
#POP STATE(1)
#%MATCHED%
#Freeing REx: "(?:ABCP|ABCG|ABCE|ABCB|ABCA|ABCD)"
%MATCHED%
EXACT <ABC>
Start-Class:A-EGP
only one match : #6 <ABCD>
Start:4
minlen 4

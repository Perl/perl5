#!/usr/bin/perl

use strict;
use warnings;

# Test binmode option and verify reading data from UTF-8 files

use Tie::File;

use utf8; # this script file is UTF-8
# unicode characters in test descriptions may garble to the terminal
# unless encoded.
use Encode qw(decode encode); 
binmode( STDOUT, ':encoding(UTF-8)');

use Test::More tests => 3;

diag( 'Test binmode option and verify reading data from UTF-8 files');

my @data = (<DATA>);
open( my $tmpary, '>:encoding(UTF-8)', '44array.txt')
  or die "test unable to open data file $!\n";
for (@data) { print $tmpary $_ }
close $tmpary;

my $tie_obj = tie my @array, 'Tie::File', '44array.txt', 'binmode' => ':encoding(UTF-8)';
print "$array[1]\n";
$array[1] =~ /\/(Bront\N{LATIN SMALL LETTER E WITH DIAERESIS})\//;
is( $1, "Bront\N{LATIN SMALL LETTER E WITH DIAERESIS}",
  encode ( 'UTF-8', "Bront\N{LATIN SMALL LETTER E WITH DIAERESIS} accent character matches codepoint"));
$array[6] =~ /(ç)/;
is( ord($1), 231, 'also use ord to confirm the value of a character in a string -- Latin Small Letter C With Cedilla as 231');

subtest 'compare every line of tied file to the origina data' => sub {
  plan tests => 6;
  for my $j ( 0..5 ) {
    my $d = encode ( 'UTF-8', $data[$j] );
    chomp $d;
    is( encode ( 'UTF-8', $array[$j]), $d, "line $j matches $d");
  }
};

unlink '44array.txt';

__DATA__
1 NAME Anne /Brontë/
1 NAME Charlotte /Brontë/
1 NAME Emily Jane /Brontë/
SmilyFace ☺
Next Line is Cyrillic
привіт, світ, зок на довший, а інший – на коротший амінити рядrontë
En 1815, M. Charles-François-Bienvenu Myriel était évêque de Digne. C'était un vieillard d'environ soixante-quinze ans; il occupait le siège de Digne depuis 1806
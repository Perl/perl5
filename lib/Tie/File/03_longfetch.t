#!/usr/bin/perl
#
# Make sure we can fetch a record in the middle of the file
# before we've ever looked at any records before it
#
# (tests _fill_offsets_to() )
#

my $file = "tf$$.txt";
my $data = "rec0$/rec1$/rec2$/";

print "1..5\n";

my $N = 1;
use Tie::File;
print "ok $N\n"; $N++;

open F, "> $file" or die $!;
print F $data;
close F;


my $o = tie @a, 'Tie::File', $file;
print $o ? "ok $N\n" : "not ok $N\n";
$N++;

my $n;

# 3-5
for (2, 1, 0) {
  print $a[$_] eq "rec$_$/" ? "ok $N\n" : "not ok $N # rec=$a[$_] ?\n";
  $N++;
}

END {
  1 while unlink $file;
}


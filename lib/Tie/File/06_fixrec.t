#!/usr/bin/perl

my $file = "tf$$.txt";

print "1..5\n";

my $N = 1;
use Tie::File;
print "ok $N\n"; $N++;

my $o = tie @a, 'Tie::File', $file;
print $o ? "ok $N\n" : "not ok $N\n";
$N++;

$a[0] = 'rec0';
check_contents("rec0$/");
$a[1] = "rec1$/";
check_contents("rec0$/rec1$/");
$a[2] = "rec2$/$/";             # should we detect this?
check_contents("rec0$/rec1$/rec2$/$/");

sub check_contents {
  my $x = shift;
  local *FH;
  my $open = open FH, "< $file";
  binmode FH;
  my $a;
  { local $/; $a = <FH> }
  print (($open && $a eq $x) ? "ok $N\n" : "not ok $N\n");
  $N++;
}


END {
  1 while unlink $file;
}


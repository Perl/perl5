#!/usr/bin/perl
#
# Check miscellaneous tied-array interface methods
# EXTEND, CLEAR, DELETE, EXISTS
#

my $file = "tf$$.txt";
1 while unlink $file;

print "1..24\n";

my $N = 1;
use Tie::File;
print "ok $N\n"; $N++;

my $o = tie @a, 'Tie::File', $file;
print $o ? "ok $N\n" : "not ok $N\n";
$N++;

# (3-8) EXTEND
$o->EXTEND(3);
check_contents("$/$/$/");
$o->EXTEND(4);
check_contents("$/$/$/$/");
$o->EXTEND(3);
check_contents("$/$/$/$/");

# (9-10) CLEAR
@a = ();
check_contents("");

# (11-16) EXISTS
print !exists $a[0] ? "ok $N\n" : "not ok $N\n";
$N++;
$a[0] = "I like pie.";
print exists $a[0] ? "ok $N\n" : "not ok $N\n";
$N++;
print !exists $a[1] ? "ok $N\n" : "not ok $N\n";
$N++;
$a[2] = "GIVE ME PIE";
print exists $a[0] ? "ok $N\n" : "not ok $N\n";
$N++;
# exists $a[1] is not defined by this module under these circumstances
print exists $a[1] ? "ok $N\n" : "ok $N\n";
$N++;
print exists $a[2] ? "ok $N\n" : "not ok $N\n";
$N++;

# (17-24) DELETE
delete $a[0];
check_contents("$/$/GIVE ME PIE$/");
delete $a[2];
check_contents("$/$/");
delete $a[0];
check_contents("$/$/");
delete $a[1];
check_contents("$/");


use POSIX 'SEEK_SET';
sub check_contents {
  my $x = shift;
  local *FH = $o->{fh};
  seek FH, 0, SEEK_SET;
  my $a;
  { local $/; $a = <FH> }
  $a = "" unless defined $a;
  if ($a eq $x) {
    print "ok $N\n";
  } else {
    s{$/}{\\n}g for $a, $x;
    print "not ok $N\n# expected <$x>, got <$a>\n";
  }
  $N++;
  print $o->_check_integrity($file, $ENV{INTEGRITY}) ? "ok $N\n" : "not ok $N\n";
  $N++;
}

END {
  undef $o;
  untie @a;
  1 while unlink $file;
}



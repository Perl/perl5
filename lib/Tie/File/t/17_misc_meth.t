#!/usr/bin/perl
#
# Check miscellaneous tied-array interface methods
# EXTEND, CLEAR, DELETE, EXISTS
#

my $file = "tf$$.txt";
$: = Tie::File::_default_recsep();
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
check_contents("$:$:$:");
$o->EXTEND(4);
check_contents("$:$:$:$:");
$o->EXTEND(3);
check_contents("$:$:$:$:");

# (9-10) CLEAR
@a = ();
check_contents("");

# (11-16) EXISTS
if ($] >= 5.006) {
  eval << 'TESTS';
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
TESTS
  } else {                      # perl 5.005 doesn't have exists $array[1]
    for (11..16) {
      print "ok $_ \# skipped (no exists for arrays)\n";
          $N++;
    }
  }

# (17-24) DELETE
if ($] >= 5.006) {
  eval << 'TESTS';
delete $a[0];
check_contents("$:$:GIVE ME PIE$:");
delete $a[2];
check_contents("$:$:");
delete $a[0];
check_contents("$:$:");
delete $a[1];
check_contents("$:");
TESTS
  } else {                      # perl 5.005 doesn't have delete $array[1]
    for (17..24) {
      print "ok $_ \# skipped (no delete for arrays)\n";
          $N++;
    }
  }

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
    ctrlfix(my $msg = "# expected <$x>, got <$a>");
    print "not ok $N\n$msg\n";
  }
  $N++;
  print $o->_check_integrity($file, $ENV{INTEGRITY}) ? "ok $N\n" : "not ok $N\n";
  $N++;
}

sub ctrlfix {
  for (@_) {
    s/\n/\\n/g;
    s/\r/\\r/g;
  }
}

END {
  undef $o;
  untie @a;
  1 while unlink $file;
}



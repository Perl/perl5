#!/usr/bin/perl

my $file = "tf$$.txt";

print "1..38\n";

my $N = 1;
use Tie::File;
print "ok $N\n"; $N++;

my $o = tie @a, 'Tie::File', $file, recsep => 'blah';
print $o ? "ok $N\n" : "not ok $N\n";
$N++;


# 3-4 create
$a[0] = 'rec0';
check_contents("rec0");

# 5-8 append
$a[1] = 'rec1';
check_contents("rec0", "rec1");
$a[2] = 'rec2';
check_contents("rec0", "rec1", "rec2");

# 9-14 same-length alterations
$a[0] = 'new0';
check_contents("new0", "rec1", "rec2");
$a[1] = 'new1';
check_contents("new0", "new1", "rec2");
$a[2] = 'new2';
check_contents("new0", "new1", "new2");

# 15-24 lengthening alterations
$a[0] = 'long0';
check_contents("long0", "new1", "new2");
$a[1] = 'long1';
check_contents("long0", "long1", "new2");
$a[2] = 'long2';
check_contents("long0", "long1", "long2");
$a[1] = 'longer1';
check_contents("long0", "longer1", "long2");
$a[0] = 'longer0';
check_contents("longer0", "longer1", "long2");

# 25-34 shortening alterations, including truncation
$a[0] = 'short0';
check_contents("short0", "longer1", "long2");
$a[1] = 'short1';
check_contents("short0", "short1", "long2");
$a[2] = 'short2';
check_contents("short0", "short1", "short2");
$a[1] = 'sh1';
check_contents("short0", "sh1", "short2");
$a[0] = 'sh0';
check_contents("sh0", "sh1", "short2");

# file with holes
$a[4] = 'rec4';
check_contents("sh0", "sh1", "short2", "", "rec4");
$a[3] = 'rec3';
check_contents("sh0", "sh1", "short2", "rec3", "rec4");


# try inserting a record into the middle of an empty file


sub check_contents {
  my @c = @_;
  my $x = join 'blah', @c, '';
  local *FH;
  my $open = open FH, "< $file";
  binmode FH;
  my $a;
  { local $/; $a = <FH> }
  print (($open && $a eq $x) ? "ok $N\n" : "not ok $N # file @c\n");
  $N++;

  # now check FETCH:
  my $good = 1;
  for (0.. $#c) {
    $good = 0 unless $a[$_] eq "$c[$_]blah";
  }
  print (($open && $good) ? "ok $N\n" : "not ok $N # fetch @c\n");
  $N++;
}

END {
  1 while unlink $file;
}


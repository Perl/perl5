#!/usr/bin/perl

my $file = "tf$$.txt";

print "1..47\n";

my $N = 1;
use Tie::File;
print "ok $N\n"; $N++;

$RECSEP = 'blah';
my $o = tie @a, 'Tie::File', $file, 
    recsep => $RECSEP, autochomp => 0, autodefer => 0;
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

# (35-37) zero out file
@a = ();
check_contents();

# (38-40) insert into the middle of an empty file
$a[3] = "rec3";
check_contents("", "", "", "rec3");


# (41-46) 20020326 You thought there would be a bug in STORE where if
# a cached record was false, STORE wouldn't see it at all.  Yup, there is,
# and adding the appropriate defined() test fixes the problem.
undef $o;  untie @a;  1 while unlink $file;
$RECSEP = '0';
$o = tie @a, 'Tie::File', $file, 
    recsep => $RECSEP, autochomp => 0, autodefer => 0;
print $o ? "ok $N\n" : "not ok $N\n";
$N++;
$#a = 2;
my $z = $a[1];                  # caches "0"
$a[2] = "oops";
check_contents("", "", "oops");
$a[1] = "bah";
check_contents("", "bah", "oops");


use POSIX 'SEEK_SET';
sub check_contents {
  my @c = @_;
  my $x = join $RECSEP, @c, '';
  local *FH = $o->{fh};
  seek FH, 0, SEEK_SET;
  my $a;
  { local $/; $a = <FH> }

  $a = "" unless defined $a;
  if ($a eq $x) {
    print "ok $N\n";
  } else {
    my $msg = "# expected <$x>, got <$a>";
    ctrlfix($msg);
    print "not ok $N $msg\n";
  }
  $N++;

  # now check FETCH:
  my $good = 1;
  for (0.. $#c) {
    unless ($a[$_] eq "$c[$_]$RECSEP") {
      $msg = "expected $c[$_]$RECSEP, got $a[$_]";
      ctrlfix($msg);
      $good = 0;
    }
  }
  print $good ? "ok $N\n" : "not ok $N # fetch $msg\n";
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


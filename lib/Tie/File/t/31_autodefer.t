#!/usr/bin/perl
#
# Check behavior of 'autodefer' feature
# Mostly this isn't implemented yet
# This file is primarily here to make sure that the promised ->autodefer
# method doesn't croak.
#

use POSIX 'SEEK_SET';
my $file = "tf$$.txt";
$: = Tie::File::_default_recsep();
my $data = "rec0$:rec1$:rec2$:";
my ($o, $n, @a);

print "1..3\n";

my $N = 1;
use Tie::File;
print "ok $N\n"; $N++;

open F, "> $file" or die $!;
binmode F;
print F $data;
close F;
$o = tie @a, 'Tie::File', $file;
print $o ? "ok $N\n" : "not ok $N\n";
$N++;

# (3) You promised this interface, so it better not die

eval {$o->autodefer(0)};
print $@ ? "not ok $N # $@\n" : "ok $N\n";



sub check_contents {
  my $x = shift;
  my $integrity = $o->_check_integrity($file, $ENV{INTEGRITY});
  local *FH = $o->{fh};
  seek FH, 0, SEEK_SET;
  print $integrity ? "ok $N\n" : "not ok $N\n";
  $N++;
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
}

sub ctrlfix {
  for (@_) {
    s/\n/\\n/g;
    s/\r/\\r/g;
  }
}

END {
  1 while unlink $file;
}


#!/usr/bin/perl
#
# Make sure it works to open the file in read-only mode
#

my $file = "tf$$.txt";

print "1..9\n";

my $N = 1;
use Tie::File;
use Fcntl 'O_RDONLY';
print "ok $N\n"; $N++;

my @items = qw(Gold Frankincense Myrrh Ivory Apes Peacocks);
init_file(join $/, @items, '');

my $o = tie @a, 'Tie::File', $file, mode => O_RDONLY;
print $o ? "ok $N\n" : "not ok $N\n";
$N++;

$#a == $#items ? print "ok $N\n" : print "not ok $N\n";
$N++;

for my $i (0..$#items) {
  ("$items[$i]$/" eq $a[$i]) ? print "ok $N\n" : print "not ok $N\n";
  $N++;
}

sub init_file {
  my $data = shift;
  open F, "> $file" or die $!;
  print F $data;
  close F;
}


END {
  1 while unlink $file;
}


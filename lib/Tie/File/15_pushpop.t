#!/usr/bin/perl
#
# Check PUSH, POP, SHIF, and UNSHIFT 
#
# Each call to 'check_contents' actually performs two tests.
# First, it calls the tied object's own 'check_integrity' method,
# which makes sure that the contents of the read cache and offset tables
# accurately reflect the contents of the file.  
# Then, it checks the actual contents of the file against the expected
# contents.

use lib '/home/mjd/src/perl/Tie-File2/lib';
my $file = "tf$$.txt";
1 while unlink $file;
my $data = "rec0$/rec1$/rec2$/";

print "1..38\n";

my $N = 1;
use Tie::File;
print "ok $N\n"; $N++;  # partial credit just for showing up

my $o = tie @a, 'Tie::File', $file;
print $o ? "ok $N\n" : "not ok $N\n";
$N++;
my ($n, @r);



# (3-11) PUSH tests
$n = push @a, "rec0", "rec1", "rec2";
check_contents($data);
print $n == 3 ? "ok $N\n" : "not ok $N # size is $n, should be 3\n";
$N++;

$n = push @a, "rec3", "rec4\n";
check_contents("$ {data}rec3$/rec4$/");
print $n == 5 ? "ok $N\n" : "not ok $N # size is $n, should be 5\n";
$N++;

# Trivial push
$n = push @a;
check_contents("$ {data}rec3$/rec4$/");
print $n == 5 ? "ok $N\n" : "not ok $N # size is $n, should be 5\n";
$N++;

# (12-20) POP tests
$n = pop @a;
check_contents("$ {data}rec3$/");
print $n eq "rec4$/" ? "ok $N\n" : "not ok $N # last rec is $n, should be rec4\n";
$N++;

# Presumably we have already tested this to death
splice(@a, 1, 3);
$n = pop @a;
check_contents("");
print $n eq "rec0$/" ? "ok $N\n" : "not ok $N # last rec is $n, should be rec0\n";
$N++;

$n = pop @a;
check_contents("");
print ! defined $n ? "ok $N\n" : "not ok $N # last rec should be undef, is $n\n";
$N++;


# (21-29) UNSHIFT tests
$n = unshift @a, "rec0", "rec1", "rec2";
check_contents($data);
print $n == 3 ? "ok $N\n" : "not ok $N # size is $n, should be 3\n";
$N++;

$n = unshift @a, "rec3", "rec4\n";
check_contents("rec3$/rec4$/$data");
print $n == 5 ? "ok $N\n" : "not ok $N # size is $n, should be 5\n";
$N++;

# Trivial unshift
$n = unshift @a;
check_contents("rec3$/rec4$/$data");
print $n == 5 ? "ok $N\n" : "not ok $N # size is $n, should be 5\n";
$N++;

# (30-38) SHIFT tests
$n = shift @a;
check_contents("rec4$/$data");
print $n eq "rec3$/" ? "ok $N\n" : "not ok $N # last rec is $n, should be rec3\n";
$N++;

# Presumably we have already tested this to death
splice(@a, 1, 3);
$n = shift @a;
check_contents("");
print $n eq "rec4$/" ? "ok $N\n" : "not ok $N # last rec is $n, should be rec4\n";
$N++;

$n = shift @a;
check_contents("");
print ! defined $n ? "ok $N\n" : "not ok $N # last rec should be undef, is $n\n";
$N++;


sub init_file {
  my $data = shift;
  open F, "> $file" or die $!;
  binmode F;
  print F $data;
  close F;
}

sub check_contents {
  my $x = shift;
  local *FH;
  my $integrity = $o->_check_integrity($file, $ENV{INTEGRITY});
  print $integrity ? "ok $N\n" : "not ok $N\n";
  $N++;
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


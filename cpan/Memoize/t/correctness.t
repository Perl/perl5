#!/usr/bin/perl

use lib '..';
use Memoize;

print "1..25\n";

print "# Basic\n";

# A function that should only be called once.
my $FAIL = 0;
{ my $COUNT = 0;
  sub no_args {	
    $FAIL++ if $COUNT++;
    11;
  }
}

# 
memoize('no_args');

my $c1 = &no_args();
print (($c1 == 11) ? "ok 1\n" : "not ok 1\n");
my $c2 = &no_args();
print (($c2 == 11) ? "ok 2\n" : "not ok 2\n");
print $FAIL ? "not ok 3\n" : "ok 3\n";	# Was it really memoized?

my $FAIL = 0;
my $f = do { my $COUNT = 0; sub { $FAIL++ if $COUNT++; 12 } };
my $fm = memoize($f);

$c1 = &$fm();
print (($c1 == 12) ? "ok 4\n" : "not ok 4\n");
$c2 = &$fm();
print (($c2 == 12) ? "ok 5\n" : "not ok 5\n");
print $FAIL ? "not ok 6\n" : "ok 6\n";	# Was it really memoized?

$f = do { my $COUNT = 0; sub { $FAIL++ if $COUNT++; 13 } };
$fm = memoize($f, INSTALL => 'another');

$c1 = &another();  # Was it really installed?
print (($c1 == 13) ? "ok 7\n" : "not ok 7\n");
$c2 = &another();  
print (($c2 == 13) ? "ok 8\n" : "not ok 8\n");
print $FAIL ? "not ok 9\n" : "ok 9\n";	# Was it really memoized?
my $c3 = &$fm();			# Call memoized version through returned ref
print (($c3 == 13) ? "ok 10\n" : "not ok 10\n");
print $FAIL ? "not ok 11\n" : "ok 11\n";	# Was it really memoized?
my $c4 = &$f();			# Call original version again
print (($c4 == 13) ? "ok 12\n" : "not ok 12\n");
print $FAIL ? "ok 13\n" : "not ok 13\n";	# Did we get the original?

print "# Fibonacci\n";

sub mt1 {			# Fibonacci
  my $n = shift;
  return $n if $n < 2;
  mt1($n-1) + mt2($n-2);
}
sub mt2 {		
  my $n = shift;
  return $n if $n < 2;
  mt1($n-1) + mt2($n-2);
}

my @f1 = map { mt1($_) } (0 .. 15);
my @f2 = map { mt2($_) } (0 .. 15);
memoize('mt1');
my @f3 = map { mt1($_) } (0 .. 15);
my @f4 = map { mt1($_) } (0 .. 15);
my @arrays = (\@f1, \@f2, \@f3, \@f4); 
my $n = 13;
for (my $i=0; $i<3; $i++) {
  for (my $j=$i+1; $j<3; $j++) {
    $n++;
    print ((@{$arrays[$i]} == @{$arrays[$j]}) ? "ok $n\n" : "not ok $n\n");
    $n++;
    for (my $k=0; $k < @{$arrays[$i]}; $k++) {
      (print "not ok $n\n", next)  if $arrays[$i][$k] != $arrays[$j][$k];
    }
    print "ok $n\n";
  }
}



print "# Normalizers\n";

sub fake_normalize {
  return '';
}

sub f1 {
  return shift;
}
sub f2 {
  return shift;
}
sub f3 {
  return shift;
}
&memoize('f1');
&memoize('f2', NORMALIZER => 'fake_normalize');
&memoize('f3', NORMALIZER => \&fake_normalize);
my @f1r = map { f1($_) } (1 .. 10);
my @f2r = map { f2($_) } (1 .. 10);
my @f3r = map { f3($_) } (1 .. 10);
$n++;
print (("@f1r" eq "1 2 3 4 5 6 7 8 9 10") ? "ok $n\n" : "not ok $n\n");
$n++;
print (("@f2r" eq "1 1 1 1 1 1 1 1 1 1") ? "ok $n\n" : "not ok $n\n");
$n++;
print (("@f3r" eq "1 1 1 1 1 1 1 1 1 1") ? "ok $n\n" : "not ok $n\n");

print "# INSTALL => undef option.\n";
{ my $i = 1;
  sub u1 { $i++ }
}
my $um = memoize('u1', INSTALL => undef);
my @umr = (&$um, &$um, &$um);
my @u1r = (&u1,  &u1,  &u1 );	# Did *not* clobber &u1
$n++;
print (("@umr" eq "1 1 1") ? "ok $n\n" : "not ok $n\n"); # Increment once
$n++;
print (("@u1r" eq "2 3 4") ? "ok $n\n" : "not ok $n\n"); # Increment thrice
$n++;
print ((defined &{"undef"}) ? "not ok $n\n" : "ok $n\n"); # Just in case

print "# $n tests in all.\n";


#!/usr/bin/perl

use lib '..';
use Memoize;

if (-e '.fast') {
  print "1..0\n";
  exit 0;
}

print  "# Warning: I'm testing the speedup.  This might take up to sixty seconds.\n";

print "1..6\n";

sub fib {
  my $n = shift;
  $COUNT++;
  return $n if $n < 2;
  fib($n-1) + fib($n-2);
}

$N = 0;

$ELAPSED = 0;
until ($ELAPSED > 10) {
  $N++;
  my $start = time;
  $COUNT=0;
  $RESULT = fib($N);
  $ELAPSED = time - $start;
  print "# fib($N) took $ELAPSED seconds.\n" if $N % 1 == 0;
}

print "# OK, fib($N) was slow enough; it took $ELAPSED seconds.\n";


&memoize('fib');

$COUNT=0;
$start = time;
$RESULT2 = fib($N);
$ELAPSED2 = time - $start + .001; # prevent division by 0 errors

print (($RESULT == $RESULT2) ? "ok 1\n" : "not ok 1\n");
# If it's not ten times as fast, something is seriously wrong.
print (($ELAPSED/$ELAPSED2 > 10) ? "ok 2\n" : "not ok 2\n");
# If it called the function more than $N times, it wasn't memoized properly
print (($COUNT > $N) ? "ok 3\n" : "not ok 3\n");

# Do it again. Should be even faster this time.
$start = time;
$RESULT2 = fib($N);
$ELAPSED2 = time - $start + .001; # prevent division by 0 errors


print (($RESULT == $RESULT2) ? "ok 4\n" : "not ok 4\n");
print (($ELAPSED/$ELAPSED2 > 10) ? "ok 5\n" : "not ok 5\n");
# This time it shouldn't have called the function at all.
print ($COUNT ? "ok 6\n" : "not ok 6\n");

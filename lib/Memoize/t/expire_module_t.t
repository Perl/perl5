#!/usr/bin/perl

use lib '..';
use Memoize;

my $n = 0;

if (-e '.fast') {
  print "1..0\n";
  exit 0;
}

print "# Warning: I'm testing the timed expiration policy.\nThis will take about thirty seconds.\n";

print "1..14\n";

++$n; print "ok $n\n";

sub close_enough {
#  print "Close enough? @_[0,1]\n";
  abs($_[0] - $_[1]) <= 1;
}

sub now {
#  print "NOW: @_ ", time(), "\n";
  time;
}

memoize 'now',
    SCALAR_CACHE => ['TIE', 'Memoize::Expire', LIFETIME => 15],
    LIST_CACHE => 'FAULT'
    ;

++$n; print "ok $n\n";


# T
for (1,2,3) {
  $when{$_} = now($_);
  ++$n;
  print "not " unless $when{$_} == time;
  print "ok $n\n";
  sleep 5 if $_ < 3;
}

# T+10
for (1,2,3) {
  $again{$_} = now($_); # Should be the sameas before, because of memoization
}

# T+10
foreach (1,2,3) {
  ++$n;
  print "not " unless $when{$_} == $again{$_};
  print "ok $n\n";
}

sleep 6;  # now(1) expires

# T+16 
print "not " unless close_enough(time, $again{1} = now(1));
++$n; print "ok $n\n";

# T+16 
foreach (2,3) {			# Have not expired yet.
  ++$n;
  print "not " unless now($_) == $again{$_};
  print "ok $n\n";
}

sleep 6;  # now(2) expires

# T+22
print "not " unless close_enough(time, $again{2} = now(2));
++$n; print "ok $n\n";

# T+22
foreach (1,3) {
  ++$n;
  print "not " unless now($_) == $again{$_};
  print "ok $n\n";
}



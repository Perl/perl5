#!/usr/bin/perl

use lib '..';
use Memoize;
use Config;

print "1..11\n";

eval { memoize({}) };
print $@ ? "ok 1\n" : "not ok 1 # $@\n";

eval { memoize([]) };
print $@ ? "ok 2\n" : "not ok 2 # $@\n";

eval { my $x; memoize(\$x) };
print $@ ? "ok 3\n" : "not ok 3 # $@\n";

# 4--8
$n = 4;
for $mod (qw(DB_File GDBM_File SDBM_File ODBM_File NDBM_File)) {
  eval { memoize(sub {}, LIST_CACHE => ['TIE', $mod]) };
  print $@ ? "ok $n\n" : "not ok $n # $@\n";
  $n++;
}

# 9
eval { memoize(sub {}, LIST_CACHE => ['TIE', WuggaWugga]) };
print $@ ? "ok 9\n" : "not ok 9 # $@\n";

# 10
eval { memoize(sub {}, LIST_CACHE => 'YOB GORGLE') };
print $@ ? "ok 10\n" : "not ok 10 # $@\n";

# 11
eval { memoize(sub {}, SCALAR_CACHE => ['YOB GORGLE']) };
print $@ ? "ok 11\n" : "not ok 11 # $@\n";


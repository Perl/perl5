#!/usr/bin/perl

print "1..1\n";

use Tie::File;

if ($Tie::File::VERSION != 0.20) {
  print STDERR "
WHOA THERE!!

You seem to be running version $Tie::File::VERSION of the module against
version 0.20 of the test suite!

None of the other test results will be reliable.
";
  exit 1;
}

print "ok 1\n";

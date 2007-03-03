#!/usr/bin/perl -w

# Test for memory leaks from _zero() and friends.

use Test::More;
use strict;

BEGIN
  {
  $| = 1;
  chdir 't' if -d 't';
  unshift @INC, ('../lib', '../blib/arch');	# for running manually
  plan tests => 4;
  }

#############################################################################
package Math::BigInt::FastCalc::LeakCheck;
use base qw(Math::BigInt::FastCalc);

my $destroyed = 0;
sub DESTROY { $destroyed++ }

#############################################################################
package main;

for my $method (qw(_zero _one _two _ten))
  {
  $destroyed = 0;
    {
    my $num = Math::BigInt::FastCalc::LeakCheck->$method();
    bless $num, "Math::BigInt::FastCalc::LeakCheck";
    }
  is ($destroyed, 1, "$method does not leak memory");
  }

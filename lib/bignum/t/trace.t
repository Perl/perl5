#!/usr/bin/perl -w

###############################################################################

use Test;
use strict;

BEGIN
  {
  $| = 1;
  chdir 't' if -d 't';
  unshift @INC, '../lib';
  plan tests => 1;
  }

BEGIN
  {
  print "# ";					# for testsuite
  }
use bignum qw/ trace /;

###############################################################################
# general tests

my $x = 5; 
print "\n";
ok (ref($x),'Math::BigInt::Trace');		# :constant via trace

###############################################################################
###############################################################################
# Perl 5.005 does not like ok ($x,undef)

sub ok_undef
  {
  my $x = shift;

  ok (1,1) and return if !defined $x;
  ok ($x,'undef');
  }

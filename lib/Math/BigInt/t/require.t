#!/usr/bin/perl -w

use strict;
use Test;

BEGIN
  {
  $| = 1;
  chdir 't' if -d 't';
  unshift @INC, '../lib'; # for running manually
  plan tests => 1;
  } 

my ($try,$ans,$x);

require Math::BigInt; $x = Math::BigInt->new(1); ++$x;

#$try = 'require Math::BigInt; $x = Math::BigInt->new(1); ++$x;';
#$ans = eval $try || 'undef';
#print "# For '$try'\n" if (!ok "$ans" , '2' ); 

ok ($x||'undef',2);

# all tests done

1;


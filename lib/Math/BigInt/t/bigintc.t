#!/usr/bin/perl -w

use strict;
use Test;

BEGIN 
  {
  $| = 1;
  # chdir 't' if -d 't';
  unshift @INC, '../lib'; # for running manually
  plan tests => 29;
  }

# testing of Math::BigInt::Calc, primarily for interface/api and not for the
# math functionality

use Math::BigInt::Calc;

my $s123 = \'123'; my $s321 = \'321';
# _new and _str
my $x = _new($s123); my $u = _str($x);
ok ($$u,123); ok ($x->[0],123); ok (@$x,1);
my $y = _new($s321);

# _add, _sub, _mul, _div

ok (${_str(_add($x,$y))},444);
ok (${_str(_sub($x,$y))},123);
ok (${_str(_mul($x,$y))},39483);
ok (${_str(_div($x,$y))},123);

# division with reminder
my $z = _new(\"111");
 _mul($x,$y);
ok (${_str($x)},39483);
_add($x,$z);
ok (${_str($x)},39594);
my ($re,$rr) = _div($x,$y);

ok (${_str($re)},123); ok (${_str($rr)},111);

# _copy
$x = _new(\"12356");
ok (${_str(_copy($x))},12356);

# digit
$x = _new(\"123456789");
ok (_digit($x,0),9);
ok (_digit($x,1),8);
ok (_digit($x,2),7);
ok (_digit($x,-1),1);
ok (_digit($x,-2),2);
ok (_digit($x,-3),3);

# is_zero, _is_one, _one, _zero
$x = _new(\"12356");
ok (_is_zero($x),0);
ok (_is_one($x),0);

# _zeros
$x = _new(\"1256000000"); ok (_zeros($x),6);
$x = _new(\"152"); ok (_zeros($x),0);
$x = _new(\"123000"); ok (_zeros($x),3);

ok (_is_one(_one()),1); ok (_is_one(_zero()),0);
ok (_is_zero(_zero()),1); ok (_is_zero(_one()),0);

ok (_check($x),0);
ok (_check(123),'123 is not a reference');

# done

1;

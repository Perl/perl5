#!/usr/bin/perl -w

use strict;
use Test;

BEGIN 
  {
  $| = 1;
  # chdir 't' if -d 't';
  unshift @INC, '../lib'; # for running manually
  plan tests => 52;
  }

# testing of Math::BigInt::BitVect, primarily for interface/api and not for the
# math functionality

use Math::BigInt::Calc;

my $C = 'Math::BigInt::Calc';	# pass classname to sub's

# _new and _str
my $x = $C->_new(\"123"); my $y = $C->_new(\"321");
ok (ref($x),'ARRAY'); ok (${$C->_str($x)},123); ok (${$C->_str($y)},321);

# _add, _sub, _mul, _div

ok (${$C->_str($C->_add($x,$y))},444);
ok (${$C->_str($C->_sub($x,$y))},123);
ok (${$C->_str($C->_mul($x,$y))},39483);
ok (${$C->_str($C->_div($x,$y))},123);

ok (${$C->_str($C->_mul($x,$y))},39483);
ok (${$C->_str($x)},39483);
ok (${$C->_str($y)},321);
my $z = $C->_new(\"2");
ok (${$C->_str($C->_add($x,$z))},39485);
my ($re,$rr) = $C->_div($x,$y);

ok (${$C->_str($re)},123); ok (${$C->_str($rr)},2);

# is_zero, _is_one, _one, _zero
ok ($C->_is_zero($x),0);
ok ($C->_is_one($x),0);

ok ($C->_is_one($C->_one()),1); ok ($C->_is_one($C->_zero()),0);
ok ($C->_is_zero($C->_zero()),1); ok ($C->_is_zero($C->_one()),0);

# is_odd, is_even
ok ($C->_is_odd($C->_one()),1); ok ($C->_is_odd($C->_zero()),0);
ok ($C->_is_even($C->_one()),0); ok ($C->_is_even($C->_zero()),1);

# _digit
$x = $C->_new(\"123456789");
ok ($C->_digit($x,0),9);
ok ($C->_digit($x,1),8);
ok ($C->_digit($x,2),7);
ok ($C->_digit($x,-1),1);
ok ($C->_digit($x,-2),2);
ok ($C->_digit($x,-3),3);

# _copy
$x = $C->_new(\"12356");
ok (${$C->_str($C->_copy($x))},12356);

# _zeros
$x = $C->_new(\"1256000000"); ok ($C->_zeros($x),6);
$x = $C->_new(\"152"); ok ($C->_zeros($x),0);
$x = $C->_new(\"123000"); ok ($C->_zeros($x),3); 

# _lsft, _rsft
$x = $C->_new(\"10"); $y = $C->_new(\"3"); 
ok (${$C->_str($C->_lsft($x,$y,10))},10000);
$x = $C->_new(\"20"); $y = $C->_new(\"3"); 
ok (${$C->_str($C->_lsft($x,$y,10))},20000);
$x = $C->_new(\"128"); $y = $C->_new(\"4");
if (!defined $C->_lsft($x,$y,2)) 
  {
  ok (1,1) 
  }
else
  {
  ok ('_lsft','undef');
  }
$x = $C->_new(\"1000"); $y = $C->_new(\"3"); 
ok (${$C->_str($C->_rsft($x,$y,10))},1);
$x = $C->_new(\"20000"); $y = $C->_new(\"3"); 
ok (${$C->_str($C->_rsft($x,$y,10))},20);
$x = $C->_new(\"256"); $y = $C->_new(\"4");
if (!defined $C->_rsft($x,$y,2)) 
  {
  ok (1,1) 
  }
else
  {
  ok ('_rsft','undef');
  }

# _acmp
$x = $C->_new(\"123456789");
$y = $C->_new(\"987654321");
ok ($C->_acmp($x,$y),-1);
ok ($C->_acmp($y,$x),1);
ok ($C->_acmp($x,$x),0);
ok ($C->_acmp($y,$y),0);

# _div
$x = $C->_new(\"3333"); $y = $C->_new(\"1111");
ok (${$C->_str(scalar $C->_div($x,$y))},3);
$x = $C->_new(\"33333"); $y = $C->_new(\"1111"); ($x,$y) = $C->_div($x,$y);
ok (${$C->_str($x)},30); ok (${$C->_str($y)},3);
$x = $C->_new(\"123"); $y = $C->_new(\"1111"); 
($x,$y) = $C->_div($x,$y); ok (${$C->_str($x)},0); ok (${$C->_str($y)},123);

# _num
$x = $C->_new(\"12345"); $x = $C->_num($x); ok (ref($x)||'',''); ok ($x,12345);

# should not happen:
# $x = $C->_new(\"-2"); $y = $C->_new(\"4"); ok ($C->_acmp($x,$y),-1);

# _check
$x = $C->_new(\"123456789");
ok ($C->_check($x),0);
ok ($C->_check(123),'123 is not a reference');

# done

1;


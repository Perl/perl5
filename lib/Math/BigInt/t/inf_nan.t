#!/usr/bin/perl -w

# test inf/NaN handling all in one place
# Thanx to Jarkko for the excellent explanations and the tables

use Test;
use strict;

BEGIN
  {
  $| = 1;	# 7 values  6 groups 4 oprators 2 classes
  plan tests =>   7       * 6      * 4        * 2;
  chdir 't' if -d 't';
  unshift @INC, '../lib';
  }

use Math::BigInt;
use Math::BigFloat;

my (@args,$x,$y,$z);

# +
foreach (qw/
  -inf:-inf:-inf
  -1:-inf:-inf
  -0:-inf:-inf
  0:-inf:-inf
  1:-inf:-inf
  inf:-inf:NaN
  NaN:-inf:NaN

  -inf:-1:-inf
  -1:-1:-2
  -0:-1:-1
  0:-1:-1
  1:-1:0
  inf:-1:inf
  NaN:-1:NaN

  -inf:0:-inf
  -1:0:-1
  -0:0:0
  0:0:0
  1:0:1
  inf:0:inf
  NaN:0:NaN

  -inf:1:-inf
  -1:1:0
  -0:1:1
  0:1:1
  1:1:2
  inf:1:inf
  NaN:1:NaN

  -inf:inf:NaN
  -1:inf:inf
  -0:inf:inf
  0:inf:inf
  1:inf:inf
  inf:inf:inf
  NaN:inf:NaN

  -inf:NaN:NaN
  -1:NaN:NaN
  -0:NaN:NaN
  0:NaN:NaN
  1:NaN:NaN
  inf:NaN:NaN
  NaN:NaN:NaN
  /)
  {
  @args = split /:/,$_;
  for my $class (qw/Math::BigInt Math::BigFloat/)
    {
    $x = $class->new($args[0]);
    $y = $class->new($args[1]);
    $args[2] = '0' if $args[2] eq '-0';		# BigInt/Float hasn't got -0
    print "# $class $args[0] + $args[1] should be $args[2] but is $x\n",
      if !ok ($x->badd($y)->bstr(),$args[2]);
    }
  }

# -
foreach (qw/
  -inf:-inf:NaN
  -1:-inf:inf
  -0:-inf:inf
  0:-inf:inf
  1:-inf:inf
  inf:-inf:inf
  NaN:-inf:NaN

  -inf:-1:-inf
  -1:-1:0
  -0:-1:1
  0:-1:1
  1:-1:2
  inf:-1:inf
  NaN:-1:NaN

  -inf:0:-inf
  -1:0:-1
  -0:0:-0
  0:0:0
  1:0:1
  inf:0:inf
  NaN:0:NaN

  -inf:1:-inf
  -1:1:-2
  -0:1:-1
  0:1:-1
  1:1:0
  inf:1:inf
  NaN:1:NaN

  -inf:inf:-inf
  -1:inf:-inf
  -0:inf:-inf
  0:inf:-inf
  1:inf:-inf
  inf:inf:NaN
  NaN:inf:NaN

  -inf:NaN:NaN
  -1:NaN:NaN
  -0:NaN:NaN
  0:NaN:NaN
  1:NaN:NaN
  inf:NaN:NaN
  NaN:NaN:NaN
  /)
  {
  @args = split /:/,$_;
  for my $class (qw/Math::BigInt Math::BigFloat/)
    {
    $x = $class->new($args[0]);
    $y = $class->new($args[1]);
    $args[2] = '0' if $args[2] eq '-0';		# BigInt/Float hasn't got -0
    print "# $class $args[0] - $args[1] should be $args[2] but is $x\n"
      if !ok ($x->bsub($y)->bstr(),$args[2]);
    }
  }

# *
foreach (qw/
  -inf:-inf:inf
  -1:-inf:inf
  -0:-inf:NaN
  0:-inf:NaN
  1:-inf:-inf
  inf:-inf:-inf
  NaN:-inf:NaN

  -inf:-1:inf
  -1:-1:1
  -0:-1:0
  0:-1:-0
  1:-1:-1
  inf:-1:-inf
  NaN:-1:NaN

  -inf:0:NaN
  -1:0:-0
  -0:0:-0
  0:0:0
  1:0:0
  inf:0:NaN
  NaN:0:NaN

  -inf:1:-inf
  -1:1:-1
  -0:1:-0
  0:1:0
  1:1:1
  inf:1:inf
  NaN:1:NaN

  -inf:inf:-inf
  -1:inf:-inf
  -0:inf:NaN
  0:inf:NaN
  1:inf:inf
  inf:inf:inf
  NaN:inf:NaN

  -inf:NaN:NaN
  -1:NaN:NaN
  -0:NaN:NaN
  0:NaN:NaN
  1:NaN:NaN
  inf:NaN:NaN
  NaN:NaN:NaN
  /)
  {
  @args = split /:/,$_;
  for my $class (qw/Math::BigInt Math::BigFloat/)
    {
    $x = $class->new($args[0]);
    $y = $class->new($args[1]);
    $args[2] = '0' if $args[2] eq '-0';		# BigInt/Float hasn't got -0
    $args[2] = '0' if $args[2] eq '-0';	# BigInt hasn't got -0
    print "# $class $args[0] * $args[1] should be $args[2] but is $x\n"
      if !ok ($x->bmul($y)->bstr(),$args[2]);
    }
  }

# /
foreach (qw/
  -inf:-inf:NaN
  -1:-inf:0
  -0:-inf:0
  0:-inf:-0
  1:-inf:-0
  inf:-inf:NaN
  NaN:-inf:NaN

  -inf:-1:inf
  -1:-1:1
  -0:-1:0
  0:-1:-0
  1:-1:-1
  inf:-1:-inf
  NaN:-1:NaN

  -inf:0:-inf
  -1:0:-inf
  -0:0:NaN
  0:0:NaN
  1:0:inf
  inf:0:inf
  NaN:0:NaN

  -inf:1:-inf
  -1:1:-1
  -0:1:-0
  0:1:0
  1:1:1
  inf:1:inf
  NaN:1:NaN

  -inf:inf:NaN
  -1:inf:-0
  -0:inf:-0
  0:inf:0
  1:inf:0
  inf:inf:NaN
  NaN:inf:NaN

  -inf:NaN:NaN
  -1:NaN:NaN
  -0:NaN:NaN
  0:NaN:NaN
  1:NaN:NaN
  inf:NaN:NaN
  NaN:NaN:NaN
  /)
  {
  @args = split /:/,$_;
  for my $class (qw/Math::BigInt Math::BigFloat/)
    {
    $x = $class->new($args[0]);
    $y = $class->new($args[1]);
    $args[2] = '0' if $args[2] eq '-0';		# BigInt/Float hasn't got -0
    print "# $class $args[0] / $args[1] should be $args[2] but is $x\n"
      if !ok ($x->bdiv($y)->bstr(),$args[2]);
    }
  }


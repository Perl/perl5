#!/usr/bin/perl -w

# test calling conventions

use strict;
use Test;

BEGIN 
  {
  $| = 1;
  # chdir 't' if -d 't';
  unshift @INC, '../lib'; # for running manually
  plan tests => 100;
  }

package Math::BigInt::Test;

use Math::BigInt;
use vars qw/@ISA/;
@ISA = qw/Math::BigInt/;		# child of MBI
use overload;

package Math::BigFloat::Test;

use Math::BigFloat;
use vars qw/@ISA/;
@ISA = qw/Math::BigFloat/;		# child of MBI
use overload;

package main;

use Math::BigInt;
use Math::BigFloat;

my ($x,$y,$z,$u);

###############################################################################
# check whether op's accept normal strings, even when inherited by subclasses

# do one positive and one negative test to avoid false positives by "accident"

my ($func,@args,$ans,$rc,$class,$try);
while (<DATA>)
  {
  chop;
  next if /^#/; # skip comments
  if (s/^&//)
    {
    $func = $_;
    }
  else
    {
    @args = split(/:/,$_,99);
    $ans = pop @args;
    foreach $class (qw/
      Math::BigInt Math::BigFloat Math::BigInt::Test Math::BigFloat::Test/)
      {
      $try = "$class\->$func('$args[0]');";
      $rc = eval $try;
      print "# Tried: '$try'\n" if !ok ($rc, $ans);
      }
    } 

  }

# all done

###############################################################################
# Perl 5.005 does not like ok ($x,undef)

sub ok_undef
  {
  my $x = shift;

  ok (1,1) and return if !defined $x;
  ok ($x,'undef');
  }

__END__
&is_zero
1:0
0:1
&is_one
1:1
0:0
&is_positive
1:1
-1:0
&is_negative
1:0
-1:1
&is_nan
abc:1
1:0
&is_inf
inf:1
0:0
&bstr
5:5
10:10
abc:NaN
+inf:inf
-inf:-inf
&bsstr
1:1e+0
0:0e+1
2:2e+0
200:2e+2
&babs
-1:1
1:1
&bnot
-2:1
1:-2

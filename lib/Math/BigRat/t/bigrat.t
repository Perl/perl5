#!/usr/bin/perl -w

use strict;
use Test;

BEGIN 
  {
  $| = 1;
  chdir 't' if -d 't';
  unshift @INC, '../lib'; # for running manually
  plan tests => 83;
  }

# testing of Math::BigRat

use Math::BigRat;
use Math::BigInt;
use Math::BigFloat;

# shortcuts
my $cr = 'Math::BigRat';		
my $mbi = 'Math::BigInt';
my $mbf = 'Math::BigFloat';

my ($x,$y,$z);

$x = Math::BigRat->new(1234); 		ok ($x,1234);
ok ($x->isa('Math::BigRat'));
ok (!$x->isa('Math::BigFloat'));
ok (!$x->isa('Math::BigInt'));

##############################################################################
# new and bnorm()

foreach my $func (qw/new bnorm/)
  {
  $x = $cr->$func(1234); 	ok ($x,1234);

  $x = $cr->$func('1234/1'); 	ok ($x,1234);
  $x = $cr->$func('1234/2'); 	ok ($x,617);

  $x = $cr->$func('100/1.0');	ok ($x,100);
  $x = $cr->$func('10.0/1.0');	ok ($x,10);
  $x = $cr->$func('0.1/10');	ok ($x,'1/100');
  $x = $cr->$func('0.1/0.1');	ok ($x,'1');
  $x = $cr->$func('1e2/10');	ok ($x,10);
  $x = $cr->$func('1e2/1e1');	ok ($x,10);
  $x = $cr->$func('1 / 3');		ok ($x,'1/3');
  $x = $cr->$func('-1 / 3');	ok ($x,'-1/3');
  $x = $cr->$func('NaN');		ok ($x,'NaN');
  $x = $cr->$func('inf');		ok ($x,'inf');
  $x = $cr->$func('-inf');		ok ($x,'-inf');
  $x = $cr->$func('1/');		ok ($x,'NaN');

  # input ala '1+1/3' isn't parsed ok yet
  $x = $cr->$func('1+1/3');		ok ($x,'NaN');

  ############################################################################
  # other classes as input

  $x = $cr->$func($mbi->new(1231));		ok ($x,'1231');
  $x = $cr->$func($mbf->new(1232));		ok ($x,'1232');
  $x = $cr->$func($mbf->new(1232.3));	ok ($x,'12323/10');
  }

##############################################################################
# mixed arguments

ok (Math::BigRat->new('3/7')->badd(1),'10/7');
ok (Math::BigRat->new('3/10')->badd(1.1),'7/5');
ok (Math::BigRat->new('3/7')->badd(Math::BigInt->new(1)),'10/7');
ok (Math::BigRat->new('3/10')->badd(Math::BigFloat->new('1.1')),'7/5');

ok (Math::BigRat->new('3/7')->bsub(1),'-4/7');
ok (Math::BigRat->new('3/10')->bsub(1.1),'-4/5');
ok (Math::BigRat->new('3/7')->bsub(Math::BigInt->new(1)),'-4/7');
ok (Math::BigRat->new('3/10')->bsub(Math::BigFloat->new('1.1')),'-4/5');

ok (Math::BigRat->new('3/7')->bmul(1),'3/7');
ok (Math::BigRat->new('3/10')->bmul(1.1),'33/100');
ok (Math::BigRat->new('3/7')->bmul(Math::BigInt->new(1)),'3/7');
ok (Math::BigRat->new('3/10')->bmul(Math::BigFloat->new('1.1')),'33/100');

ok (Math::BigRat->new('3/7')->bdiv(1),'3/7');
ok (Math::BigRat->new('3/10')->bdiv(1.1),'3/11');
ok (Math::BigRat->new('3/7')->bdiv(Math::BigInt->new(1)),'3/7');
ok (Math::BigRat->new('3/10')->bdiv(Math::BigFloat->new('1.1')),'3/11');

##############################################################################
$x = Math::BigRat->new('1/4'); $y = Math::BigRat->new('1/3');
ok ($x + $y, '7/12');
ok ($x * $y, '1/12');
ok ($x / $y, '3/4');

$x = Math::BigRat->new('7/5'); $x *= '3/2'; 
ok ($x,'21/10');
$x -= '0.1';
ok ($x,'2');	# not 21/10

$x = Math::BigRat->new('2/3');		$y = Math::BigRat->new('3/2');
ok ($x > $y,'');		
ok ($x < $y,1);
ok ($x == $y,'');

$x = Math::BigRat->new('-2/3');		$y = Math::BigRat->new('3/2');
ok ($x > $y,'');		
ok ($x < $y,'1');
ok ($x == $y,'');

$x = Math::BigRat->new('-2/3');		$y = Math::BigRat->new('-2/3');
ok ($x > $y,'');		
ok ($x < $y,'');
ok ($x == $y,'1');

$x = Math::BigRat->new('-2/3');		$y = Math::BigRat->new('-1/3');
ok ($x > $y,'');		
ok ($x < $y,'1');
ok ($x == $y,'');

$x = Math::BigRat->new('-124');		$y = Math::BigRat->new('-122');
ok ($x->bacmp($y),1);

$x = Math::BigRat->new('-124');		$y = Math::BigRat->new('-122');
ok ($x->bcmp($y),-1);

$x = Math::BigRat->new('3/7');		$y = Math::BigRat->new('5/7');
ok ($x+$y,'8/7');

$x = Math::BigRat->new('3/7');		$y = Math::BigRat->new('5/7');
ok ($x*$y,'15/49');

$x = Math::BigRat->new('3/5');		$y = Math::BigRat->new('5/7');
ok ($x*$y,'3/7');

$x = Math::BigRat->new('3/5');		$y = Math::BigRat->new('5/7');
ok ($x/$y,'21/25');

$x = Math::BigRat->new('-144/9'); $x->bsqrt(); ok ($x,'NaN');
$x = Math::BigRat->new('144/9');  $x->bsqrt(); ok ($x,'4');

# done

1;


#!/usr/bin/perl -w

use strict;
use Test;

BEGIN 
  {
  $| = 1;
  chdir 't' if -d 't';
  unshift @INC, '../lib'; # for running manually
  plan tests => 94;
  }

use Math::BigInt::Lite;

my $c = 'Math::BigInt::Lite';
my $mbi = 'Math::BigInt';

ok (Math::BigInt::Lite->config()->{version},$Math::BigInt::VERSION);
ok (Math::BigInt::Lite->config()->{version_lite},$Math::BigInt::Lite::VERSION);

my ($x,$y,$z);

##############################################################################
$x = $c->new(1234); 	ok (ref($x),$c);	ok ($x,1234);
ok ($x->isa('Math::BigInt::Lite'));
ok (!$x->isa('Math::BigRat'));
ok (!$x->isa('Math::BigFloat'));

$x = $c->new('1e3'); 	ok (ref($x),$c);	ok ($x,'1000');
$x = $c->new('1000'); 	ok (ref($x),$c);	ok ($x,'1000');
$x = $c->new('1234'); 	ok (ref($x),$c);	ok ($x,1234);
$x = $c->new('1e12'); 	ok (ref($x),$mbi);
$x = $c->new('1.'); 	ok (ref($x),$c);	ok ($x,1);
$x = $c->new('1.0'); 	ok (ref($x),$c);	ok ($x,1);
$x = $c->new('1.00'); 	ok (ref($x),$c);	ok ($x,1);
$x = $c->new('1.02'); 	ok (ref($x),$mbi);	ok ($x,'NaN');

$x = $c->new('1'); 	ok (ref($x),$c); $y = $x->copy(); ok (ref($y),$c);
ok ($x,$y);

$x = $c->new('6'); 	$y = $c->new('2');
ok (ref($x),$c); ok (ref($y),$c);

$z = $x; $z += $y; 	ok (ref($z),$c);	ok ($z,8);
$z = $x + $y;	 	ok (ref($z),$c);	ok ($z,8);
$z = $x - $y;	 	ok (ref($z),$c);	ok ($z,4);
$z = $y - $x;	 	ok (ref($z),$c);	ok ($z,-4);
$z = $x * $y;	 	ok (ref($z),$c);	ok ($z,12);
$z = $x / $y;	 	ok (ref($z),$c);	ok ($z,3);
$z = $x % $y;	 	ok (ref($z),$c);	ok ($z,0);

$z = $y / $x;	 	ok (ref($z),$c);	ok ($z,0);
$z = $y % $x;	 	ok (ref($z),$c);	ok ($z,2);

$z = $x->as_number(); 	ok (ref($z),$mbi);	ok ($z,6);

###############################################################################
# bone/binf etc

$z = $c->bone();	ok (ref($z),$c);	ok ($z,1);
$z = $c->bone('-');	ok (ref($z),$c);	ok ($z,-1);
$z = $c->bone('+');	ok (ref($z),$c);	ok ($z,1);
$z = $c->bzero();	ok (ref($z),$c);	ok ($z,0);
$z = $c->binf();	ok (ref($z),$mbi);	ok ($z,'inf');
$z = $c->binf('+');	ok (ref($z),$mbi);	ok ($z,'inf');
$z = $c->binf('+inf');	ok (ref($z),$mbi);	ok ($z,'inf');
$z = $c->binf('-');	ok (ref($z),$mbi);	ok ($z,'-inf');
$z = $c->binf('-inf');	ok (ref($z),$mbi);	ok ($z,'-inf');
$z = $c->bnan();	ok (ref($z),$mbi);	ok ($z,'NaN');

$x = $c->new(3); 
$z = $x->copy()->bone();	ok (ref($z),$c);	ok ($z,1);
$z = $x->copy()->bone('-');	ok (ref($z),$c);	ok ($z,-1);
$z = $x->copy()->bone('+');	ok (ref($z),$c);	ok ($z,1);
$z = $x->copy()->bzero();	ok (ref($z),$c);	ok ($z,0);
$z = $x->copy()->binf();	ok (ref($z),$mbi);	ok ($z,'inf');
$z = $x->copy()->binf('+');	ok (ref($z),$mbi);	ok ($z,'inf');
$z = $x->copy()->binf('+inf');	ok (ref($z),$mbi);	ok ($z,'inf');
$z = $x->copy()->binf('-');	ok (ref($z),$mbi);	ok ($z,'-inf');
$z = $x->copy()->binf('-inf');	ok (ref($z),$mbi);	ok ($z,'-inf');
$z = $x->copy()->bnan();	ok (ref($z),$mbi);	ok ($z,'NaN');

###############################################################################
# non-objects

$x = Math::BigInt::Lite::badd('1','2'); ok ($x,3);
$x = Math::BigInt::Lite::badd('1',2); ok ($x,3);
$x = Math::BigInt::Lite::badd(1,'2'); ok ($x,3);
$x = Math::BigInt::Lite::badd(1,2); ok ($x,3);

$x = Math::BigInt::Lite->new(123456);
ok ($x->copy()->round(3),123000);
ok ($x->copy()->bround(3),123000);
ok ($x->copy()->bfround(3),123000);

# done

1;


#!/usr/bin/perl -w

# test rounding, accuracy, precicion and fallback, round_mode and mixing
# of classes

# Make sure you always quote any bare floating-point values, lest 123.46 will
# be stringified to 123.4599999999 due to limited float prevision.

use strict;
use Test;

BEGIN 
  {
  $| = 1;
  chdir 't' if -d 't';
  unshift @INC, '../lib'; # for running manually
  plan tests => 260;
  }

# for finding out whether round finds correct class
package Foo;

use Math::BigInt;
use vars qw/@ISA $precision $accuracy $div_scale $round_mode/;
@ISA = qw/Math::BigInt/;

$precision = 6;
$accuracy = 8;
$div_scale = 5;
$round_mode = 'odd';

sub new
  {
  my $class = shift; 
  my $self = { _a => undef, _p => undef, value => 5 };
  bless $self, $class;
  }

sub bstr
  { 
  my $self = shift;

  return "$self->{value}";
  }

# these will be called with the rounding precision or accuracy, depending on
# class
sub bround
  {
  my ($self,$a,$r) = @_;
  $self->{value} = 'a' x $a;
  return $self;
  }

sub bnorm
  {
  my $self = shift;
  return $self;
  }

sub bfround
  {
  my ($self,$p,$r) = @_;
  $self->{value} = 'p' x $p;
  return $self;
  }

package main;

use Math::BigInt;
use Math::BigFloat;

my ($x,$y,$z,$u);

###############################################################################
# test defaults and set/get

ok_undef ($Math::BigInt::accuracy);
ok_undef ($Math::BigInt::precision);
ok_undef (Math::BigInt::accuracy());
ok_undef (Math::BigInt::precision());
ok_undef (Math::BigInt->accuracy());
ok_undef (Math::BigInt->precision());
ok ($Math::BigInt::div_scale,40);
ok (Math::BigInt::div_scale(),40);
ok ($Math::BigInt::round_mode,'even');
ok (Math::BigInt::round_mode(),'even');
ok (Math::BigInt->round_mode(),'even');

ok_undef ($Math::BigFloat::accuracy);
ok_undef ($Math::BigFloat::precision);
ok_undef (Math::BigFloat::accuracy());
ok_undef (Math::BigFloat::accuracy());
ok_undef (Math::BigFloat->precision());
ok_undef (Math::BigFloat->precision());
ok ($Math::BigFloat::div_scale,40);
ok (Math::BigFloat::div_scale(),40);
ok ($Math::BigFloat::round_mode,'even');
ok (Math::BigFloat::round_mode(),'even');
ok (Math::BigFloat->round_mode(),'even');

# old way
ok ($Math::BigInt::rnd_mode,'even');
ok ($Math::BigFloat::rnd_mode,'even');

$x = eval 'Math::BigInt->round_mode("huhmbi");';
ok ($@ =~ /^Unknown round mode huhmbi at/);

$x = eval 'Math::BigFloat->round_mode("huhmbf");';
ok ($@ =~ /^Unknown round mode huhmbf at/);

# old way (now with test for validity)
$x = eval '$Math::BigInt::rnd_mode = "huhmbi";';
ok ($@ =~ /^Unknown round mode huhmbi at/);
$x = eval '$Math::BigFloat::rnd_mode = "huhmbi";';
ok ($@ =~ /^Unknown round mode huhmbi at/);
# see if accessor also changes old variable
Math::BigInt->round_mode('odd');
ok ($Math::BigInt::rnd_mode,'odd');
Math::BigFloat->round_mode('odd');
ok ($Math::BigFloat::rnd_mode,'odd');

Math::BigInt->round_mode('even');
Math::BigFloat->round_mode('even');

# accessors
foreach my $class (qw/Math::BigInt Math::BigFloat/)
  {
  ok_undef ($class->accuracy());
  ok_undef ($class->precision());
  ok ($class->round_mode(),'even');
  ok ($class->div_scale(),40);
   
  ok ($class->div_scale(20),20);
  $class->div_scale(40); ok ($class->div_scale(),40);
  
  ok ($class->round_mode('odd'),'odd');
  $class->round_mode('even'); ok ($class->round_mode(),'even');
  
  ok ($class->accuracy(2),2);
  $class->accuracy(3); ok ($class->accuracy(),3);
  ok_undef ($class->accuracy(undef));

  ok ($class->precision(2),2);
  ok ($class->precision(-2),-2);
  $class->precision(3); ok ($class->precision(),3);
  ok_undef ($class->precision(undef));
  }

# accuracy
foreach (qw/5 42 -1 0/)
  {
  ok ($Math::BigFloat::accuracy = $_,$_);
  ok ($Math::BigInt::accuracy = $_,$_);
  }
ok_undef ($Math::BigFloat::accuracy = undef);
ok_undef ($Math::BigInt::accuracy = undef);

# precision
foreach (qw/5 42 -1 0/)
  {
  ok ($Math::BigFloat::precision = $_,$_);
  ok ($Math::BigInt::precision = $_,$_);
  }
ok_undef ($Math::BigFloat::precision = undef);
ok_undef ($Math::BigInt::precision = undef);

# fallback
foreach (qw/5 42 1/)
  {
  ok ($Math::BigFloat::div_scale = $_,$_);
  ok ($Math::BigInt::div_scale = $_,$_);
  }
# illegal values are possible for fallback due to no accessor

# round_mode
foreach (qw/odd even zero trunc +inf -inf/)
  {
  ok ($Math::BigFloat::round_mode = $_,$_);
  ok ($Math::BigInt::round_mode = $_,$_);
  }
$Math::BigFloat::round_mode = 'zero';
ok ($Math::BigFloat::round_mode,'zero');
ok ($Math::BigInt::round_mode,'-inf');	# from above

$Math::BigInt::accuracy = undef;
$Math::BigInt::precision = undef;
# local copies
$x = Math::BigFloat->new('123.456');
ok_undef ($x->accuracy());
ok ($x->accuracy(5),5);
ok_undef ($x->accuracy(undef),undef);
ok_undef ($x->precision());
ok ($x->precision(5),5);
ok_undef ($x->precision(undef),undef);

# see if MBF changes MBIs values
ok ($Math::BigInt::accuracy = 42,42);
ok ($Math::BigFloat::accuracy = 64,64);
ok ($Math::BigInt::accuracy,42);		# should be still 42
ok ($Math::BigFloat::accuracy,64);		# should be still 64

###############################################################################
# see if creating a number under set A or P will round it

$Math::BigInt::accuracy = 4;
$Math::BigInt::precision = 3;

ok (Math::BigInt->new(123456),123500);	# with A
$Math::BigInt::accuracy = undef;
ok (Math::BigInt->new(123456),123000);	# with P

$Math::BigFloat::accuracy = 4;
$Math::BigFloat::precision = -1;
$Math::BigInt::precision = undef;

ok (Math::BigFloat->new('123.456'),'123.5');	# with A
$Math::BigFloat::accuracy = undef;
ok (Math::BigFloat->new('123.456'),'123.5');	# with P from MBF, not MBI!

$Math::BigFloat::precision = undef;

###############################################################################
# see if setting accuracy/precision actually rounds the number

$x = Math::BigFloat->new('123.456'); $x->accuracy(4);   ok ($x,'123.5');
$x = Math::BigFloat->new('123.456'); $x->precision(-2); ok ($x,'123.46');

$x = Math::BigInt->new(123456);      $x->accuracy(4);   ok ($x,123500);
$x = Math::BigInt->new(123456);      $x->precision(2);  ok ($x,123500);

###############################################################################
# test actual rounding via round()

$x = Math::BigFloat->new('123.456');
ok ($x->copy()->round(5,2),'123.46');
ok ($x->copy()->round(4,2),'123.5');
ok ($x->copy()->round(undef,-2),'123.46');
ok ($x->copy()->round(undef,2),100);

$x = Math::BigFloat->new('123.45000');
ok ($x->copy()->round(undef,-1,'odd'),'123.5');

# see if rounding is 'sticky'
$x = Math::BigFloat->new('123.4567');
$y = $x->copy()->bround();		# no-op since nowhere A or P defined

ok ($y,123.4567);			
$y = $x->copy()->round(5,2);
ok ($y->accuracy(),5);
ok_undef ($y->precision());		# A has precedence, so P still unset
$y = $x->copy()->round(undef,2);
ok ($y->precision(),2);
ok_undef ($y->accuracy());		# P has precedence, so A still unset

# see if setting A clears P and vice versa
$x = Math::BigFloat->new('123.4567');
ok ($x,'123.4567');
ok ($x->accuracy(4),4);
ok ($x->precision(-2),-2);		# clear A
ok_undef ($x->accuracy());

$x = Math::BigFloat->new('123.4567');
ok ($x,'123.4567');
ok ($x->precision(-2),-2);
ok ($x->accuracy(4),4);			# clear P
ok_undef ($x->precision());

# does copy work?
$x = Math::BigFloat->new(123.456); $x->accuracy(4); $x->precision(2);
$z = $x->copy(); ok_undef ($z->accuracy(),undef); ok ($z->precision(),2);

###############################################################################
# test wether operations round properly afterwards
# These tests are not complete, since they do not excercise every "return"
# statement in the op's. But heh, it's better than nothing...

$x = Math::BigFloat->new('123.456');
$y = Math::BigFloat->new('654.321');
$x->{_a} = 5;		# $x->accuracy(5) would round $x straightaway
$y->{_a} = 4;		# $y->accuracy(4) would round $x straightaway

$z = $x + $y;		ok ($z,'777.8');
$z = $y - $x;		ok ($z,'530.9');
$z = $y * $x;		ok ($z,'80780');
$z = $x ** 2;		ok ($z,'15241');
$z = $x * $x;		ok ($z,'15241');

# not: $z = -$x;		ok ($z,'-123.46'); ok ($x,'123.456');
$z = $x->copy(); $z->{_a} = 2; $z = $z / 2; ok ($z,62);
$x = Math::BigFloat->new(123456); $x->{_a} = 4;
$z = $x->copy; $z++;	ok ($z,123500);

$x = Math::BigInt->new(123456);
$y = Math::BigInt->new(654321);
$x->{_a} = 5;		# $x->accuracy(5) would round $x straightaway
$y->{_a} = 4;		# $y->accuracy(4) would round $x straightaway

$z = $x + $y; 		ok ($z,777800);
$z = $y - $x; 		ok ($z,530900);
$z = $y * $x;		ok ($z,80780000000);
$z = $x ** 2;		ok ($z,15241000000);
# not yet: $z = -$x;		ok ($z,-123460); ok ($x,123456);
$z = $x->copy; $z++;	ok ($z,123460);
$z = $x->copy(); $z->{_a} = 2; $z = $z / 2; ok ($z,62000);

$x = Math::BigInt->new(123400); $x->{_a} = 4;
ok ($x->bnot(),-123400);			# not -1234001

# both babs() and bneg() don't need to round, since the input will already
# be rounded (either as $x or via new($string)), and they don't change the
# value
# The two tests below peek at this by using _a illegally
$x = Math::BigInt->new(-123401); $x->{_a} = 4;
ok ($x->babs(),123401);
$x = Math::BigInt->new(-123401); $x->{_a} = 4;
ok ($x->bneg(),123401);

###############################################################################
# test mixed arguments

$x = Math::BigFloat->new(10);
$u = Math::BigFloat->new(2.5);
$y = Math::BigInt->new(2);

$z = $x + $y; ok ($z,12); ok (ref($z),'Math::BigFloat');
$z = $x / $y; ok ($z,5); ok (ref($z),'Math::BigFloat');
$z = $u * $y; ok ($z,5); ok (ref($z),'Math::BigFloat');

$y = Math::BigInt->new(12345);
$z = $u->copy()->bmul($y,2,0,'odd'); ok ($z,31000);
$z = $u->copy()->bmul($y,3,0,'odd'); ok ($z,30900);
$z = $u->copy()->bmul($y,undef,0,'odd'); ok ($z,30863);
$z = $u->copy()->bmul($y,undef,1,'odd'); ok ($z,30860);
$z = $u->copy()->bmul($y,undef,-1,'odd'); ok ($z,30862.5);

# breakage:
# $z = $y->copy()->bmul($u,2,0,'odd'); ok ($z,31000);
# $z = $y * $u; ok ($z,5); ok (ref($z),'Math::BigInt');
# $z = $y + $x; ok ($z,12); ok (ref($z),'Math::BigInt');
# $z = $y / $x; ok ($z,0); ok (ref($z),'Math::BigInt');

###############################################################################
# rounding in bdiv with fallback and already set A or P

$Math::BigFloat::accuracy = undef;
$Math::BigFloat::precision = undef;
$Math::BigFloat::div_scale = 40;

$x = Math::BigFloat->new(10); $x->{_a} = 4;
ok ($x->bdiv(3),'3.333');
ok ($x->{_a},4);			# set's it since no fallback

$x = Math::BigFloat->new(10); $x->{_a} = 4; $y = Math::BigFloat->new(3);
ok ($x->bdiv($y),'3.333');
ok ($x->{_a},4);			# set's it since no fallback

# rounding to P of x
$x = Math::BigFloat->new(10); $x->{_p} = -2;
ok ($x->bdiv(3),'3.33');

# round in div with requested P
$x = Math::BigFloat->new(10);
ok ($x->bdiv(3,undef,-2),'3.33');

# round in div with requested P greater than fallback
$Math::BigFloat::div_scale = 5;
$x = Math::BigFloat->new(10);
ok ($x->bdiv(3,undef,-8),'3.33333333');
$Math::BigFloat::div_scale = 40;

$x = Math::BigFloat->new(10); $y = Math::BigFloat->new(3); $y->{_a} = 4;
ok ($x->bdiv($y),'3.333');
ok ($x->{_a},4); ok ($y->{_a},4);	# set's it since no fallback
ok_undef ($x->{_p}); ok_undef ($y->{_p});

# rounding to P of y
$x = Math::BigFloat->new(10); $y = Math::BigFloat->new(3); $y->{_p} = -2;
ok ($x->bdiv($y),'3.33');
ok ($x->{_p},-2);
 ok ($y->{_p},-2);
ok_undef ($x->{_a}); ok_undef ($y->{_a});

###############################################################################
# test whether bround(-n) fails in MBF (undocumented in MBI)
eval { $x = Math::BigFloat->new(1); $x->bround(-2); };
ok ($@ =~ /^bround\(\) needs positive accuracy/,1);

# test whether rounding to higher accuracy is no-op
$x = Math::BigFloat->new(1); $x->{_a} = 4;
ok ($x,'1.000');
$x->bround(6);                  # must be no-op
ok ($x->{_a},4);
ok ($x,'1.000');

$x = Math::BigInt->new(1230); $x->{_a} = 3;
ok ($x,'1230');
$x->bround(6);                  # must be no-op
ok ($x->{_a},3);
ok ($x,'1230');

# bround(n) should set _a
$x->bround(2);                  # smaller works
ok ($x,'1200');
ok ($x->{_a},2);
 
# bround(-n) is undocumented and only used by MBF
# bround(-n) should set _a
$x = Math::BigInt->new(12345);
$x->bround(-1);
ok ($x,'12300');
ok ($x->{_a},4);
 
# bround(-n) should set _a
$x = Math::BigInt->new(12345);
$x->bround(-2);
ok ($x,'12000');
ok ($x->{_a},3);
 
# bround(-n) should set _a
$x = Math::BigInt->new(12345); $x->{_a} = 5;
$x->bround(-3);
ok ($x,'10000');
ok ($x->{_a},2);
 
# bround(-n) should set _a
$x = Math::BigInt->new(12345); $x->{_a} = 5;
$x->bround(-4);
ok ($x,'00000');
ok ($x->{_a},1);

# bround(-n) should be noop if n too big
$x = Math::BigInt->new(12345);
$x->bround(-5);
ok ($x,'0');			# scale to "big" => 0
ok ($x->{_a},0);
 
# bround(-n) should be noop if n too big
$x = Math::BigInt->new(54321);
$x->bround(-5);
ok ($x,'100000');		# used by MBF to round 0.0054321 at 0.0_6_00000
ok ($x->{_a},0);
 
# bround(-n) should be noop if n too big
$x = Math::BigInt->new(54321); $x->{_a} = 5;
$x->bround(-6);
ok ($x,'100000');		# no-op
ok ($x->{_a},0);
 
# bround(n) should set _a
$x = Math::BigInt->new(12345); $x->{_a} = 5;
$x->bround(5);                  # must be no-op
ok ($x,'12345');
ok ($x->{_a},5);
 
# bround(n) should set _a
$x = Math::BigInt->new(12345); $x->{_a} = 5;
$x->bround(6);                  # must be no-op
ok ($x,'12345');

$x = Math::BigFloat->new('0.0061'); $x->bfround(-2);
ok ($x,'0.01');

###############################################################################
# rounding with already set precision/accuracy

$x = Math::BigFloat->new(1); $x->{_p} = -5;
ok ($x,'1.00000');

# further rounding donw
ok ($x->bfround(-2),'1.00');
ok ($x->{_p},-2);

$x = Math::BigFloat->new(12345); $x->{_a} = 5;
ok ($x->bround(2),'12000');
ok ($x->{_a},2);

$x = Math::BigFloat->new('1.2345'); $x->{_a} = 5;
ok ($x->bround(2),'1.2');
ok ($x->{_a},2);

# mantissa/exponent format and A/P
$x = Math::BigFloat->new('12345.678'); $x->accuracy(4);
ok ($x,'12350'); ok ($x->{_a},4); ok_undef ($x->{_p});
ok ($x->{_m}->{_f},1); ok ($x->{_e}->{_f},1);
ok_undef ($x->{_m}->{_a}); ok_undef ($x->{_e}->{_a});
ok_undef ($x->{_m}->{_p}); ok_undef ($x->{_e}->{_p});

# check for no A/P in case of fallback
# result
$x = Math::BigFloat->new(100) / 3;
ok_undef ($x->{_a}); ok_undef ($x->{_p});

# result & reminder
$x = Math::BigFloat->new(100) / 3; ($x,$y) = $x->bdiv(3);
ok_undef ($x->{_a}); ok_undef ($x->{_p});
ok_undef ($y->{_a}); ok_undef ($y->{_p});

###############################################################################
# math with two numbers with differen A and P

$x = Math::BigFloat->new(12345); $x->accuracy(4);	# '12340'
$y = Math::BigFloat->new(12345); $y->accuracy(2);	# '12000'
ok ($x+$y,24000);				# 12340+12000=> 24340 => 24000

$x = Math::BigFloat->new(54321); $x->accuracy(4);	# '12340'
$y = Math::BigFloat->new(12345); $y->accuracy(3);	# '12000'
ok ($x-$y,42000);				# 54320+12300=> 42020 => 42000

$x = Math::BigFloat->new('1.2345'); $x->precision(-2);	# '1.23'
$y = Math::BigFloat->new('1.2345'); $y->precision(-4);	# '1.2345'
ok ($x+$y,'2.46');			# 1.2345+1.2300=> 2.4645 => 2.46

###############################################################################
# round should find and use proper class

$x = Foo->new();
ok ($x->round($Foo::accuracy),'a' x $Foo::accuracy);
ok ($x->round(undef,$Foo::precision),'p' x $Foo::precision);
ok ($x->bfround($Foo::precision),'p' x $Foo::precision);
ok ($x->bround($Foo::accuracy),'a' x $Foo::accuracy);

###############################################################################
# find out whether _find_round_parameters is doing what's it's supposed to do
 
$Math::BigInt::accuracy = undef;
$Math::BigInt::precision = undef;
$Math::BigInt::div_scale = 40;
$Math::BigInt::round_mode = 'odd';
 
$x = Math::BigInt->new(123);
my @params = $x->_find_round_parameters();
ok (scalar @params,1);				# nothing to round

@params = $x->_find_round_parameters(1);
ok (scalar @params,4);				# a=1
ok ($params[0],$x);				# self
ok ($params[1],1);				# a
ok_undef ($params[2]);				# p
ok ($params[3],'odd');				# round_mode

@params = $x->_find_round_parameters(undef,2);
ok (scalar @params,4);				# p=2
ok ($params[0],$x);				# self
ok_undef ($params[1]);				# a
ok ($params[2],2);				# p
ok ($params[3],'odd');				# round_mode

eval { @params = $x->_find_round_parameters(undef,2,'foo'); };
ok ($@ =~ /^Unknown round mode 'foo'/,1);

@params = $x->_find_round_parameters(undef,2,'+inf');
ok (scalar @params,4);				# p=2
ok ($params[0],$x);				# self
ok_undef ($params[1]);				# a
ok ($params[2],2);				# p
ok ($params[3],'+inf');				# round_mode

@params = $x->_find_round_parameters(2,-2,'+inf');
ok (scalar @params,4);				# p=2
ok ($params[0],$x);				# self
ok ($params[1],2);				# a
ok ($params[2],-2);				# p
ok ($params[3],'+inf');				# round_mode

# all done

###############################################################################
# Perl 5.005 does not like ok ($x,undef)

sub ok_undef
  {
  my $x = shift;

  ok (1,1) and return if !defined $x;
  ok ($x,'undef');
  }


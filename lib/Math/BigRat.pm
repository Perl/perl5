#!/usr/bin/perl -w

# The following hash values are used:
#   sign : +,-,NaN,+inf,-inf
#   _d   : denominator
#   _n   : numeraotr (value = _n/_d)
#   _a   : accuracy
#   _p   : precision
#   _f   : flags, used by MBR to flag parts of a rationale as untouchable

package Math::BigRat;

require 5.005_02;
use strict;

use Exporter;
use Math::BigFloat;
use vars qw($VERSION @ISA $PACKAGE @EXPORT_OK $upgrade $downgrade
            $accuracy $precision $round_mode $div_scale);

@ISA = qw(Exporter Math::BigFloat);
@EXPORT_OK = qw();

$VERSION = '0.05';

use overload;				# inherit from Math::BigFloat

##############################################################################
# global constants, flags and accessory

use constant MB_NEVER_ROUND => 0x0001;

$accuracy = $precision = undef;
$round_mode = 'even';
$div_scale = 40;
$upgrade = undef;
$downgrade = undef;

my $nan = 'NaN';
my $class = 'Math::BigRat';

sub isa
  {
  return 0 if $_[1] =~ /^Math::Big(Int|Float)/;		# we aren't
  UNIVERSAL::isa(@_);
  }

sub _new_from_float
  {
  # turn a single float input into a rationale (like '0.1')
  my ($self,$f) = @_;

  return $self->bnan() if $f->is_nan();
  return $self->binf('-inf') if $f->{sign} eq '-inf';
  return $self->binf('+inf') if $f->{sign} eq '+inf';

  #print "f $f caller", join(' ',caller()),"\n";
  $self->{_n} = $f->{_m}->copy();			# mantissa
  $self->{_d} = Math::BigInt->bone();
  $self->{sign} = $f->{sign}; $self->{_n}->{sign} = '+';
  if ($f->{_e}->{sign} eq '-')
    {
    # something like Math::BigRat->new('0.1');
    $self->{_d}->blsft($f->{_e}->copy()->babs(),10);	# 1 / 1 => 1/10
    }
  else
    {
    # something like Math::BigRat->new('10');
    # 1 / 1 => 10/1
    $self->{_n}->blsft($f->{_e},10) unless $f->{_e}->is_zero();	
    }
#  print "float new $self->{_n} / $self->{_d}\n";
  $self;
  }

sub new
  {
  # create a Math::BigRat
  my $class = shift;

  my ($n,$d) = shift;

  my $self = { }; bless $self,$class;
 
#  print "ref ",ref($d),"\n";
#  if (ref($d))
#    {
#  print "isa float ",$d->isa('Math::BigFloat'),"\n";
#  print "isa int ",$d->isa('Math::BigInt'),"\n";
#  print "isa rat ",$d->isa('Math::BigRat'),"\n";
#    }

  # input like (BigInt,BigInt) or (BigFloat,BigFloat) not handled yet

  if ((ref $n) && (!$n->isa('Math::BigRat')))
    {
#    print "is ref, but not rat\n";
    if ($n->isa('Math::BigFloat'))
      {
   #   print "is ref, and float\n";
      return $self->_new_from_float($n)->bnorm();
      }
    if ($n->isa('Math::BigInt'))
      {
#      print "is ref, and int\n";
      $self->{_n} = $n->copy();				# "mantissa" = $n
      $self->{_d} = Math::BigInt->bone();
      $self->{sign} = $self->{_n}->{sign}; $self->{_n}->{sign} = '+';
      return $self->bnorm();
      }
    if ($n->isa('Math::BigInt::Lite'))
      {
#      print "is ref, and lite\n";
      $self->{_n} = Math::BigInt->new($$n);		# "mantissa" = $n
      $self->{_d} = Math::BigInt->bone();
      $self->{sign} = $self->{_n}->{sign}; $self->{_n}->{sign} = '+';
      return $self->bnorm();
      }
    }
  return $n->copy() if ref $n;
      
#  print "is string\n";

  if (!defined $n)
    {
    $self->{_n} = Math::BigInt->bzero();	# undef => 0
    $self->{_d} = Math::BigInt->bone();
    $self->{sign} = '+';
    return $self->bnorm();
    }
  # string input with / delimiter
  if ($n =~ /\s*\/\s*/)
    {
    return Math::BigRat->bnan() if $n =~ /\/.*\//;	# 1/2/3 isn't valid
    return Math::BigRat->bnan() if $n =~ /\/\s*$/;	# 1/ isn't valid
    ($n,$d) = split (/\//,$n);
    # try as BigFloats first
    if (($n =~ /[\.eE]/) || ($d =~ /[\.eE]/))
      {
      # one of them looks like a float 
      $self->_new_from_float(Math::BigFloat->new($n));
      # now correct $self->{_n} due to $n
      my $f = Math::BigFloat->new($d);
      if ($f->{_e}->{sign} eq '-')
        {
	# 10 / 0.1 => 100/1
        $self->{_n}->blsft($f->{_e}->copy()->babs(),10);
        }
      else
        {
        $self->{_d}->blsft($f->{_e},10); 		# 1 / 1 => 10/1
         }
      }
    else
      {
      $self->{_n} = Math::BigInt->new($n);
      $self->{_d} = Math::BigInt->new($d);
      return $self->bnan() if $self->{_n}->is_nan() || $self->{_d}->is_nan();
      # inf handling is missing here
 
      $self->{sign} = $self->{_n}->{sign}; $self->{_n}->{sign} = '+';
      # if $d is negative, flip sign
      $self->{sign} =~ tr/+-/-+/ if $self->{_d}->{sign} eq '-';
      $self->{_d}->{sign} = '+';	# normalize
      }
    return $self->bnorm();
    }

  # simple string input
  if (($n =~ /[\.eE]/))
    {
    # looks like a float
#    print "float-like string $d\n";
    $self->_new_from_float(Math::BigFloat->new($n));
    }
  else
    {
    $self->{_n} = Math::BigInt->new($n);
    $self->{_d} = Math::BigInt->bone();
    $self->{sign} = $self->{_n}->{sign}; $self->{_n}->{sign} = '+';
    }
  $self->bnorm();
  }

###############################################################################

sub bstr
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  if ($x->{sign} !~ /^[+-]$/)		# inf, NaN etc
    {
    my $s = $x->{sign}; $s =~ s/^\+//; 	# +inf => inf
    return $s;
    }

#  print "bstr $x->{sign} $x->{_n} $x->{_d}\n";
  my $s = ''; $s = $x->{sign} if $x->{sign} ne '+';	# +3 vs 3

  return $s.$x->{_n}->bstr() if $x->{_d}->is_one(); 
  return $s.$x->{_n}->bstr() . '/' . $x->{_d}->bstr(); 
  }

sub bsstr
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  if ($x->{sign} !~ /^[+-]$/)		# inf, NaN etc
    {
    my $s = $x->{sign}; $s =~ s/^\+//; 	# +inf => inf
    return $s;
    }
  
  my $s = ''; $s = $x->{sign} if $x->{sign} ne '+';	# +3 vs 3
  return $x->{_n}->bstr() . '/' . $x->{_d}->bstr(); 
  }

sub bnorm
  {
  # reduce the number to the shortest form and remember this (so that we
  # don't reduce again)
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  # this is to prevent automatically rounding when MBI's globals are set
  $x->{_d}->{_f} = MB_NEVER_ROUND;
  $x->{_n}->{_f} = MB_NEVER_ROUND;
  # 'forget' that parts were rounded via MBI::bround() in MBF's bfround()
  $x->{_d}->{_a} = undef; $x->{_n}->{_a} = undef;
  $x->{_d}->{_p} = undef; $x->{_n}->{_p} = undef; 

  # normalize zeros to 0/1
  if (($x->{sign} =~ /^[+-]$/) &&
      ($x->{_n}->is_zero()))
    {
    $x->{sign} = '+';						# never -0
    $x->{_d} = Math::BigInt->bone() unless $x->{_d}->is_one();
    return $x;
    }

#  print "$x->{_n} / $x->{_d} => ";
  # reduce other numbers
  # print "bgcd $x->{_n} (",ref($x->{_n}),") $x->{_d} (",ref($x->{_d}),")\n";
  # disable upgrade in BigInt, otherwise deep recursion
  local $Math::BigInt::upgrade = undef;
  my $gcd = $x->{_n}->bgcd($x->{_d});

  if (!$gcd->is_one())
    {
    $x->{_n}->bdiv($gcd);
    $x->{_d}->bdiv($gcd);
    }
#  print "$x->{_n} / $x->{_d}\n";
  $x;
  }

##############################################################################
# special values

sub _bnan
  {
  # used by parent class bone() to initialize number to 1
  my $self = shift;
  $self->{_n} = Math::BigInt->bzero();
  $self->{_d} = Math::BigInt->bzero();
  }

sub _binf
  {
  # used by parent class bone() to initialize number to 1
  my $self = shift;
  $self->{_n} = Math::BigInt->bzero();
  $self->{_d} = Math::BigInt->bzero();
  }

sub _bone
  {
  # used by parent class bone() to initialize number to 1
  my $self = shift;
  $self->{_n} = Math::BigInt->bone();
  $self->{_d} = Math::BigInt->bone();
  }

sub _bzero
  {
  # used by parent class bone() to initialize number to 1
  my $self = shift;
  $self->{_n} = Math::BigInt->bzero();
  $self->{_d} = Math::BigInt->bone();
  }

##############################################################################
# mul/add/div etc

sub badd
  {
  # add two rationales
  my ($self,$x,$y,$a,$p,$r) = objectify(2,@_);

  $x = $class->new($x) unless $x->isa($class);
  $y = $class->new($y) unless $y->isa($class);

  return $x->bnan() if ($x->{sign} eq 'NaN' || $y->{sign} eq 'NaN');

  #  1   1    gcd(3,4) = 1    1*3 + 1*4    7
  #  - + -                  = --------- = --                 
  #  4   3                      4*3       12

  my $gcd = $x->{_d}->bgcd($y->{_d});

  my $aa = $x->{_d}->copy();
  my $bb = $y->{_d}->copy(); 
  if ($gcd->is_one())
    {
    $bb->bdiv($gcd); $aa->bdiv($gcd);
    }
  $x->{_n}->bmul($bb); $x->{_n}->{sign} = $x->{sign};
  my $m = $y->{_n}->copy()->bmul($aa);
  $m->{sign} = $y->{sign};			# 2/1 - 2/1
  $x->{_n}->badd($m);

  $x->{_d}->bmul($y->{_d});

  # calculate new sign
  $x->{sign} = $x->{_n}->{sign}; $x->{_n}->{sign} = '+';

  $x->bnorm()->round($a,$p,$r);
  }

sub bsub
  {
  # subtract two rationales
  my ($self,$x,$y,$a,$p,$r) = objectify(2,@_);

  $x = $class->new($x) unless $x->isa($class);
  $y = $class->new($y) unless $y->isa($class);

  return $x->bnan() if ($x->{sign} eq 'NaN' || $y->{sign} eq 'NaN');
  # TODO: inf handling

  #  1   1    gcd(3,4) = 1    1*3 + 1*4    7
  #  - + -                  = --------- = --                 
  #  4   3                      4*3       12

  my $gcd = $x->{_d}->bgcd($y->{_d});

  my $aa = $x->{_d}->copy();
  my $bb = $y->{_d}->copy(); 
  if ($gcd->is_one())
    {
    $bb->bdiv($gcd); $aa->bdiv($gcd);
    }
  $x->{_n}->bmul($bb); $x->{_n}->{sign} = $x->{sign};
  my $m = $y->{_n}->copy()->bmul($aa);
  $m->{sign} = $y->{sign};			# 2/1 - 2/1
  $x->{_n}->bsub($m);

  $x->{_d}->bmul($y->{_d});
  
  # calculate new sign
  $x->{sign} = $x->{_n}->{sign}; $x->{_n}->{sign} = '+';

  $x->bnorm()->round($a,$p,$r);
  }

sub bmul
  {
  # multiply two rationales
  my ($self,$x,$y,$a,$p,$r) = objectify(2,@_);

  $x = $class->new($x) unless $x->isa($class);
  $y = $class->new($y) unless $y->isa($class);

  return $x->bnan() if ($x->{sign} eq 'NaN' || $y->{sign} eq 'NaN');

  # inf handling
  if (($x->{sign} =~ /^[+-]inf$/) || ($y->{sign} =~ /^[+-]inf$/))
    {
    return $x->bnan() if $x->is_zero() || $y->is_zero();
    # result will always be +-inf:
    # +inf * +/+inf => +inf, -inf * -/-inf => +inf
    # +inf * -/-inf => -inf, -inf * +/+inf => -inf
    return $x->binf() if ($x->{sign} =~ /^\+/ && $y->{sign} =~ /^\+/);
    return $x->binf() if ($x->{sign} =~ /^-/ && $y->{sign} =~ /^-/);
    return $x->binf('-');
    }

  # x== 0 # also: or y == 1 or y == -1
  return wantarray ? ($x,$self->bzero()) : $x if $x->is_zero();

  # According to Knuth, this can be optimized by doingtwice gcd (for d and n)
  # and reducing in one step)

  #  1   1    2    1
  #  - * - =  -  = -
  #  4   3    12   6
  $x->{_n}->bmul($y->{_n});
  $x->{_d}->bmul($y->{_d});

  # compute new sign
  $x->{sign} = $x->{sign} eq $y->{sign} ? '+' : '-';

  $x->bnorm()->round($a,$p,$r);
  }

sub bdiv
  {
  # (dividend: BRAT or num_str, divisor: BRAT or num_str) return
  # (BRAT,BRAT) (quo,rem) or BRAT (only rem)
  my ($self,$x,$y,$a,$p,$r) = objectify(2,@_);

  $x = $class->new($x) unless $x->isa($class);
  $y = $class->new($y) unless $y->isa($class);

  return $self->_div_inf($x,$y)
   if (($x->{sign} !~ /^[+-]$/) || ($y->{sign} !~ /^[+-]$/) || $y->is_zero());

  # x== 0 # also: or y == 1 or y == -1
  return wantarray ? ($x,$self->bzero()) : $x if $x->is_zero();

  # TODO: list context, upgrade

  # 1     1    1   3
  # -  /  - == - * -
  # 4     3    4   1
  $x->{_n}->bmul($y->{_d});
  $x->{_d}->bmul($y->{_n});

  # compute new sign 
  $x->{sign} = $x->{sign} eq $y->{sign} ? '+' : '-';

  $x->bnorm()->round($a,$p,$r);
  }

##############################################################################
# is_foo methods (the rest is inherited)

sub is_int
  {
  # return true if arg (BRAT or num_str) is an integer
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  return 1 if ($x->{sign} =~ /^[+-]$/) &&	# NaN and +-inf aren't
    $x->{_d}->is_one();				# 1e-1 => no integer
  0;
  }

sub is_zero
  {
  # return true if arg (BRAT or num_str) is zero
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  return 1 if $x->{sign} eq '+' && $x->{_n}->is_zero();
  0;
  }

sub is_one
  {
  # return true if arg (BRAT or num_str) is +1 or -1 if signis given
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  my $sign = shift || ''; $sign = '+' if $sign ne '-';
  return 1
   if ($x->{sign} eq $sign && $x->{_n}->is_one() && $x->{_d}->is_one());
  0;
  }

sub is_odd
  {
  # return true if arg (BFLOAT or num_str) is odd or false if even
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  return 1 if ($x->{sign} =~ /^[+-]$/) &&		# NaN & +-inf aren't
    ($x->{_d}->is_one() && $x->{_n}->is_odd());		# x/2 is not, but 3/1
  0;
  }

sub is_even
  {
  # return true if arg (BINT or num_str) is even or false if odd
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  return 0 if $x->{sign} !~ /^[+-]$/;			# NaN & +-inf aren't
  return 1 if ($x->{_d}->is_one()			# x/3 is never
     && $x->{_n}->is_even());				# but 4/1 is
  0;
  }

BEGIN
  {
  *objectify = \&Math::BigInt::objectify;
  }

##############################################################################
# parts() and friends

sub numerator
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);
 
  my $n = $x->{_n}->copy(); $n->{sign} = $x->{sign};
  $n;
  }

sub denominator
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  $x->{_d}->copy(); 
  }

sub parts
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  my $n = $x->{_n}->copy();
  $n->{sign} = $x->{sign};
  return ($x->{_n}->copy(),$x->{_d}->copy());
  }

sub length
  {
  return 0;
  }

sub digit
  {
  return 0;
  }

##############################################################################
# special calc routines

sub bceil
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  return $x unless $x->{sign} =~ /^[+-]$/;
  return $x if $x->{_d}->is_one();		# 22/1 => 22, 0/1 => 0

  $x->{_n}->bdiv($x->{_d});			# 22/7 => 3/1
  $x->{_d}->bone();
  $x->{_n}->binc() if $x->{sign} eq '+';	# +22/7 => 4/1
  $x;
  }

sub bfloor
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  return $x unless $x->{sign} =~ /^[+-]$/;
  return $x if $x->{_d}->is_one();		# 22/1 => 22, 0/1 => 0

  $x->{_n}->bdiv($x->{_d});			# 22/7 => 3/1
  $x->{_d}->bone();
  $x->{_n}->binc() if $x->{sign} eq '-';	# -22/7 => -4/1
  $x;
  }

sub bfac
  {
  return Math::BigRat->bnan();
  }

sub bpow
  {
  my ($self,$x,$y,@r) = objectify(2,@_);

  return $x if $x->{sign} =~ /^[+-]inf$/;       # -inf/+inf ** x
  return $x->bnan() if $x->{sign} eq $nan || $y->{sign} eq $nan;
  return $x->bone(@r) if $y->is_zero();
  return $x->round(@r) if $x->is_one() || $y->is_one();
  if ($x->{sign} eq '-' && $x->{_n}->is_one() && $x->{_d}->is_one())
    {
    # if $x == -1 and odd/even y => +1/-1
    return $y->is_odd() ? $x->round(@r) : $x->babs()->round(@r);
    # my Casio FX-5500L has a bug here: -1 ** 2 is -1, but -1 * -1 is 1;
    }
  # 1 ** -y => 1 / (1 ** |y|)
  # so do test for negative $y after above's clause
 #  return $x->bnan() if $y->{sign} eq '-';
  return $x->round(@r) if $x->is_zero();  # 0**y => 0 (if not y <= 0)

  my $pow2 = $self->__one();
  my $y1 = Math::BigInt->new($y->{_n}/$y->{_d})->babs();
  my $two = Math::BigInt->new(2);
  while (!$y1->is_one())
    {
    print "at $y1 (= $x)\n";
    $pow2->bmul($x) if $y1->is_odd();
    $y1->bdiv($two);
    $x->bmul($x);
    }
  $x->bmul($pow2) unless $pow2->is_one();
  # n ** -x => 1/n ** x
  ($x->{_d},$x->{_n}) = ($x->{_n},$x->{_d}) if $y->{sign} eq '-'; 
  $x;
  #$x->round(@r);
  }

sub blog
  {
  return Math::BigRat->bnan();
  }

sub bsqrt
  {
  my ($self,$x,$a,$p,$r) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  return $x->bnan() if $x->{sign} ne '+';	# inf, NaN, -1 etc
  $x->{_d}->bsqrt($a,$p,$r);
  $x->{_n}->bsqrt($a,$p,$r);
  $x->bnorm();
  }

sub blsft
  {
  my ($self,$x,$y,$b,$a,$p,$r) = objectify(3,@_);
 
  $x->bmul( $b->copy()->bpow($y), $a,$p,$r);
  $x;
  }

sub brsft
  {
  my ($self,$x,$y,$b,$a,$p,$r) = objectify(2,@_);

  $x->bdiv( $b->copy()->bpow($y), $a,$p,$r);
  $x;
  }

##############################################################################
# round

sub round
  {
  $_[0];
  }

sub bround
  {
  $_[0];
  }

sub bfround
  {
  $_[0];
  }

##############################################################################
# comparing

sub bcmp
  {
  my ($self,$x,$y) = objectify(2,@_);

  if (($x->{sign} !~ /^[+-]$/) || ($y->{sign} !~ /^[+-]$/))
    {
    # handle +-inf and NaN
    return undef if (($x->{sign} eq $nan) || ($y->{sign} eq $nan));
    return 0 if $x->{sign} eq $y->{sign} && $x->{sign} =~ /^[+-]inf$/;
    return +1 if $x->{sign} eq '+inf';
    return -1 if $x->{sign} eq '-inf';
    return -1 if $y->{sign} eq '+inf';
    return +1;
    }
  # check sign for speed first
  return 1 if $x->{sign} eq '+' && $y->{sign} eq '-';   # does also 0 <=> -y
  return -1 if $x->{sign} eq '-' && $y->{sign} eq '+';  # does also -x <=> 0

  # shortcut
  my $xz = $x->{_n}->is_zero();
  my $yz = $y->{_n}->is_zero();
  return 0 if $xz && $yz;                               # 0 <=> 0
  return -1 if $xz && $y->{sign} eq '+';                # 0 <=> +y
  return 1 if $yz && $x->{sign} eq '+';                 # +x <=> 0
 
  my $t = $x->{_n} * $y->{_d}; $t->{sign} = $x->{sign};
  my $u = $y->{_n} * $x->{_d}; $u->{sign} = $y->{sign};
  $t->bcmp($u);
  }

sub bacmp
  {
  my ($self,$x,$y) = objectify(2,@_);

  if (($x->{sign} !~ /^[+-]$/) || ($y->{sign} !~ /^[+-]$/))
    {
    # handle +-inf and NaN
    return undef if (($x->{sign} eq $nan) || ($y->{sign} eq $nan));
    return 0 if $x->{sign} =~ /^[+-]inf$/ && $y->{sign} =~ /^[+-]inf$/;
    return +1;  # inf is always bigger
    }

  my $t = $x->{_n} * $y->{_d};
  my $u = $y->{_n} * $x->{_d};
  $t->bacmp($u);
  }

##############################################################################
# output conversation

sub as_number
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  return $x if $x->{sign} !~ /^[+-]$/;			# NaN, inf etc 
  my $t = $x->{_n}->copy()->bdiv($x->{_d});		# 22/7 => 3
  $t->{sign} = $x->{sign};
  $t;
  }

#sub import
#  {
#  my $self = shift;
#  Math::BigInt->import(@_);
#  $self->SUPER::import(@_);                     # need it for subclasses
#  #$self->export_to_level(1,$self,@_);          # need this ?
#  }

1;

__END__

=head1 NAME

Math::BigRat - arbitrarily big rationales

=head1 SYNOPSIS

  use Math::BigRat;

  $x = Math::BigRat->new('3/7');

  print $x->bstr(),"\n";

=head1 DESCRIPTION

This is just a placeholder until the real thing is up and running. Watch this
space...

=head2 MATH LIBRARY

Math with the numbers is done (by default) by a module called
Math::BigInt::Calc. This is equivalent to saying:

	use Math::BigRat lib => 'Calc';

You can change this by using:

	use Math::BigRat lib => 'BitVect';

The following would first try to find Math::BigInt::Foo, then
Math::BigInt::Bar, and when this also fails, revert to Math::BigInt::Calc:

	use Math::BigRat lib => 'Foo,Math::BigInt::Bar';

Calc.pm uses as internal format an array of elements of some decimal base
(usually 1e7, but this might be differen for some systems) with the least
significant digit first, while BitVect.pm uses a bit vector of base 2, most
significant bit first. Other modules might use even different means of
representing the numbers. See the respective module documentation for further
details.

=head1 METHODS

=head2 new

	$x = Math::BigRat->new('1/3');

Create a new Math::BigRat object. Input can come in various forms:

	$x = Math::BigRat->new('1/3');				# simple string
	$x = Math::BigRat->new('1 / 3');			# spaced
	$x = Math::BigRat->new('1 / 0.1');			# w/ floats
	$x = Math::BigRat->new(Math::BigInt->new(3));		# BigInt
	$x = Math::BigRat->new(Math::BigFloat->new('3.1'));	# BigFloat

=head2 numerator

	$n = $x->numerator();

Returns a copy of the numerator (the part above the line) as signed BigInt.

=head2 denominator
	
	$d = $x->denominator();

Returns a copy of the denominator (the part under the line) as positive BigInt.

=head2 parts

	($n,$d) = $x->parts();

Return a list consisting of (signed) numerator and (unsigned) denominator as
BigInts.

=head1 BUGS

None know yet. Please see also L<Math::BigInt>.

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Math::BigFloat> and L<Math::Big> as well as L<Math::BigInt::BitVect>,
L<Math::BigInt::Pari> and  L<Math::BigInt::GMP>.

The package at
L<http://search.cpan.org/search?mode=module&query=Math%3A%3ABigRat> may
contain more documentation and examples as well as testcases.

=head1 AUTHORS

(C) by Tels L<http://bloodgate.com/> 2001-2002. 

=cut

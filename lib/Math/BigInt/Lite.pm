#!/usr/bin/perl -w

# For speed and simplicity, Lite objects are a reference to a scalar. When
# something more complex needs to happen (like +inf,-inf, NaN or rounding),
# they will upgrade.

package Math::BigInt::Lite;

require 5.005_02;
use strict;

use Exporter;
use Math::BigInt;
use vars qw($VERSION @ISA $PACKAGE @EXPORT_OK $upgrade $downgrade
            $accuracy $precision $round_mode $div_scale);

@ISA = qw(Exporter Math::BigInt);
my $class = 'Math::BigInt::Lite';

$VERSION = '0.09';

##############################################################################
# global constants, flags and accessory

$accuracy = $precision = undef;
$round_mode = 'even';
$div_scale = 40;
$upgrade = 'Math::BigInt';
$downgrade = undef;

my $nan = 'NaN';

my $MAX_NEW_LEN;
my $MAX_MUL;
my $MAX_ADD;

BEGIN
  {
  # from Daniel Pfeiffer: determine largest group of digits that is precisely
  # multipliable with itself plus carry
  # Test now changed to expect the proper pattern, not a result off by 1 or 2
  my ($e, $num) = 3;    # lowest value we will use is 3+1-1 = 3
  do
    {
    $num = ('9' x ++$e) + 0;
    $num *= $num + 1.0;
    } while ("$num" =~ /9{$e}0{$e}/);	# must be a certain pattern
  $e--;					# last test failed, so retract one step
  # the limits below brush the problems with the test above under the rug:
  # the test should be able to find the proper $e automatically
  $e = 5 if $^O =~ /^uts/;	# UTS get's some special treatment
  $e = 5 if $^O =~ /^unicos/;	# unicos is also problematic (6 seems to work
				# there, but we play safe)
  $e = 8 if $e > 8;		# cap, for VMS, OS/390 and other 64 bit systems

  my $bi = $e;

#  # determine how many digits fit into an integer and can be safely added
#  # together plus carry w/o causing an overflow
#
#  # this below detects 15 on a 64 bit system, because after that it becomes
#  # 1e16  and not 1000000 :/ I can make it detect 18, but then I get a lot of
#  # test failures. Ugh! (Tomake detect 18: uncomment lines marked with *)
#  use integer;
#  my $bi = 5;                   # approx. 16 bit
#  $num = int('9' x $bi);
#  # $num = 99999; # *
#  # while ( ($num+$num+1) eq '1' . '9' x $bi)   # *
#  while ( int($num+$num+1) eq '1' . '9' x $bi)
#    {
#    $bi++; $num = int('9' x $bi);
#    # $bi++; $num *= 10; $num += 9;     # *
#    }
#  $bi--;                                # back off one step

  # we ensure that every number created is below the length for the add, so
  # that it is always safe to add two objects together
  $MAX_NEW_LEN = $bi;
  # The constant below is used to check the result of any add, if above, we
  # need to upgrade.
  $MAX_ADD = int("1E$bi");
  # For mul, we need to check *before* the operation that both operands are
  # below the number benlow, since otherwise it could overflow.
  $MAX_MUL = int("1E$e");

 # print "MAX_NEW_LEN $MAX_NEW_LEN MAX_ADD $MAX_ADD MAX_MUL $MAX_MUL\n\n";
  }

##############################################################################
# we tie our accuracy/precision/round_mode to BigInt, so that setting it here
# will do it in BigInt, too. You can't use Lite w/o BigInt, anyway.

sub round_mode
  {
  no strict 'refs';
  # make Class->round_mode() work
  my $self = shift;
  my $class = ref($self) || $self || __PACKAGE__;
  if (defined $_[0])
    {
    my $m = shift;
    die "Unknown round mode $m"
     if $m !~ /^(even|odd|\+inf|\-inf|zero|trunc)$/;
    # set in BigInt, too
    Math::BigInt->round_mode($m);
    return ${"${class}::round_mode"} = $m;
    }
  return ${"${class}::round_mode"};
  }

sub accuracy
  {
  # $x->accuracy($a);           ref($x) $a
  # $x->accuracy();             ref($x)
  # Class->accuracy();          class
  # Class->accuracy($a);        class $a

  my $x = shift;
  my $class = ref($x) || $x || __PACKAGE__;

  no strict 'refs';
  # need to set new value?
  if (@_ > 0)
    {
    my $a = shift;
    die ('accuracy must not be zero') if defined $a && $a == 0;
    if (ref($x))
      {
      # $object->accuracy() or fallback to global
      $x->bround($a) if defined $a;
      $x->{_a} = $a;                    # set/overwrite, even if not rounded
      $x->{_p} = undef;                 # clear P
      }
    else
      {
      # set global
      Math::BigInt->accuracy($a);
      # and locally here	
      $accuracy = $a;
      $precision = undef; 	# clear P
      }
    return $a;                          # shortcut
    }

  if (ref($x))
    {
    # $object->accuracy() or fallback to global
    return $x->{_a} || ${"${class}::accuracy"};
    }
  return ${"${class}::accuracy"};
  }

sub precision
  {
  # $x->precision($p);          ref($x) $p
  # $x->precision();            ref($x)
  # Class->precision();         class
  # Class->precision($p);       class $p

  my $x = shift;
  my $class = ref($x) || $x || __PACKAGE__;

  no strict 'refs';
  # need to set new value?
  if (@_ > 0)
    {
    my $p = shift;
    if (ref($x))
      {
      # $object->precision() or fallback to global
      $x->bfround($p) if defined $p;
      $x->{_p} = $p;                    # set/overwrite, even if not rounded
      $x->{_a} = undef;                 # clear A
      }
    else
      {
      Math::BigInt->precision($p);
      # and locally here	
      $accuracy = undef;		# clear A
      $precision = $p;
      }
    return $p;                          # shortcut
    }

  if (ref($x))
    {
    # $object->precision() or fallback to global
    return $x->{_p} || ${"${class}::precision"};
    }
  return ${"${class}::precision"};
  }

use overload
'+'     =>
 sub 
  {
  my $x = $_[0];
  my $s = $_[1]; $s = $class->new($s) unless ref($s);
  if ($s->isa($class))
    {
    $x = \($$x + $$s); bless $x,$class;		# inline copy
    $upgrade->new($$x) if abs($$x) >= $MAX_ADD;
    }
  else
    {
    $x = $upgrade->new($$x)->badd($s);
    }
  $x;
  }, 

'*'     =>
 sub 
  {
  my $x = $_[0];
  my $s = $_[1]; $s = $class->new($s) unless ref($s);
  if ($s->isa($class))
    {
    $x = \($$x * $$s); $$x = 0 if $$x eq '-0';	# correct 5.x.x bug
    bless $x,$class;		# inline copy
    }
  else
    {
    $x = $upgrade->new(${$_[0]})->bmul($s);
    }
  }, 

# some shortcuts for speed (assumes that reversed order of arguments is routed
# to normal '+' and we thus can always modify first arg. If this is changed,
# this breaks and must be adjusted.)
#'/='    =>      sub { scalar $_[0]->bdiv($_[1]); },
#'*='    =>      sub { $_[0]->bmul($_[1]); },
#'+='    =>       sub { $_[0]->badd($_[1]); },
#'-='    =>      sub { $_[0]->bsub($_[1]); },
#'%='    =>      sub { $_[0]->bmod($_[1]); },
#'&='    =>      sub { $_[0]->band($_[1]); },
#'^='    =>      sub { $_[0]->bxor($_[1]); },
#'|='    =>      sub { $_[0]->bior($_[1]); },
#'**='   =>      sub { $upgrade->bpow($_[0],$_[1]); },

'<=>'   =>      sub { $_[2] ? bcmp($_[1],$_[0]) : bcmp($_[0],$_[1]); },

'""' 	=> 	sub { ${$_[0]}; },
'0+'	=> 	sub { ${$_[0]}; },

'++'    =>      sub { 
  ${$_[0]}++; 
  return $upgrade->new(${$_[0]}) if ${$_[0]} >= $MAX_ADD; 
  $_[0];
  },
'--'    =>      sub { 
  ${$_[0]}--; 
  return $upgrade->new(${$_[0]}) if ${$_[0]} <= -$MAX_ADD; 
  $_[0];
  }
 ;

BEGIN
  {
  *objectify = \&Math::BigInt::objectify;
  }

sub config
  {
  my $cfg = Math::BigInt->config();
  $cfg->{version_lite} = $VERSION;
  $cfg;
  }

sub bgcd
  {
  if (@_ == 1)		# bgcd (8) == bgcd(8,0) == 8
    {
    my $x = shift; $x = $class->new($x) unless ref($x);
    return $x;
    }

  my @a = ();
  foreach (@_)
    {
    my $x = $_;
    $x = $upgrade->new($x) unless ref ($x);
    $x = $upgrade->new($$x) if $x->isa($class);
    push @a, $x;
    }
  Math::BigInt::bgcd(@a);
  }

sub blcm
  {
  my @a = ();
  foreach (@_)
    {
    my $x = $_;
    $x = $upgrade->new($x) unless ref ($x);
    $x = $upgrade->new($$x) if $x->isa($class);
    push @a, $x;
    }
  Math::BigInt::blcm(@a);
  }

sub isa
  {
  return 1 if $_[1] =~ /^Math::BigInt::Lite/;		# we aren't a BigInt
							# nor BigRat/BigFloat
  return 0;
#  UNIVERSAL::isa(@_);
  }

sub new
  {
  my ($class,$wanted,@r) = @_;

  return $upgrade->new($wanted) if !defined $wanted;

  # 1e12, NaN, inf, 0x12, 0b11, 1.2e2, "12345678901234567890" etc all upgrade 
  if (!ref($wanted))
    {
    if ((length($wanted) <= $MAX_NEW_LEN) && 
        ($wanted =~ /^[+-]?[0-9]{1,$MAX_NEW_LEN}(\.0*)?$/))
      {
      my $a = \($wanted+0);	# +0 to make a copy and force it numeric
      return bless $a, $class;
      }
    # TODO: 1e10 style constants that are still below MAX_NEW
    if ($wanted =~ /^([+-])?([0-9]+)[eE][+]?([0-9]+)$/)
      {
      if ((length($2) + $3) < $MAX_NEW_LEN)
        {
        my $a = \($wanted+0);	# +0 to make a copy and force it numeric
        return bless $a, $class;
        }
      } 
#    print "new '$$a' $BASE_LEN ($wanted)\n";
    }
  $upgrade->new($wanted,@r);
  }

sub bstr
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  return $x->bstr() unless $x->isa($class);
  $$x;
  }

sub bsstr
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  $upgrade->new($$x)->bsstr();
  }

sub bnorm
  {
  # no-op
  my $x = ref($_[0]) ? $_[0] : $_[0]->new($_[1]);

#  # zap "-0" (TODO find a way to avoid this)
#  print "bnorm l $$x\n" if ref($x) eq $class;
#  print "bnorm b $x\n" if ref($x) ne $class;
#  $$x = 0 if $x->isa($class) && $$x eq '-0';	
  $x;
  }

sub _upgrade_2
  {
  # This takes the two possible arguments, and checks them. It uses new() to
  # convert literals to objects first. Then it upgrades the operation
  # when it detects that:
  # * one or both of the argument(s) is/are BigInt, 
  # * global A or P are set
  # Input arguments: x,y,a,p,r
  # Output: flag (1: need to upgrade, 0: need not),x,y,$a,$p,$r

  # Math::BigInt::Lite->badd(1,2) style calls
  shift if !ref($_[0]) && $_[0] =~ /^Math::BigInt::Lite/;

  my ($x,$y,$a,$p,$r) = @_;

  my $up = 0;	# default: don't upgrade

  $up = 1
   if (defined $a || defined $p || defined $accuracy || defined $precision);
  $x = __PACKAGE__->new($x) unless ref $x;	# upgrade literals
  $y = __PACKAGE__->new($y) unless ref $y;	# upgrade literals
  $up = 1 unless $x->isa($class) && $y->isa($class);
  # no need to check for overflow for add/sub/div/mod math
  if ($up == 1)
    {
    $x = $upgrade->new($$x) if $x->isa($class);
    $y = $upgrade->new($$y) if $y->isa($class);
    }

  ($up,$x,$y,$a,$p,$r);
  }

sub _upgrade_2_mul
  {
  # This takes the two possible arguments, and checks them. It uses new() to
  # convert literals to objects first. Then it upgrades the operation
  # when it detects that:
  # * one or both of the argument(s) is/are BigInt, 
  # * global A or P are set
  # * One of the arguments is too large for the operation 
  # Input arguments: x,y,a,p,r
  # Output: flag (1: need to upgrade, 0: need not),x,y,$a,$p,$r

  # Math::BigInt::Lite->badd(1,2) style calls
  shift if !ref($_[0]) && $_[0] =~ /^Math::BigInt::Lite/;

  my ($x,$y,$a,$p,$r) = @_;

  my $up = 0;	# default: don't upgrade

  $up = 1
   if (defined $a || defined $p || defined $accuracy || defined $precision);
  $x = __PACKAGE__->new($x) unless ref $x;	# upgrade literals
  $y = __PACKAGE__->new($y) unless ref $y;	# upgrade literals
  $up = 1 unless $x->isa($class) && $y->isa($class);
  $up = 1 if ($up == 0 && (abs($$x) >= $MAX_MUL || abs($$y) >= $MAX_MUL) );
  if ($up == 1)
    {
    $x = $upgrade->new($$x) if $x->isa($class);
    $y = $upgrade->new($$y) if $y->isa($class);
    }
  ($up,$x,$y,$a,$p,$r);
  }

sub _upgrade_1
  {
  # This takes the one possible argument, and checks it. It uses new() to
  # convert a literal to an object first. Then it checks for a necc. upgrade:
  # * the argument is a BigInt
  # * global A or P are set
  # Input arguments: x,a,p,r
  # Output: flag (1: need to upgrade, 0: need not), x,$a,$p,$r
  my ($x,$a,$p,$r) = @_;

  my $up = 0;	# default: don't upgrade

  $up = 1
   if (defined $a || defined $p || defined $accuracy || defined $precision);
  $x = __PACKAGE_->new($x) unless ref $x;	# upgrade literals
  $up = 1 unless $x->isa($class);
  if ($up == 1)
    {
    $x = $upgrade->new($$x) if $x->isa($class);
    }
  ($up,$x,$a,$p,$r);
  }

##############################################################################
# rounding functions

sub bround
  {
  my ($self,$x,$a,$m) = ref($_[0]) ? (ref($_[0]),@_) :
    ($class,$class->new($_[0]),$_[1],$_[2]);

  #$m = $self->round_mode() if !defined $m;
  #$a = $self->accuracy() if !defined $a;

  $x = $upgrade->new($$x) if $x->isa($class);
  $x->bround($a,$m);
  }

sub bfround
  {
  my ($self,$x,$p,$m) = ref($_[0]) ? (ref($_[0]),@_) :
    ($class,$class->new($_[0]),$_[1],$_[2]);

  #$m = $self->round_mode() if !defined $m;
  #$p = $self->precision() if !defined $p;

  $x = $upgrade->new($$x) if $x->isa($class);
  $x->bfround($p,$m);

  }

sub round
  {
  my ($self,$x,$a,$p,$r) = ref($_[0]) ? (ref($_[0]),@_) : 
    ($class,$class->new(@_),$_[0],$_[1],$_[2]);

  $x = $upgrade->new($$x) if $x->isa($class);
  $x->round($a,$p,$r);
  }

##############################################################################
# special values

sub bnan
  {
  # return a bnan or set object to NaN
  my $x = shift;
  
  $upgrade->bnan();
  }

sub binf
  {
  # return a binf
  my $x = shift;

#  return $upgrade->new($$x)->binf(@_) if ref $x;
  $upgrade->binf(@_);				# binf(1,'-') form
  }

sub bone
  {
  # return a one
  my $x = shift;
 
  my $sign = '+'; $sign = '-' if ($_[0] ||'') eq '-';
  return $x->new($sign.'1') unless ref $x;		# Class->bone();
  $$x = 1;
  $$x = -1 if $sign eq '-';
  $x;
  }

sub bzero
  {
  # return a one
  my $x = shift;

  return $x->new(0) unless ref $x;		# Class->bone();
  #return $x->bzero() unless $x->isa($class);	# should not happen
  $$x = 0;
  $x;
  }

sub bcmp
  {
  # compare two objects
  my ($x,$y) = @_;

  $x = $class->new($x) unless ref $x;
  $y = $class->new($y) unless ref $y;

  return ($$x <=> $$y) if ($x->isa($class) && ($y->isa($class)));
  my $x1 = $x; my $y1 = $y;
  $x1 = $upgrade->new($$x) if $x->isa($class);
  $y1 = $upgrade->new($$y) if $y->isa($class);
  $x1->bcmp($y1);		# one of them other class
  }

sub bacmp
  {
  # compare two objects
  my ($x,$y) = @_;

#  print "bacmp $x $y\n";
  $x = $class->new($x) unless ref $x;
  $y = $class->new($y) unless ref $y;
  return (abs($$x) <=> abs($$y))
   if ($x->isa($class) && ($y->isa($class)));
  my $x1 = $x; my $y1 = $y;
  $x1 = $upgrade->new($$x) if $x->isa($class);
  $y1 = $upgrade->new($$y) if $y->isa($class);
  $x1->bacmp($y1);		# one of them other class
  }

##############################################################################
# copy/conversion

sub copy
  {
  my $x = shift;
  return $class->new($x) if !ref $x;

  my $a = $$x; my $t = \$a; bless $t, $class;
  }

sub as_number
  {
  my ($x) = shift;

  return $upgrade->new($x) unless ref($x);
  # as_number needs to return a BigInt
  return $upgrade->new($$x) if $x->isa($class);
  $x->copy();
  }

sub numify
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : ($class,$class->new(@_));

  return $$x if $x->isa($class);
  $x->numify();
  }

sub as_hex
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : ($class,$class->new(@_));

  return $upgrade->new($$x)->as_hex() if $x->isa($class);
  $x->as_hex();
  }

sub as_bin
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : ($class,$class->new(@_));

  return $upgrade->new($$x)->as_bin() if $x->isa($class);
  $x->as_bin();
  }

##############################################################################
# binc/bdec

sub binc
  {
  # increment by one
  my ($up,$x,$y,$a,$p,$r) = _upgrade_1(@_);

  return $x->binc($a,$p,$r) if $up;
  $$x++;
  return $upgrade->new($$x) if abs($$x) > $MAX_ADD;
  $x;
  }

sub bdec
  {
  # decrement by one
  my ($up,$x,$y,$a,$p,$r) = _upgrade_1(@_);

  return $x->bdec($a,$p,$r) if $up;
  $$x--;
  return $upgrade->new($$x) if abs($$x) > $MAX_ADD;
  $x;
  }

##############################################################################
# shifting

sub brsft
  {
  # shift right 
  my ($x,$y,$b,$a,$p,$r) = @_; #objectify(2,@_);

  $x = $class->new($x) unless ref($x);
  $y = $class->new($x) unless ref($y);
  
  return $x->brsft($y,$b,$a,$p,$r) unless $x->isa($class);
  return $upgrade->new($$x)->brsft($y,$b,$a,$p,$r)
   unless $y->isa($class);
  
  $b = 2 if !defined $b;  
  # can't do this
  return $upgrade->new($$x)->brsft($upgrade->new($$y),$b,$a,$p,$r)
   if $b != 2 || $$y < 0;
  use integer;
  $$x = $$x >> $$y;	# base 2 for now
  $x;
  }

sub blsft
  {
  # shift left 
  my ($x,$y,$b,$a,$p,$r) = @_; #objectify(2,@_);

  $x = $class->new($x) unless ref($x);
  $y = $class->new($x) unless ref($y);

  return $x->blsft($upgrade->new($$y),$b,$a,$p,$r) unless $x->isa($class);
  return $upgrade->new($$x)->blsft($y,$b,$a,$p,$r)
   unless $y->isa($class);

  # overflow: can't do this
  return $upgrade->new($$x)->blsft($upgrade->new($$y),$b,$a,$p,$r)
   if $$y > 31;
  $b = 2 if !defined $b;  
  # can't do this
  return $upgrade->new($$x)->blsft($upgrade->new($$y),$b,$a,$p,$r)
   if $b != 2 || $$y < 0;
  use integer;
  $$x = $$x << $$y;	# base 2 for now
  $x;
  }

##############################################################################
# bitwise logical operators

sub band
  {
  # AND two objects
  my ($x,$y,$a,$p,$r) = @_; #objectify(2,@_);

  $x = $class->new($x) unless ref($x);
  $y = $class->new($x) unless ref($y);
  
  return $x->band($y,$a,$p,$r) unless $x->isa($class);
  return $upgrade->band($x,$y,$a,$p,$r) unless $y->isa($class);
  use integer;
  $$x = ($$x+0) & ($$y+0);	# +0 to avoid string-context
  $x;
  }

sub bxor
  {
  # XOR two objects
  my ($x,$y,$a,$p,$r) = @_; #objectify(2,@_);

  $x = $class->new($x) unless ref($x);
  $y = $class->new($x) unless ref($y);
  
  return $x->bxor($y,$a,$p,$r) unless $x->isa($class);
  return $upgrade->bxor($x,$y,$a,$p,$r) unless $y->isa($class);
  use integer;
  $$x = ($$x+0) ^ ($$y+0);	# +0 to avoid string-context
  $x;
  }

sub bior
  {
  # OR two objects
  my ($x,$y,$a,$p,$r) = @_; #objectify(2,@_);

  $x = $class->new($x) unless ref($x);
  $y = $class->new($x) unless ref($y);
  
  return $x->bior($y,$a,$p,$r) unless $x->isa($class);
  return $upgrade->bior($x,$y,$a,$p,$r) unless $y->isa($class);
  use integer;
  $$x = ($$x+0) | ($$y+0);	# +0 to avoid string-context
  $x;
  }

##############################################################################
# mul/add/div etc

sub badd
  {
  # add two objects
  my ($up,$x,$y,$a,$p,$r) = _upgrade_2(@_);

  return $x->badd($y,$a,$p,$r) if $up;
  
  $$x = $$x + $$y;
  return $upgrade->new($$x) if abs($$x) > $MAX_ADD;
  $x;
  }

sub bsub
  {
  # subtract two objects
  my ($up,$x,$y,$a,$p,$r) = _upgrade_2(@_);
  return $x->bsub($y,$a,$p,$r) if $up;
  $$x = $$x - $$y;
  return $upgrade->new($$x) if abs($$x) > $MAX_ADD;
  $x;
  }

sub bmul
  {
  # multiply two objects
  my ($up,$x,$y,$a,$p,$r) = _upgrade_2_mul(@_);
  return $x->bmul($y,$a,$p,$r) if $up;
  $$x = $$x * $$y;
  $$x = 0 if $$x eq '-0';	# for some Perls leave '-0' here
  #return $upgrade->new($$x) if abs($$x) > $MAX_ADD;
  $x;
  }

sub bmod
  {
  # remainder of div
  my ($up,$x,$y,$a,$p,$r) = _upgrade_2(@_);
  return $x->bmod($y,$a,$p,$r) if $up;
  return $upgrade->new($$x)->bmod($y,$a,$p,$r) if $$y == 0;
  $$x = $$x % $$y;
  $x;
  }

sub bdiv
  {
  # divide two objects
  my ($up,$x,$y,$a,$p,$r) = _upgrade_2(@_);
  
  return $x->bdiv($y,$a,$p,$r) if $up;

  return $upgrade->new($$x)->bdiv($$y,$a,$p,$r) if $$y == 0;

  # need to give Math::BigInt a chance to upgrade further
  return $upgrade->new($$x)->bdiv($$y,$a,$p,$r)
   if defined $Math::BigInt::upgrade;
  
  if (wantarray)
    {
    my $a = \($$x % $$y); bless $a,$class;	
    $$x = int($$x / $$y);
    return ($x,$a);
    }
  $$x = int($$x / $$y);
  $x;
  }

##############################################################################
# is_foo methods (the rest is inherited)

sub is_int
  {
  # return true if arg (BLite or num_str) is an integer
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  return 1 if $x->isa($class);			# Lite objects are always int
  $x->is_int();
  }

sub is_inf
  {
  # return true if arg (BLite or num_str) is an infinity
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  return 0 if $x->isa($class);			# Lite objects are never inf
  $x->is_inf();
  }

sub is_nan
  {
  # return true if arg (BLite or num_str) is an NaN
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  return 0 if $x->isa($class);			# Lite objects are never NaN
  $x->is_nan();
  }

sub is_zero
  {
  # return true if arg (BLite or num_str) is zero
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  return ($$x == 0) <=> 0if $x->isa($class);
  $x->is_zero();
  }

sub is_positive
  {
  # return true if arg (BLite or num_str) is positive
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  return ($$x >= 0) <=> 0 if $x->isa($class);
  $x->is_positive();
  }

sub is_negative
  {
  # return true if arg (BLite or num_str) is negative
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  return ($$x < 0) <=> 0 if $x->isa($class);
  $x->is_positive();
  }

sub is_one
  {
  # return true if arg (BLite or num_str) is one
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  return ($$x == 1) <=> 0 if $x->isa($class);
  $x->is_one();
  }

sub is_odd
  {
  # return true if arg (BLite or num_str) is odd
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  return $x->is_odd() unless $x->isa($class);
  $$x & 1 == 1 ? 1 : 0;
  }

sub is_even
  {
  # return true if arg (BLite or num_str) is even
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  return $x->is_even() unless $x->isa($class);
  $$x & 1 == 1 ? 0 : 1;
  }

##############################################################################
# parts() and friends

sub parts
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) :
   ($class,$class->new($_[0]));

  $x = $upgrade->new("$x") if $x->isa($class);
  return $x->parts();
  }

sub sign
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) :
    ($class,$class->new($_[0]));

  $$x >= 0 ? '+' : '-';
  }

sub exponent
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) :
    ($class,$class->new($_[0]));

  return $upgrade->new($$x)->exponent() if $x->isa($class);
  $x->exponent();
  }

sub mantissa
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) :
    ($class,$class->new($_[0]));

  return $upgrade->new($$x)->mantissa() if $x->isa($class);
  $x->mantissa();
  }

sub digit
  {
  my ($self,$x,$n) = ref($_[0]) ? (ref($_[0]),@_) : objectify(1,@_);

  return $x->digit($n) unless $x->isa($class);
  
  $n = 0 if !defined $n;
  my $len = length("$$x");

  $n = $len+$n if $n < 0;               # -1 last, -2 second-to-last
  $n = abs($n);                         # if negative was too big
  $len--; $n = $len if $n > $len;       # n to big?

  substr($$x,-$n-1,1);
  }

sub length
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  return $x->length() unless $x->isa($class);
  my $l = length($$x); $l-- if $$x < 0;		# -123 => 123
  $l;
  }

##############################################################################
# sign based methods

sub babs
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  $$x = abs($$x);
  $x;
  }

sub bneg
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  $$x = -$$x if $$x != 0;
  $x;
  }

sub bnot
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);

  $$x = -$$x - 1;
  $x;
  }

##############################################################################
# special calc routines

sub bceil
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);
  $x;		# no-op
  }

sub bfloor
  {
  my ($self,$x) = ref($_[0]) ? (ref($_[0]),$_[0]) : objectify(1,@_);
  $x;		# no-op
  }

sub bfac
  {
  my ($self,$x,$a,$p,$r) = ref($_[0]) ? (ref($_[0]),@_) :
    ($class,$class->new($_[0]),$_[1],$_[2],$_[3],$_[4]);

  $upgrade->bfac($x,$a,$p,$r);
  }

sub bpow
  {
  my ($self,$x,$y,$a,$p,$r) = objectify(2,@_);

  $x = $upgrade->new($$x) if $x->isa($class);
  $y = $upgrade->new($$y) if $y->isa($class);

  $x->bpow($y,$a,$p,$r);
  }

sub blog
  {
  my ($self,$x,$base,$a,$p,$r) = objectify(2,@_);

  $x = $upgrade->new($$x) if $x->isa($class);
  $base = $upgrade->new($$base) if $base->isa($class);

  $x->blog($base,$a,$p,$r);
  }

sub bsqrt
  {
  my ($self,$x,$a,$p,$r) = ref($_[0]) ? (ref($_[0]),@_) :
    ($class,$class->new($_[0]),$_[1],$_[2],$_[3]);

  return $x->bsqrt($a,$p,$r) unless $x->isa($class);
 
  return $upgrade->new($$x)->bsqrt() if $$x < 0;	# NaN
  my $s = sqrt($$x);
  # If MBI's upgrade is defined, and result is non-integer, we need to hand
  # up. If upgrade is undef, result would be the same, anyway
  if (int($s) != $s)
    {
    return $upgrade->new($$x)->bsqrt();
    }
  $$x = $s; $x;
  }

##############################################################################
# bgcd/blcm

sub import
  {
  my $self = shift;

  my @a = @_; my $l = scalar @_; my $j = 0;
  my $lib = '';
  for ( my $i = 0; $i < $l ; $i++,$j++ )
    {
    if ($_[$i] eq ':constant')
      {
      # this causes overlord er load to step in
      overload::constant integer => sub { $self->new(shift) };
      splice @a, $j, 1; $j --;
      }
    elsif ($_[$i] eq 'upgrade')
      {
      # this causes upgrading
      $upgrade = $_[$i+1];		# or undef to disable
      my $s = 2; $s = 1 if @a-$j < 2;	# no "can not modify non-existant..."
      splice @a, $j, $s; $j -= $s;
      }
    elsif ($_[$i] eq 'lib')
      {
      $lib = $_[$i+1];			# or undef to disable
      my $s = 2; $s = 1 if @a-$j < 2;   # no "can not modify non-existant..."
      splice @a, $j, $s; $j -= $s;
      }
    # hand this up to Math::BigInt
#    elsif ($_[$i] =~ /^lib$/i)
#      {
#      # this causes a different low lib to take care...
#      $CALC = $_[$i+1] || '';
#      my $s = 2; $s = 1 if @a-$j < 2;   # avoid "can not modify non-existant..."      splice @a, $j, $s; $j -= $s;
#      }
    }
  # any non :constant stuff is handled by our parent, Math::BigInt or Exporter
  # even if @_ is empty, to give it a chance
  $self->SUPER::import(@a);                     # need it for subclasses
  $self->export_to_level(1,$self,@a);           # need it for MBF
  }

1;

__END__

=head1 NAME

Math::BigInt::Lite - What BigInt's are before they become big

=head1 SYNOPSIS

  use Math::BigInt::Lite;

  $x = Math::BigInt::Lite->new(1);

  print $x->bstr(),"\n";			# 1
  $x = Math::BigInt::Lite->new('1e1234');
  print $x->bsstr(),"\n";			# 1e1234 (silently upgrades to
						# Math::BigInt)

=head1 DESCRIPTION

Math::BigInt is not very good suited to work with small (read: typical
less than 10 digits) numbers, since it has a quite high per-operation overhead
and is thus too slow.

But for some simple applications, you don't need rounding, infinity nor NaN
handling, and yet want fast speed for small numbers without the risk of
overflowing.

This is were Math::BigInt::Lite comes into play.

Math::BigInt::Lite objects should behave in every way like Math::BigInt
objects, that is apart from the different label, you should not be able
to tell the difference. Since Math::BigInt::Lite is designed with speed in
mind, there are certain limitations build-in. In praxis, however, you will
not feel them, because everytime something gets to big to pass as Lite
(literally), it will upgrade the objects and operation in question to
Math::BigInt.

=head2 Math library

Math with the numbers is done (by default) by a module called
Math::BigInt::Calc. This is equivalent to saying:

	use Math::BigInt::Lite lib => 'Calc';

You can change this by using:

	use Math::BigInt::Lite lib => 'BitVect';

The following would first try to find Math::BigInt::Foo, then
Math::BigInt::Bar, and when this also fails, revert to Math::BigInt::Calc:

	use Math::BigInt::Lite lib => 'Foo,Math::BigInt::Bar';

Calc.pm uses as internal format an array of elements of some decimal base
(usually 1e7, but this might be differen for some systems) with the least
significant digit first, while BitVect.pm uses a bit vector of base 2, most
significant bit first. Other modules might use even different means of
representing the numbers. See the respective module documentation for further
details.

Please note that Math::BigInt::Lite does B<not> use the denoted library itself,
but it merely passes the lib argument to Math::BigInt. So, instead of the need
to do:

	use Math::BigInt lib => 'GMP';
	use Math::BigInt::Lite;

you can roll it all into one line:

	use Math::BigInt::Lite lib => 'GMP';

Use the lib, Luke!

=head2 Using Lite as substitute for Math::BigInt

While Lite is fine when used directly in a script, you also want to make
other modules such as Math::BigFloat or Math::BigRat using it. Here is how
(you need a fairly recent version of the aforementioned modules to get this
to work!):

	# 1
        use Math::BigFloat with => 'Math::BigInt::Lite';

There is no need to "use Math::BigInt" or "use Math::BigInt::Lite", but you
can combine these if you want. For instance, you may want to use
Math::BigInt objects in your main script, too.

	# 2
	use Math::BigInt;
	use Math::BigFloat with => 'Math::BigInt::Lite';

Of course, you can combine this with the C<lib> parameter.

	# 3
	use Math::BigFloat with => 'Math::BigInt::Lite', lib => 'GMP,Pari';

If you want to use Math::BigInt's, too, simple add a Math::BigInt B<before>:

	# 4
	use Math::BigInt;
	use Math::BigFloat with => 'Math::BigInt::Lite', lib => 'GMP,Pari';

Notice that the module with the last C<lib> will "win" and thus
it's lib will be used if the lib is available:

	# 5
	use Math::BigInt lib => 'Bar,Baz';
	use Math::BigFloat with => 'Math::BigInt::Lite', lib => 'Foo';

That would try to load Foo, Bar, Baz and Calc (in that order). Or in other
words, Math::BigFloat will try to retain previously loaded libs when you
don't specify it one. 

Actually, the lib loading order would be "Bar,Baz,Calc", and then
"Foo,Bar,Baz,Calc", but independend of which lib exists, the result is the
same as trying the latter load alone, except for the fact that Bar or Baz
might be loaded needlessly in an intermidiate step

The old way still works though:

	# 6
        use Math::BigInt lib => 'Bar,Baz';
        use Math::BigFloat;
 
But B<examples #3 and #4 are recommended> for usage.

=head1 METHODS

=head2 new

	$x = Math::BigInt::Lite->new('1');

Create a new Math::BigInt:Lite object. When the input is not of an suitable
simple and small form, a C<$upgrade> object will be returned.

=head1 BUGS

None know yet. Please see also L<Math::BigInt>.

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Math::BigFloat> and L<Math::Big> as well as L<Math::BigInt::BitVect>,
L<Math::BigInt::Pari> and  L<Math::BigInt::GMP>.

The L<bignum|bignum> module.

=head1 AUTHORS

(C) by Tels L<http://bloodgate.com/> 2002. 

=cut

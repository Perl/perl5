#!/usr/bin/perl -w

# Qs: what exactly happens on numify of HUGE numbers? overflow?
#     $a = -$a is much slower (making copy of $a) than $a->bneg(), hm!?
#     (copy_on_write will help there, but that is not yet implemented)

# The following hash values are used:
#   value: unsigned int with actual value (as a Math::BigInt::Calc or similiar)
#   sign : +,-,NaN,+inf,-inf
#   _a   : accuracy
#   _p   : precision
#   _f   : flags, used by MBF to flag parts of a float as untouchable
#   _cow : copy on write: number of objects that share the data (NRY)

package Math::BigInt;
my $class = "Math::BigInt";
require 5.005;

$VERSION = 1.36;
use Exporter;
@ISA =       qw( Exporter );
@EXPORT_OK = qw( bneg babs bcmp badd bmul bdiv bmod bnorm bsub
                 bgcd blcm
		 bround 
                 blsft brsft band bior bxor bnot bpow bnan bzero 
                 bacmp bstr bsstr binc bdec bint binf bfloor bceil
                 is_odd is_even is_zero is_one is_nan is_inf sign
		 is_positive is_negative
		 length as_number
		 objectify _swap
               ); 

#@EXPORT = qw( );
use vars qw/$rnd_mode $accuracy $precision $div_scale/;
use strict;

# Inside overload, the first arg is always an object. If the original code had
# it reversed (like $x = 2 * $y), then the third paramater indicates this
# swapping. To make it work, we use a helper routine which not only reswaps the
# params, but also makes a new object in this case. See _swap() for details,
# especially the cases of operators with different classes.

# For overloaded ops with only one argument we simple use $_[0]->copy() to
# preserve the argument.

# Thus inheritance of overload operators becomes possible and transparent for
# our subclasses without the need to repeat the entire overload section there.

use overload
'='     =>      sub { $_[0]->copy(); },

# '+' and '-' do not use _swap, since it is a triffle slower. If you want to
# override _swap (if ever), then override overload of '+' and '-', too!
# for sub it is a bit tricky to keep b: b-a => -a+b
'-'	=>	sub { my $c = $_[0]->copy; $_[2] ?
                   $c->bneg()->badd($_[1]) :
                   $c->bsub( $_[1]) },
'+'	=>	sub { $_[0]->copy()->badd($_[1]); },

# some shortcuts for speed (assumes that reversed order of arguments is routed
# to normal '+' and we thus can always modify first arg. If this is changed,
# this breaks and must be adjusted.)
'+='	=>	sub { $_[0]->badd($_[1]); },
'-='	=>	sub { $_[0]->bsub($_[1]); },
'*='	=>	sub { $_[0]->bmul($_[1]); },
'/='	=>	sub { scalar $_[0]->bdiv($_[1]); },
'**='	=>	sub { $_[0]->bpow($_[1]); },

'<=>'	=>	sub { $_[2] ?
                      $class->bcmp($_[1],$_[0]) : 
                      $class->bcmp($_[0],$_[1])},
'cmp'	=>	sub { 
         $_[2] ? 
               $_[1] cmp $_[0]->bstr() :
               $_[0]->bstr() cmp $_[1] },

'int'	=>	sub { $_[0]->copy(); }, 
'neg'	=>	sub { $_[0]->copy()->bneg(); }, 
'abs'	=>	sub { $_[0]->copy()->babs(); },
'~'	=>	sub { $_[0]->copy()->bnot(); },

'*'	=>	sub { my @a = ref($_[0])->_swap(@_); $a[0]->bmul($a[1]); },
'/'	=>	sub { my @a = ref($_[0])->_swap(@_);scalar $a[0]->bdiv($a[1]);},
'%'	=>	sub { my @a = ref($_[0])->_swap(@_); $a[0]->bmod($a[1]); },
'**'	=>	sub { my @a = ref($_[0])->_swap(@_); $a[0]->bpow($a[1]); },
'<<'	=>	sub { my @a = ref($_[0])->_swap(@_); $a[0]->blsft($a[1]); },
'>>'	=>	sub { my @a = ref($_[0])->_swap(@_); $a[0]->brsft($a[1]); },

'&'	=>	sub { my @a = ref($_[0])->_swap(@_); $a[0]->band($a[1]); },
'|'	=>	sub { my @a = ref($_[0])->_swap(@_); $a[0]->bior($a[1]); },
'^'	=>	sub { my @a = ref($_[0])->_swap(@_); $a[0]->bxor($a[1]); },

# can modify arg of ++ and --, so avoid a new-copy for speed, but don't
# use $_[0]->_one(), it modifies $_[0] to be 1!
'++'	=>	sub { $_[0]->binc() },
'--'	=>	sub { $_[0]->bdec() },

# if overloaded, O(1) instead of O(N) and twice as fast for small numbers
'bool'  =>	sub {
  # this kludge is needed for perl prior 5.6.0 since returning 0 here fails :-/
  # v5.6.1 dumps on that: return !$_[0]->is_zero() || undef;		    :-(
  my $t = !$_[0]->is_zero();
  undef $t if $t == 0;
  return $t;
  },

qw(
""	bstr
0+	numify),		# Order of arguments unsignificant
;

##############################################################################
# global constants, flags and accessory

use constant MB_NEVER_ROUND => 0x0001;

my $NaNOK=1; 				# are NaNs ok?
my $nan = 'NaN'; 			# constants for easier life

my $CALC = 'Math::BigInt::Calc';	# module to do low level math
sub _core_lib () { return $CALC; }	# for test suite

# Rounding modes, one of 'even', 'odd', '+inf', '-inf', 'zero' or 'trunc'
$rnd_mode = 'even';
$accuracy = undef;
$precision = undef;
$div_scale = 40;

sub round_mode
  {
  # make Class->round_mode() work
  my $self = shift || $class;
  # shift @_ if defined $_[0] && $_[0] eq $class;
  if (defined $_[0])
    {
    my $m = shift;
    die "Unknown round mode $m"
     if $m !~ /^(even|odd|\+inf|\-inf|zero|trunc)$/;
    $rnd_mode = $m; return;
    }
  return $rnd_mode;
  }

sub accuracy
  {
  # $x->accuracy($a);		ref($x)	a
  # $x->accuracy();		ref($x);
  # Class::accuracy();		# not supported	
  #print "MBI @_ ($class)\n";
  my $x = shift;

  die ("accuracy() needs reference to object as first parameter.")
   if !ref $x;

  if (@_ > 0)
    {
    $x->{_a} = shift;
    $x->round() if defined $x->{_a};
    }
  return $x->{_a};
  } 

sub precision
  {
  my $x = shift;

  die ("precision() needs reference to object as first parameter.")
   unless ref $x;

  if (@_ > 0)
    {
    $x->{_p} = shift;
    $x->round() if defined $x->{_p};
    }
  return $x->{_p};
  } 

sub _scale_a
  { 
  # select accuracy parameter based on precedence,
  # used by bround() and bfround(), may return undef for scale (means no op)
  my ($x,$s,$m,$scale,$mode) = @_;
  $scale = $x->{_a} if !defined $scale;
  $scale = $s if (!defined $scale);
  $mode = $m if !defined $mode;
  return ($scale,$mode);
  }

sub _scale_p
  { 
  # select precision parameter based on precedence,
  # used by bround() and bfround(), may return undef for scale (means no op)
  my ($x,$s,$m,$scale,$mode) = @_;
  $scale = $x->{_p} if !defined $scale;
  $scale = $s if (!defined $scale);
  $mode = $m if !defined $mode;
  return ($scale,$mode);
  }

##############################################################################
# constructors

sub copy
  {
  my ($c,$x);
  if (@_ > 1)
    {
    # if two arguments, the first one is the class to "swallow" subclasses
    ($c,$x) = @_;
    }
  else
    {
    $x = shift;
    $c = ref($x);
    }
  return unless ref($x); # only for objects

  my $self = {}; bless $self,$c;
  foreach my $k (keys %$x)
    {
    if ($k eq 'value')
      {
      $self->{$k} = $CALC->_copy($x->{$k});
      }
    elsif (ref($x->{$k}) eq 'SCALAR')
      {
      $self->{$k} = \${$x->{$k}};
      }
    elsif (ref($x->{$k}) eq 'ARRAY')
      {
      $self->{$k} = [ @{$x->{$k}} ];
      }
    elsif (ref($x->{$k}) eq 'HASH')
      {
      # only one level deep!
      foreach my $h (keys %{$x->{$k}})
        {
        $self->{$k}->{$h} = $x->{$k}->{$h};
        }
      }
    elsif (ref($x->{$k}))
      {
      my $c = ref($x->{$k});
      $self->{$k} = $c->new($x->{$k}); # no copy() due to deep rec
      }
    else
      {
      $self->{$k} = $x->{$k};
      }
    }
  $self;
  }

sub new 
  {
  # create a new BigInt object from a string or another BigInt object. 
  # see hash keys documented at top

  # the argument could be an object, so avoid ||, && etc on it, this would
  # cause costly overloaded code to be called. The only allowed ops are
  # ref() and defined.

  my $class = shift;
 
  my $wanted = shift; # avoid numify call by not using || here
  return $class->bzero() if !defined $wanted;	# default to 0
  return $class->copy($wanted) if ref($wanted);

  my $self = {}; bless $self, $class;
  # handle '+inf', '-inf' first
  if ($wanted =~ /^[+-]inf$/)
    {
    $self->{value} = $CALC->_zero();
    $self->{sign} = $wanted;
    return $self;
    }
  # split str in m mantissa, e exponent, i integer, f fraction, v value, s sign
  my ($mis,$miv,$mfv,$es,$ev) = _split(\$wanted);
  if (ref $mis && !ref $miv)
    {
    # _from_hex or _from_bin
    $self->{value} = $mis->{value};
    $self->{sign} = $mis->{sign};
    return $self;	# throw away $mis
    }
  if (!ref $mis)
    {
    die "$wanted is not a number initialized to $class" if !$NaNOK;
    #print "NaN 1\n";
    $self->{value} = $CALC->_zero();
    $self->{sign} = $nan;
    return $self;
    }
  # make integer from mantissa by adjusting exp, then convert to bigint
  $self->{sign} = $$mis;			# store sign
  $self->{value} = $CALC->_zero();		# for all the NaN cases
  my $e = int("$$es$$ev");			# exponent (avoid recursion)
  if ($e > 0)
    {
    my $diff = $e - CORE::length($$mfv);
    if ($diff < 0)				# Not integer
      {
      #print "NOI 1\n";
      $self->{sign} = $nan;
      }
    else					# diff >= 0
      {
      # adjust fraction and add it to value
      # print "diff > 0 $$miv\n";
      $$miv = $$miv . ($$mfv . '0' x $diff);
      }
    }
  else
    {
    if ($$mfv ne '')				# e <= 0
      {
      # fraction and negative/zero E => NOI
      #print "NOI 2 \$\$mfv '$$mfv'\n";
      $self->{sign} = $nan;
      }
    elsif ($e < 0)
      {
      # xE-y, and empty mfv
      #print "xE-y\n";
      $e = abs($e);
      if ($$miv !~ s/0{$e}$//)		# can strip so many zero's?
        {
        #print "NOI 3\n";
        $self->{sign} = $nan;
        }
      }
    }
  $self->{sign} = '+' if $$miv eq '0';			# normalize -0 => +0
  $self->{value} = $CALC->_new($miv) if $self->{sign} =~ /^[+-]$/;
  #print "$wanted => $self->{sign}\n";
  # if any of the globals is set, use them to round and store them inside $self
  $self->round($accuracy,$precision,$rnd_mode)
   if defined $accuracy || defined $precision;
  return $self;
  }

# some shortcuts for easier life
sub bint
  {
  # exportable version of new
  return $class->new(@_);
  }

sub bnan
  {
  # create a bigint 'NaN', if given a BigInt, set it to 'NaN'
  my $self = shift;
  $self = $class if !defined $self;
  if (!ref($self))
    {
    my $c = $self; $self = {}; bless $self, $c;
    }
  return if $self->modify('bnan');
  $self->{value} = $CALC->_zero();
  $self->{sign} = $nan;
  return $self;
  }

sub binf
  {
  # create a bigint '+-inf', if given a BigInt, set it to '+-inf'
  # the sign is either '+', or if given, used from there
  my $self = shift;
  my $sign = shift; $sign = '+' if !defined $sign || $sign ne '-';
  $self = $class if !defined $self;
  if (!ref($self))
    {
    my $c = $self; $self = {}; bless $self, $c;
    }
  return if $self->modify('binf');
  $self->{value} = $CALC->_zero();
  $self->{sign} = $sign.'inf';
  return $self;
  }

sub bzero
  {
  # create a bigint '+0', if given a BigInt, set it to 0
  my $self = shift;
  $self = $class if !defined $self;
  #print "bzero $self\n";
 
  if (!ref($self))
    {
    my $c = $self; $self = {}; bless $self, $c;
    }
  return if $self->modify('bzero');
  $self->{value} = $CALC->_zero();
  $self->{sign} = '+';
  #print "result: $self\n";
  return $self;
  }

##############################################################################
# string conversation

sub bsstr
  {
  # (ref to BFLOAT or num_str ) return num_str
  # Convert number from internal format to scientific string format.
  # internal format is always normalized (no leading zeros, "-0E0" => "+0E0")
  my ($self,$x) = objectify(1,@_);

  return $x->{sign} if $x->{sign} !~ /^[+-]$/;
  my ($m,$e) = $x->parts();
  # can be only '+', so
  my $sign = 'e+';	
  # MBF: my $s = $e->{sign}; $s = '' if $s eq '-'; my $sep = 'e'.$s;
  return $m->bstr().$sign.$e->bstr();
  }

sub bstr 
  {
  # make a string from bigint object
  my $x = shift; $x = $class->new($x) unless ref $x;
  return $x->{sign} if $x->{sign} !~ /^[+-]$/;
  my $es = ''; $es = $x->{sign} if $x->{sign} eq '-';
  return $es.${$CALC->_str($x->{value})};
  }

sub numify 
  {
  # Make a number from a BigInt object
  my $x = shift; $x = $class->new($x) unless ref $x;
  return $x->{sign} if $x->{sign} !~ /^[+-]$/;
  my $num = $CALC->_num($x->{value});
  return -$num if $x->{sign} eq '-';
  return $num;
  }

##############################################################################
# public stuff (usually prefixed with "b")

sub sign
  {
  # return the sign of the number: +/-/NaN
  my ($self,$x) = objectify(1,@_);
  return $x->{sign};
  }

sub round
  {
  # After any operation or when calling round(), the result is rounded by
  # regarding the A & P from arguments, local parameters, or globals.
  # The result's A or P are set by the rounding, but not inspected beforehand
  # (aka only the arguments enter into it). This works because the given
  # 'first' argument is both the result and true first argument with unchanged
  # A and P settings.
  # This does not yet handle $x with A, and $y with P (which should be an
  # error).
  my $self = shift;
  my $a    = shift;	# accuracy, if given by caller
  my $p    = shift;	# precision, if given by caller
  my $r    = shift;	# round_mode, if given by caller
  my @args = @_;	# all 'other' arguments (0 for unary, 1 for binary ops)

  # leave bigfloat parts alone
  return $self if exists $self->{_f} && $self->{_f} & MB_NEVER_ROUND != 0;

  unshift @args,$self;	# add 'first' argument

  $self = new($self) unless ref($self); # if not object, make one

  # find out class of argument to round
  my $c = ref($args[0]);

  # now pick $a or $p, but only if we have got "arguments"
  if ((!defined $a) && (!defined $p) && (@args > 0))
    {
    foreach (@args)
      {
      # take the defined one, or if both defined, the one that is smaller
      $a = $_->{_a} if (defined $_->{_a}) && (!defined $a || $_->{_a} < $a);
      }
    if (!defined $a) 		# if it still is not defined, take p
      {
      foreach (@args)
        {
        # take the defined one, or if both defined, the one that is smaller
        $p = $_->{_p} if (defined $_->{_p}) && (!defined $p || $_->{_p} < $p);
        }
      # if none defined, use globals (#2)
      if (!defined $p) 
        {
        no strict 'refs';
        my $z = "$c\::accuracy"; $a = $$z;
        if (!defined $a)
          {
          $z = "$c\::precision"; $p = $$z;
          }
        }
      } # endif !$a
    } # endif !$a || !$P && args > 0
  # for clearity, this is not merged at place (#2)
  # now round, by calling fround or ffround:
  if (defined $a)
    {
    $self->{_a} = $a; $self->bround($a,$r);
    }
  elsif (defined $p)
    {
    $self->{_p} = $p; $self->bfround($p,$r);
    }
  return $self->bnorm();
  }

sub bnorm 
  { 
  # (num_str or BINT) return BINT
  # Normalize number -- no-op here
  my $self = shift;

  return $self;
  }

sub babs 
  {
  # (BINT or num_str) return BINT
  # make number absolute, or return absolute BINT from string
  #my ($self,$x) = objectify(1,@_);
  my $x = shift; $x = $class->new($x) unless ref $x;
  return $x if $x->modify('babs');
  # post-normalized abs for internal use (does nothing for NaN)
  $x->{sign} =~ s/^-/+/;
  $x;
  }

sub bneg 
  { 
  # (BINT or num_str) return BINT
  # negate number or make a negated number from string
  my ($self,$x,$a,$p,$r) = objectify(1,@_);
  return $x if $x->modify('bneg');
  # for +0 dont negate (to have always normalized)
  return $x if $x->is_zero();
  $x->{sign} =~ tr/+\-/-+/; # does nothing for NaN
  # $x->round($a,$p,$r);	# changing this makes $x - $y modify $y!!
  $x;
  }

sub bcmp 
  {
  # Compares 2 values.  Returns one of undef, <0, =0, >0. (suitable for sort)
  # (BINT or num_str, BINT or num_str) return cond_code
  my ($self,$x,$y) = objectify(2,@_);

  if (($x->{sign} !~ /^[+-]$/) || ($y->{sign} !~ /^[+-]$/))
    {
    # handle +-inf and NaN
    return undef if (($x->{sign} eq $nan) || ($y->{sign} eq $nan));
    return 0 if ($x->{sign} eq $y->{sign}) && ($x->{sign} =~ /^[+-]inf$/);
    return +1 if $x->{sign} eq '+inf';
    return -1 if $x->{sign} eq '-inf';
    return -1 if $y->{sign} eq '+inf';
    return +1 if $y->{sign} eq '-inf';
    }
  # normal compare now
  &cmp($x->{value},$y->{value},$x->{sign},$y->{sign}) <=> 0;
  }

sub bacmp 
  {
  # Compares 2 values, ignoring their signs. 
  # Returns one of undef, <0, =0, >0. (suitable for sort)
  # (BINT, BINT) return cond_code
  my ($self,$x,$y) = objectify(2,@_);
  return undef if (($x->{sign} eq $nan) || ($y->{sign} eq $nan));
  #acmp($x->{value},$y->{value}) <=> 0;
  $CALC->_acmp($x->{value},$y->{value}) <=> 0;
  }

sub badd 
  {
  # add second arg (BINT or string) to first (BINT) (modifies first)
  # return result as BINT
  my ($self,$x,$y,$a,$p,$r) = objectify(2,@_);

  return $x if $x->modify('badd');
  return $x->bnan() if (($x->{sign} !~ /^[+-]$/) || ($y->{sign} !~ /^[+-]$/));

  my @bn = ($a,$p,$r,$y); 			# make array for round calls
  # speed: no add for 0+y or x+0
  return $x->round(@bn) if $y->is_zero();			# x+0
  if ($x->is_zero())						# 0+y
    {
    # make copy, clobbering up x
    $x->{value} = $CALC->_copy($y->{value});
    #$x->{value} = [ @{$y->{value}} ];
    $x->{sign} = $y->{sign} || $nan;
    return $x->round(@bn);
    }

  # shortcuts
  my $xv = $x->{value};
  my $yv = $y->{value};
  my ($sx, $sy) = ( $x->{sign}, $y->{sign} ); # get signs

  if ($sx eq $sy)  
    {
    $CALC->_add($xv,$yv);		# if same sign, absolute add
    $x->{sign} = $sx;
    }
  else 
    {
    my $a = $CALC->_acmp ($yv,$xv);	# absolute compare
    if ($a > 0)                           
      {
      #print "swapped sub (a=$a)\n";
      $CALC->_sub($yv,$xv,1);		# absolute sub w/ swapped params
      $x->{sign} = $sy;
      } 
    elsif ($a == 0)
      {
      # speedup, if equal, set result to 0
      #print "equal sub, result = 0\n";
      $x->{value} = $CALC->_zero();
      $x->{sign} = '+';
      }
    else # a < 0
      {
      #print "unswapped sub (a=$a)\n";
      $CALC->_sub($xv, $yv);		# absolute sub
      $x->{sign} = $sx;
      }
    }
  return $x->round(@bn);
  }

sub bsub 
  {
  # (BINT or num_str, BINT or num_str) return num_str
  # subtract second arg from first, modify first
  my ($self,$x,$y,$a,$p,$r) = objectify(2,@_);

  return $x if $x->modify('bsub');
  $x->badd($y->bneg()); # badd does not leave internal zeros
  $y->bneg();           # refix y, assumes no one reads $y in between
  return $x->round($a,$p,$r,$y);
  }

sub binc
  {
  # increment arg by one
  my ($self,$x,$a,$p,$r) = objectify(1,@_);
  # my $x = shift; $x = $class->new($x) unless ref $x; my $self = ref($x);
  return $x if $x->modify('binc');
  $x->badd($self->_one())->round($a,$p,$r);
  }

sub bdec
  {
  # decrement arg by one
  my ($self,$x,$a,$p,$r) = objectify(1,@_);
  return $x if $x->modify('bdec');
  $x->badd($self->_one('-'))->round($a,$p,$r);
  } 

sub blcm 
  { 
  # (BINT or num_str, BINT or num_str) return BINT
  # does not modify arguments, but returns new object
  # Lowest Common Multiplicator

  my $y = shift; my ($x);
  if (ref($y))
    {
    $x = $y->copy();
    }
  else
    {
    $x = $class->new($y);
    }
  while (@_) { $x = _lcm($x,shift); } 
  $x;
  }

sub bgcd 
  { 
  # (BINT or num_str, BINT or num_str) return BINT
  # does not modify arguments, but returns new object
  # GCD -- Euclids algorithm, variant C (Knuth Vol 3, pg 341 ff)

  my $y = shift; my ($x);
  if (ref($y))
    {
    $x = $y->copy();
    }
  else
    {
    $x = $class->new($y);
    }

  if ($CALC->can('_gcd'))
    {
    while (@_)
      {
      $y = shift; $y = $class->new($y) if !ref($y);
      next if $y->is_zero();
      return $x->bnan() if $y->{sign} !~ /^[+-]$/;	# y NaN?
      $x->{value} = $CALC->_gcd($x->{value},$y->{value}); last if $x->is_one();
      }
    }
  else
    {
    while (@_)
      {
      $x = _gcd($x,shift); last if $x->is_one();	# _gcd handles NaN
      } 
    }
  $x->babs();
  }

sub bmod 
  {
  # modulus
  # (BINT or num_str, BINT or num_str) return BINT
  my ($self,$x,$y) = objectify(2,@_);
  
  return $x if $x->modify('bmod');
  (&bdiv($self,$x,$y))[1];
  }

sub bnot 
  {
  # (num_str or BINT) return BINT
  # represent ~x as twos-complement number
  my ($self,$x) = objectify(1,@_);
  return $x if $x->modify('bnot');
  $x->bneg(); $x->bdec(); # was: bsub(-1,$x);, time it someday
  $x;
  }

sub is_zero
  {
  # return true if arg (BINT or num_str) is zero (array '+', '0')
  #my ($self,$x) = objectify(1,@_);
  my $x = shift; $x = $class->new($x) unless ref $x;
  
  return 0 if $x->{sign} !~ /^[+-]$/;
  return $CALC->_is_zero($x->{value});
  #return (@{$x->{value}} == 1) && ($x->{sign} eq '+') 
  # && ($x->{value}->[0] == 0); 
  }

sub is_nan
  {
  # return true if arg (BINT or num_str) is NaN
  #my ($self,$x) = objectify(1,@_);
  my $x = shift; $x = $class->new($x) unless ref $x;
  return ($x->{sign} eq $nan); 
  }

sub is_inf
  {
  # return true if arg (BINT or num_str) is +-inf
  #my ($self,$x) = objectify(1,@_);
  my $x = shift; $x = $class->new($x) unless ref $x;
  my $sign = shift || '';

  return $x->{sign} =~ /^[+-]inf$/ if $sign eq '';
  return $x->{sign} =~ /^[$sign]inf$/;
  }

sub is_one
  {
  # return true if arg (BINT or num_str) is +1
  # or -1 if sign is given
  #my ($self,$x) = objectify(1,@_); 
  my $x = shift; $x = $class->new($x) unless ref $x;
  my $sign = shift || '+';
 
  # catch also NaN, +inf, -inf
  return 0 if $x->{sign} ne $sign || $x->{sign} !~ /^[+-]$/;
  return $CALC->_is_one($x->{value});
  #return (@{$x->{value}} == 1) && ($x->{sign} eq $sign) 
  # && ($x->{value}->[0] == 1); 
  }

sub is_odd
  {
  # return true when arg (BINT or num_str) is odd, false for even
  my $x = shift; $x = $class->new($x) unless ref $x;
  #my ($self,$x) = objectify(1,@_);

  return 0 if $x->{sign} !~ /^[+-]$/;			# NaN & +-inf aren't
  return $CALC->_is_odd($x->{value});
  #return (($x->{sign} ne $nan) && ($x->{value}->[0] & 1));
  }

sub is_even
  {
  # return true when arg (BINT or num_str) is even, false for odd
  my $x = shift; $x = $class->new($x) unless ref $x;
  #my ($self,$x) = objectify(1,@_);

  return 0 if $x->{sign} !~ /^[+-]$/;			# NaN & +-inf aren't
  return $CALC->_is_even($x->{value});
  #return (($x->{sign} ne $nan) && (!($x->{value}->[0] & 1)));
  #return (($x->{sign} !~ /^[+-]$/) && ($CALC->_is_even($x->{value})));
  }

sub is_positive
  {
  # return true when arg (BINT or num_str) is positive (>= 0)
  my $x = shift; $x = $class->new($x) unless ref $x;
  return ($x->{sign} =~ /^\+/);
  }

sub is_negative
  {
  # return true when arg (BINT or num_str) is negative (< 0)
  my $x = shift; $x = $class->new($x) unless ref $x;
  return ($x->{sign} =~ /^-/);
  }

###############################################################################

sub bmul 
  { 
  # multiply two numbers -- stolen from Knuth Vol 2 pg 233
  # (BINT or num_str, BINT or num_str) return BINT
  my ($self,$x,$y,$a,$p,$r) = objectify(2,@_);
  
  return $x if $x->modify('bmul');
  return $x->bnan() if (($x->{sign} !~ /^[+-]$/) || ($y->{sign} !~ /^[+-]$/));

  return $x->bzero() if $x->is_zero() || $y->is_zero();	# handle result = 0
  $x->{sign} = $x->{sign} eq $y->{sign} ? '+' : '-'; # +1 * +1 or -1 * -1 => +
  $CALC->_mul($x->{value},$y->{value});  # do actual math
  return $x->round($a,$p,$r,$y);
  }

sub bdiv 
  {
  # (dividend: BINT or num_str, divisor: BINT or num_str) return 
  # (BINT,BINT) (quo,rem) or BINT (only rem)
  my ($self,$x,$y,$a,$p,$r) = objectify(2,@_);

  return $x if $x->modify('bdiv');

  # 5 / 0 => +inf, -6 / 0 => -inf (0 / 0 => 1 or +inf or NaN?)
  #return wantarray 
  # ? ($x->binf($x->{sign}),binf($x->{sign})) : $x->binf($x->{sign})
  # if ($x->{sign} =~ /^[+-]$/ && $y->is_zero());
  
  # NaN?
  return wantarray ? ($x->bnan(),bnan()) : $x->bnan()
   if ($x->{sign} !~ /^[+-]$/ || $y->{sign} !~ /^[+-]$/ || $y->is_zero());

  # 0 / something
  return wantarray ? ($x,$self->bzero()) : $x if $x->is_zero();
 
  # Is $x in the interval [0, $y) ?
  my $cmp = $CALC->_acmp($x->{value},$y->{value});
  if (($cmp < 0) and ($x->{sign} eq $y->{sign}))
    {
    return $x->bzero() unless wantarray;
    my $t = $x->copy();      # make copy first, because $x->bzero() clobbers $x
    return ($x->bzero(),$t);
    }
  elsif ($cmp == 0)
    {
    # shortcut, both are the same, so set to +/- 1
    $x->_one( ($x->{sign} ne $y->{sign} ? '-' : '+') ); 
    return $x unless wantarray;
    return ($x,$self->bzero());
    }
   
  # calc new sign and in case $y == +/- 1, return $x
  $x->{sign} = ($x->{sign} ne $y->{sign} ? '-' : '+'); 
  # check for / +-1 (cant use $y->is_one due to '-'
  if (($y == 1) || ($y == -1))	# slow!
  #if ((@{$y->{value}} == 1) && ($y->{value}->[0] == 1))
    {
    return wantarray ? ($x,$self->bzero()) : $x; 
    }

  # call div here 
  my $rem = $self->bzero(); 
  $rem->{sign} = $y->{sign};
  #($x->{value},$rem->{value}) = div($x->{value},$y->{value});
  ($x->{value},$rem->{value}) = $CALC->_div($x->{value},$y->{value});
  # do not leave rest "-0";
  # $rem->{sign} = '+' if (@{$rem->{value}} == 1) && ($rem->{value}->[0] == 0);
  $rem->{sign} = '+' if $CALC->_is_zero($rem->{value});
  if (($x->{sign} eq '-') and (!$rem->is_zero()))
    {
    $x->bdec();
    }
  $x->round($a,$p,$r,$y); 
  if (wantarray)
    {
    $rem->round($a,$p,$r,$x,$y); 
    return ($x,$y-$rem) if $x->{sign} eq '-';	# was $x,$rem
    return ($x,$rem);
    }
  return $x; 
  }

sub bpow 
  {
  # (BINT or num_str, BINT or num_str) return BINT
  # compute power of two numbers -- stolen from Knuth Vol 2 pg 233
  # modifies first argument
  my ($self,$x,$y,$a,$p,$r) = objectify(2,@_);

  return $x if $x->modify('bpow');
 
  return $x if $x->{sign} =~ /^[+-]inf$/;	# -inf/+inf ** x
  return $x->bnan() if $x->{sign} eq $nan || $y->{sign} eq $nan;
  return $x->_one() if $y->is_zero();
  return $x         if $x->is_one() || $y->is_one();
  #if ($x->{sign} eq '-' && @{$x->{value}} == 1 && $x->{value}->[0] == 1)
  if ($x->{sign} eq '-' && $CALC->_is_one($x->{value}))
    {
    # if $x == -1 and odd/even y => +1/-1
    return $y->is_odd() ? $x : $x->babs();
    # my Casio FX-5500L has a bug here: -1 ** 2 is -1, but -1 * -1 is 1; LOL
    }
  # 1 ** -y => 1 / (1**y), so do test for negative $y after above's clause
  return $x->bnan() if $y->{sign} eq '-';
  return $x         if $x->is_zero();  # 0**y => 0 (if not y <= 0)

  if ($CALC->can('_pow'))
    {
    $CALC->_pow($x->{value},$y->{value});
    return $x->round($a,$p,$r);
    }
  # based on the assumption that shifting in base 10 is fast, and that mul
  # works faster if numbers are small: we count trailing zeros (this step is
  # O(1)..O(N), but in case of O(N) we save much more time due to this),
  # stripping them out of the multiplication, and add $count * $y zeros
  # afterwards like this:
  # 300 ** 3 == 300*300*300 == 3*3*3 . '0' x 2 * 3 == 27 . '0' x 6
  # creates deep recursion?
  #my $zeros = $x->_trailing_zeros();
  #if ($zeros > 0)
  #  {
  #  $x->brsft($zeros,10);	# remove zeros
  #  $x->bpow($y);		# recursion (will not branch into here again)
  #  $zeros = $y * $zeros; 	# real number of zeros to add
  #  $x->blsft($zeros,10);
  #  return $x->round($a,$p,$r);
  #  }

  my $pow2 = $self->_one();
  my $y1 = $class->new($y);
  my ($res);
  while (!$y1->is_one())
    {
    #print "bpow: p2: $pow2 x: $x y: $y1 r: $res\n";
    #print "len ",$x->length(),"\n";
    ($y1,$res)=&bdiv($y1,2);
    if (!$res->is_zero()) { &bmul($pow2,$x); }
    if (!$y1->is_zero())  { &bmul($x,$x); }
    #print "$x $y\n";
    }
  #print "bpow: e p2: $pow2 x: $x y: $y1 r: $res\n";
  &bmul($x,$pow2) if (!$pow2->is_one());
  #print "bpow: e p2: $pow2 x: $x y: $y1 r: $res\n";
  return $x->round($a,$p,$r);
  }

sub blsft 
  {
  # (BINT or num_str, BINT or num_str) return BINT
  # compute x << y, base n, y >= 0
  my ($self,$x,$y,$n) = objectify(2,@_);
  
  return $x if $x->modify('blsft');
  return $x->bnan() if ($x->{sign} !~ /^[+-]$/ || $y->{sign} !~ /^[+-]$/);

  $n = 2 if !defined $n; return $x if $n == 0;
  return $x->bnan() if $n < 0 || $y->{sign} eq '-';
  #if ($n != 10)
  #  {
    $x->bmul( $self->bpow($n, $y) );
  #  }
  #else
  #  { 
  #  # shortcut (faster) for shifting by 10) since we are in base 10eX
  #  # multiples of 5:
  #  my $src = scalar @{$x->{value}};		# source
  #  my $len = $y->numify();			# shift-len as normal int
  #  my $rem = $len % 5;				# reminder to shift
  #  my $dst = $src + int($len/5);		# destination
  #  
  #  my $v = $x->{value};			# speed-up
  #  my $vd;					# further speedup
  #  #print "src $src:",$v->[$src]||0," dst $dst:",$v->[$dst]||0," rem $rem\n";
  #  $v->[$src] = 0;				# avoid first ||0 for speed
  #  while ($src >= 0)
  #    {
  #    $vd = $v->[$src]; $vd = '00000'.$vd;
  #    #print "s $src d $dst '$vd' ";
  #    $vd = substr($vd,-5+$rem,5-$rem);
  #    #print "'$vd' ";
  #    $vd .= $src > 0 ? substr('00000'.$v->[$src-1],-5,$rem) : '0' x $rem;
  #    #print "'$vd' ";
  #    $vd = substr($vd,-5,5) if length($vd) > 5;
  #    #print "'$vd'\n";
  #    $v->[$dst] = int($vd);
  #    $dst--; $src--; 
  #    }
  #  # set lowest parts to 0
  #  while ($dst >= 0) { $v->[$dst--] = 0; }
  #  # fix spurios last zero element
  #  splice @$v,-1 if $v->[-1] == 0;
  #  #print "elems: "; my $i = 0;
  #  #foreach (reverse @$v) { print "$i $_ "; $i++; } print "\n";
  #  # old way: $x->bmul( $self->bpow($n, $y) );
  #  }
  return $x;
  }

sub brsft 
  {
  # (BINT or num_str, BINT or num_str) return BINT
  # compute x >> y, base n, y >= 0
  my ($self,$x,$y,$n) = objectify(2,@_);

  return $x if $x->modify('brsft');
  return $x->bnan() if ($x->{sign} !~ /^[+-]$/ || $y->{sign} !~ /^[+-]$/);

  $n = 2 if !defined $n; return $x->bnan() if $n <= 0 || $y->{sign} eq '-';
  #if ($n != 10)
  #  {
    scalar bdiv($x, $self->bpow($n, $y));
  #  }
  #else
  #  { 
  #  # shortcut (faster) for shifting by 10)
  #  # multiples of 5:
  #  my $dst = 0;				# destination
  #  my $src = $y->numify();			# as normal int
  #  my $rem = $src % 5;				# reminder to shift	
  #  $src = int($src / 5);			# source
  #  my $len = scalar @{$x->{value}} - $src;	# elems to go
  #  my $v = $x->{value};			# speed-up
  #  if ($rem == 0)
  #    {
  #    splice (@$v,0,$src);			# even faster, 38.4 => 39.3
  #    }
  #  else
  #    {
  #    my $vd;
  #    $v->[scalar @$v] = 0;			# avoid || 0 test inside loop
  #    while ($dst < $len)
  #      {
  #      $vd = '00000'.$v->[$src];
  #      #print "$dst $src '$vd' ";
  #      $vd = substr($vd,-5,5-$rem);
  #      #print "'$vd' ";
  #      $src++; 
  #      $vd = substr('00000'.$v->[$src],-$rem,$rem) . $vd;
  #      #print "'$vd1' ";
  #      #print "'$vd'\n";
  #      $vd = substr($vd,-5,5) if length($vd) > 5;
  #      $v->[$dst] = int($vd);
  #      $dst++; 
  #      }
  #    splice (@$v,$dst) if $dst > 0;		# kill left-over array elems
  #    pop @$v if $v->[-1] == 0;			# kill last element
  #    } # else rem == 0
  #  # old way: scalar bdiv($x, $self->bpow($n, $y));
  #  }
  return $x;
  }

sub band 
  {
  #(BINT or num_str, BINT or num_str) return BINT
  # compute x & y
  my ($self,$x,$y,$a,$p,$r) = objectify(2,@_);
  
  return $x if $x->modify('band');

  return $x->bnan() if ($x->{sign} !~ /^[+-]$/ || $y->{sign} !~ /^[+-]$/);
  return $x->bzero() if $y->is_zero();

  if ($CALC->can('_and'))
    {
    $CALC->_and($x->{value},$y->{value});
    return $x->round($a,$p,$r);
    }
  
  my $m = new Math::BigInt 1; my ($xr,$yr);
  my $x10000 = new Math::BigInt (0x10000);
  my $y1 = copy(ref($x),$y);		 		# make copy
  my $x1 = $x->copy(); $x->bzero();		# modify x in place!
  while (!$x1->is_zero() && !$y1->is_zero())
    {
    ($x1, $xr) = bdiv($x1, $x10000);
    ($y1, $yr) = bdiv($y1, $x10000);
    #print ref($xr), " $xr ", $xr->numify(),"\n";
    #print ref($yr), " $yr ", $yr->numify(),"\n";
    #print "res: ",$yr->numify() & $xr->numify(),"\n";
    my $u = bmul( $class->new( $xr->numify() & $yr->numify() ), $m);
    #print "res: $u\n";
    $x->badd( bmul( $class->new( $xr->numify() & $yr->numify() ), $m));
    $m->bmul($x10000);
    }
  return $x->round($a,$p,$r);
  }

sub bior 
  {
  #(BINT or num_str, BINT or num_str) return BINT
  # compute x | y
  my ($self,$x,$y,$a,$p,$r) = objectify(2,@_);

  return $x if $x->modify('bior');

  return $x->bnan() if ($x->{sign} !~ /^[+-]$/ || $y->{sign} !~ /^[+-]$/);
  return $x if $y->is_zero();
  if ($CALC->can('_or'))
    {
    $CALC->_or($x->{value},$y->{value});
    return $x->round($a,$p,$r);
    }

  my $m = new Math::BigInt 1; my ($xr,$yr);
  my $x10000 = new Math::BigInt (0x10000);
  my $y1 = copy(ref($x),$y);		 		# make copy
  my $x1 = $x->copy(); $x->bzero();		# modify x in place!
  while (!$x1->is_zero() || !$y1->is_zero())
    {
    ($x1, $xr) = bdiv($x1,$x10000);
    ($y1, $yr) = bdiv($y1,$x10000);
    $x->badd( bmul( $class->new( $xr->numify() | $yr->numify() ), $m));
    $m->bmul($x10000);
    }
  return $x->round($a,$p,$r);
  }

sub bxor 
  {
  #(BINT or num_str, BINT or num_str) return BINT
  # compute x ^ y
  my ($self,$x,$y,$a,$p,$r) = objectify(2,@_);

  return $x if $x->modify('bxor');

  return $x->bnan() if ($x->{sign} !~ /^[+-]$/ || $y->{sign} !~ /^[+-]$/);
  return $x if $y->is_zero();
  return $x->bzero() if $x == $y; # shortcut
  
  if ($CALC->can('_xor'))
    {
    $CALC->_xor($x->{value},$y->{value});
    return $x->round($a,$p,$r);
    }

  my $m = new Math::BigInt 1; my ($xr,$yr);
  my $x10000 = new Math::BigInt (0x10000);
  my $y1 = copy(ref($x),$y);	 		# make copy
  my $x1 = $x->copy(); $x->bzero();		# modify x in place!
  while (!$x1->is_zero() || !$y1->is_zero())
    {
    ($x1, $xr) = bdiv($x1, $x10000);
    ($y1, $yr) = bdiv($y1, $x10000);
    $x->badd( bmul( $class->new( $xr->numify() ^ $yr->numify() ), $m));
    $m->bmul($x10000);
    }
  return $x->round($a,$p,$r);
  }

sub length
  {
  my ($self,$x) = objectify(1,@_);

  my $e = $CALC->_len($x->{value}); 
  #  # fallback, since we do not know the underlying representation
  #my $es = "$x"; my $c = 0; $c = 1 if $es =~ /^[+-]/;	# if lib returns '+123'
  #my $e = CORE::length($es)-$c;
  return wantarray ? ($e,0) : $e;
  }

sub digit
  {
  # return the nth decimal digit, negative values count backward, 0 is right
  my $x = shift;
  my $n = shift || 0; 

  return $CALC->_digit($x->{value},$n);
  }

sub _trailing_zeros
  {
  # return the amount of trailing zeros in $x
  my $x = shift;
  $x = $class->new($x) unless ref $x;

  return 0 if $x->is_zero() || $x->is_nan() || $x->is_inf();

  return $CALC->_zeros($x->{value}) if $CALC->can('_zeros');

  # if not: since we do not know underlying internal representation:
  my $es = "$x"; $es =~ /([0]*)$/;
 
  return 0 if !defined $1;	# no zeros
  return CORE::length("$1");	# as string, not as +0!
  }

sub bsqrt
  {
  my ($self,$x) = objectify(1,@_);

  return $x->bnan() if $x->{sign} =~ /\-|$nan/;	# -x or NaN => NaN
  return $x->bzero() if $x->is_zero();		# 0 => 0
  return $x if $x == 1;				# 1 => 1

  my $y = $x->copy();				# give us one more digit accur.
  my $l = int($x->length()/2);
  
  $x->bzero(); 
  $x->binc();		# keep ref($x), but modify it
  $x *= 10 ** $l;

  # print "x: $y guess $x\n";

  my $last = $self->bzero();
  while ($last != $x)
    {
    $last = $x; 
    $x += $y / $x; 
    $x /= 2;
    }
  return $x;
  }

sub exponent
  {
  # return a copy of the exponent (here always 0, NaN or 1 for $m == 0)
  my ($self,$x) = objectify(1,@_);
 
  return bnan() if $x->is_nan();
  my $e = $class->bzero();
  return $e->binc() if $x->is_zero();
  $e += $x->_trailing_zeros();
  return $e;
  }

sub mantissa
  {
  # return a copy of the mantissa (here always $self)
  my ($self,$x) = objectify(1,@_);

  return bnan() if $x->is_nan();
  my $m = $x->copy();
  # that's inefficient
  my $zeros = $m->_trailing_zeros();
  $m /= 10 ** $zeros if $zeros != 0;
  return $m;
  }

sub parts
  {
  # return a copy of both the exponent and the mantissa (here 0 and self)
  my $self = shift;
  $self = $class->new($self) unless ref $self;

  return ($self->mantissa(),$self->exponent());
  }
   
##############################################################################
# rounding functions

sub bfround
  {
  # precision: round to the $Nth digit left (+$n) or right (-$n) from the '.'
  # $n == 0 => round to integer
  my $x = shift; $x = $class->new($x) unless ref $x;
  my ($scale,$mode) = $x->_scale_p($precision,$rnd_mode,@_);
  return $x if !defined $scale;		# no-op

  # no-op for BigInts if $n <= 0
  return $x if $scale <= 0;

  $x->bround( $x->length()-$scale, $mode);
  }

sub _scan_for_nonzero
  {
  my $x = shift;
  my $pad = shift;
  my $xs = shift;
 
  my $len = $x->length();
  return 0 if $len == 1;		# '5' is trailed by invisible zeros
  my $follow = $pad - 1;
  return 0 if $follow > $len || $follow < 1;
  #print "checking $x $r\n";

  # since we do not know underlying represention of $x, use decimal string
  #my $r = substr ($$xs,-$follow);
  my $r = substr ("$x",-$follow);
  return 1 if $r =~ /[^0]/; return 0;
  }

sub fround
  {
  # to make life easier for switch between MBF and MBI (autoload fxxx()
  # like MBF does for bxxx()?)
  my $x = shift;
  return $x->bround(@_);
  }

sub bround
  {
  # accuracy: +$n preserve $n digits from left,
  #           -$n preserve $n digits from right (f.i. for 0.1234 style in MBF)
  # no-op for $n == 0
  # and overwrite the rest with 0's, return normalized number
  # do not return $x->bnorm(), but $x
  my $x = shift; $x = $class->new($x) unless ref $x;
  my ($scale,$mode) = $x->_scale_a($accuracy,$rnd_mode,@_);
  return $x if !defined $scale;		# no-op
  
  # print "MBI round: $x to $scale $mode\n";
  # -scale means what? tom? hullo? -$scale needed by MBF round, but what for?
  return $x if $x->is_nan() || $x->is_zero() || $scale == 0;

  # we have fewer digits than we want to scale to
  my $len = $x->length();
  # print "$len $scale\n";
  return $x if $len < abs($scale);
   
  # count of 0's to pad, from left (+) or right (-): 9 - +6 => 3, or |-6| => 6
  my ($pad,$digit_round,$digit_after);
  $pad = $len - $scale;
  $pad = abs($scale)+1 if $scale < 0;
  # do not use digit(), it is costly for binary => decimal
  #$digit_round = '0'; $digit_round = $x->digit($pad) if $pad < $len;
  #$digit_after = '0'; $digit_after = $x->digit($pad-1) if $pad > 0;
  my $xs = $CALC->_str($x->{value});
  my $pl = -$pad-1;
  # pad:   123: 0 => -1, at 1 => -2, at 2 => -3, at 3 => -4
  # pad+1: 123: 0 => 0,  at 1 => -1, at 2 => -2, at 3 => -3
  $digit_round = '0'; $digit_round = substr($$xs,$pl,1) if $pad <= $len;
  $pl++; $pl ++ if $pad >= $len;
  $digit_after = '0'; $digit_after = substr($$xs,$pl,1)
   if $pad > 0;
  
  #my $d_round = '0'; $d_round = $x->digit($pad) if $pad < $len;
  #my $d_after = '0'; $d_after = $x->digit($pad-1) if $pad > 0;
  # print "$pad $pl $$xs $digit_round:$d_round $digit_after:$d_after\n";

  # in case of 01234 we round down, for 6789 up, and only in case 5 we look
  # closer at the remaining digits of the original $x, remember decision
  my $round_up = 1;					# default round up
  $round_up -- if
    ($mode eq 'trunc')				||	# trunc by round down
    ($digit_after =~ /[01234]/)			|| 	# round down anyway,
							# 6789 => round up
    ($digit_after eq '5')			&&	# not 5000...0000
    ($x->_scan_for_nonzero($pad,$xs) == 0)		&&
    (
     ($mode eq 'even') && ($digit_round =~ /[24680]/) ||
     ($mode eq 'odd')  && ($digit_round =~ /[13579]/) ||
     ($mode eq '+inf') && ($x->{sign} eq '-')   ||
     ($mode eq '-inf') && ($x->{sign} eq '+')   ||
     ($mode eq 'zero')		# round down if zero, sign adjusted below
    );
  # allow rounding one place left of mantissa
  #print "$pad $len $scale\n";
  # this is triggering warnings, and buggy for $scale < 0
  #if (-$scale != $len)
    {
    # old code, depend on internal representation
    # split mantissa at $pad and then pad with zeros
    #my $s5 = int($pad / 5);
    #my $i = 0;
    #while ($i < $s5)
    #  {
    #  $x->{value}->[$i++] = 0;				# replace with 5 x 0
    #  }
    #$x->{value}->[$s5] = '00000'.$x->{value}->[$s5];	# pad with 0
    #my $rem = $pad % 5;				# so much left over
    #if ($rem > 0)
    #  {
    #  #print "remainder $rem\n";
    ##  #print "elem      $x->{value}->[$s5]\n";
    #  substr($x->{value}->[$s5],-$rem,$rem) = '0' x $rem;	# stamp w/ '0'
    #  }
    #$x->{value}->[$s5] = int ($x->{value}->[$s5]);	# str '05' => int '5'
    #print ${$CALC->_str($pad->{value})}," $len\n";
    if (($pad > 0) && ($pad <= $len))
      {
      substr($$xs,-$pad,$pad) = '0' x $pad;
      $x->{value} = $CALC->_new($xs);			# put back in
      }
    elsif ($pad > $len)
      {
      $x->{value} = $CALC->_zero();			# round to '0'
      }
    #print "res $$xs\n";
    }
  # move this later on after the inc of the string
  #$x->{value} = $CALC->_new($xs);			# put back in
  if ($round_up)					# what gave test above?
    {
    $pad = $len if $scale < 0;				# tlr: whack 0.51=>1.0	
    # modify $x in place, undef, undef to avoid rounding
    # str creation much faster than 10 ** something
    $x->badd( Math::BigInt->new($x->{sign}.'1'.'0'x$pad) );
    # increment string in place, to avoid dec=>hex for the '1000...000'
    # $xs ...blah foo
    }
  # to here:
  #$x->{value} = $CALC->_new($xs);			# put back in
  $x;
  }

sub bfloor
  {
  # return integer less or equal then number, since it is already integer,
  # always returns $self
  my ($self,$x,$a,$p,$r) = objectify(1,@_);

  # not needed: return $x if $x->modify('bfloor');

  return $x->round($a,$p,$r);
  }

sub bceil
  {
  # return integer greater or equal then number, since it is already integer,
  # always returns $self
  my ($self,$x,$a,$p,$r) = objectify(1,@_);

  # not needed: return $x if $x->modify('bceil');

  return $x->round($a,$p,$r);
  }

##############################################################################
# private stuff (internal use only)

sub _one
  {
  # internal speedup, set argument to 1, or create a +/- 1
  my $self = shift;
  #my $x = $self->bzero(); $x->{value} = [ 1 ]; $x->{sign} = shift || '+'; $x;
  my $x = $self->bzero(); $x->{value} = $CALC->_one();
  $x->{sign} = shift || '+';
  return $x;
  }

sub _swap
  {
  # Overload will swap params if first one is no object ref so that the first
  # one is always an object ref. In this case, third param is true.
  # This routine is to overcome the effect of scalar,$object creating an object
  # of the class of this package, instead of the second param $object. This
  # happens inside overload, when the overload section of this package is
  # inherited by sub classes.
  # For overload cases (and this is used only there), we need to preserve the
  # args, hence the copy().
  # You can override this method in a subclass, the overload section will call
  # $object->_swap() to make sure it arrives at the proper subclass, with some
  # exceptions like '+' and '-'.

  # object, (object|scalar) => preserve first and make copy
  # scalar, object	    => swapped, re-swap and create new from first
  #                            (using class of second object, not $class!!)
  my $self = shift;			# for override in subclass
  #print "swap $self 0:$_[0] 1:$_[1] 2:$_[2]\n";
  if ($_[2])
    {
    my $c = ref ($_[0]) || $class; 	# fallback $class should not happen
    return ( $c->new($_[1]), $_[0] );
    }
  else
    { 
    return ( $_[0]->copy(), $_[1] );
    }
  }

sub objectify
  {
  # check for strings, if yes, return objects instead
 
  # the first argument is number of args objectify() should look at it will
  # return $count+1 elements, the first will be a classname. This is because
  # overloaded '""' calls bstr($object,undef,undef) and this would result in
  # useless objects beeing created and thrown away. So we cannot simple loop
  # over @_. If the given count is 0, all arguments will be used.
 
  # If the second arg is a ref, use it as class.
  # If not, try to use it as classname, unless undef, then use $class 
  # (aka Math::BigInt). The latter shouldn't happen,though.

  # caller:			   gives us:
  # $x->badd(1);                => ref x, scalar y
  # Class->badd(1,2);           => classname x (scalar), scalar x, scalar y
  # Class->badd( Class->(1),2); => classname x (scalar), ref x, scalar y
  # Math::BigInt::badd(1,2);    => scalar x, scalar y
  # In the last case we check number of arguments to turn it silently into
  # $class,1,2. (We cannot take '1' as class ;o)
  # badd($class,1) is not supported (it should, eventually, try to add undef)
  # currently it tries 'Math::BigInt' + 1, which will not work.
 
  my $count = abs(shift || 0);
  
  #print caller(),"\n";
 
  my @a;			# resulting array 
  if (ref $_[0])
    {
    # okay, got object as first
    $a[0] = ref $_[0];
    }
  else
    {
    # nope, got 1,2 (Class->xxx(1) => Class,1 and not supported)
    $a[0] = $class;
    #print "@_\n"; sleep(1); 
    $a[0] = shift if $_[0] =~ /^[A-Z].*::/;	# classname as first?
    }
  #print caller(),"\n";
  # print "Now in objectify, my class is today $a[0]\n";
  my $k; 
  if ($count == 0)
    {
    while (@_)
      {
      $k = shift;
      if (!ref($k))
        {
        $k = $a[0]->new($k);
        }
      elsif (ref($k) ne $a[0])
	{
	# foreign object, try to convert to integer
        $k->can('as_number') ?  $k = $k->as_number() : $k = $a[0]->new($k);
	}
      push @a,$k;
      }
    }
  else
    {
    while ($count > 0)
      {
      #print "$count\n";
      $count--; 
      $k = shift; 
      if (!ref($k))
        {
        $k = $a[0]->new($k);
        }
      elsif (ref($k) ne $a[0])
	{
	# foreign object, try to convert to integer
        $k->can('as_number') ?  $k = $k->as_number() : $k = $a[0]->new($k);
	}
      push @a,$k;
      }
    push @a,@_;		# return other params, too
    }
  #my $i = 0;
  #foreach (@a)
  #  {
  #  print "o $i $a[0]\n" if $i == 0;
  #  print "o $i ",ref($_),"\n" if $i != 0; $i++;
  #  }
  #print "objectify done: would return ",scalar @a," values\n";
  #print caller(1),"\n" unless wantarray;
  die "$class objectify needs list context" unless wantarray;
  @a;
  }

sub import 
  {
  my $self = shift;
  #print "import $self @_\n";
  my @a = @_; my $l = scalar @_; my $j = 0;
  for ( my $i = 0; $i < $l ; $i++,$j++ )
    {
    if ($_[$i] eq ':constant')
      {
      # this causes overlord er load to step in
      overload::constant integer => sub { $self->new(shift) };
      splice @a, $j, 1; $j --;
      }
    elsif ($_[$i] =~ /^lib$/i)
      {
      # this causes a different low lib to take care...
      $CALC = $_[$i+1] || $CALC;
      my $s = 2; $s = 1 if @a-$j < 2; # avoid "cannot modify non-existant..."
      splice @a, $j, $s; $j -= $s;
      }
    }
  # any non :constant stuff is handled by our parent, Exporter
  # even if @_ is empty, to give it a chance 
  #$self->SUPER::import(@a);			# does not work
  $self->export_to_level(1,$self,@a);		# need this instead

  # load core math lib
  $CALC = 'Math::BigInt::'.$CALC if $CALC !~ /^Math::BigInt/i;
  my $c = $CALC;
  $c =~ s!::!/!g;                               # XXX portability, e.g. MacOS?
  $c .= '.pm' if $c !~ /\.pm$/;
  require $c;
  }

sub _strip_zeros
  {
  # internal normalization function that strips leading zeros from the array
  # args: ref to array
  my $s = shift;
 
  my $cnt = scalar @$s; # get count of parts
  my $i = $cnt-1;
  #print "strip: cnt $cnt i $i\n";
  # '0', '3', '4', '0', '0',
  #  0    1    2    3    4    
  # cnt = 5, i = 4
  # i = 4
  # i = 3
  # => fcnt = cnt - i (5-2 => 3, cnt => 5-1 = 4, throw away from 4th pos)
  # >= 1: skip first part (this can be zero)
  while ($i > 0) { last if $s->[$i] != 0; $i--; }
  $i++; splice @$s,$i if ($i < $cnt); # $i cant be 0
  return $s;
  }

sub _from_hex
  {
  # convert a (ref to) big hex string to BigInt, return undef for error
  my $hs = shift;

  my $x = Math::BigInt->bzero();
  return $x->bnan() if $$hs !~ /^[\-\+]?0x[0-9A-Fa-f]+$/;

  my $sign = '+'; $sign = '-' if ($$hs =~ /^-/);

  $$hs =~ s/^[+-]//;			# strip sign
  if ($CALC->can('_from_hex'))
    {
    $x->{value} = $CALC->_from_hex($hs);
    }
  else
    {
    # fallback to pure perl
    my $mul = Math::BigInt->bzero(); $mul++;
    my $x65536 = Math::BigInt->new(65536);
    my $len = CORE::length($$hs)-2;
    $len = int($len/4);			# 4-digit parts, w/o '0x'
    my $val; my $i = -4;
    while ($len >= 0)
      {
      $val = substr($$hs,$i,4);
      $val =~ s/^[+-]?0x// if $len == 0;	# for last part only because
      $val = hex($val); 			# hex does not like wrong chars
      # print "$val ",substr($$hs,$i,4),"\n";
      $i -= 4; $len --;
      $x += $mul * $val if $val != 0;
      $mul *= $x65536 if $len >= 0;		# skip last mul
      }
    }
  $x->{sign} = $sign if !$x->is_zero();		# no '-0'
  return $x;
  }

sub _from_bin
  {
  # convert a (ref to) big binary string to BigInt, return undef for error
  my $bs = shift;

  my $x = Math::BigInt->bzero();
  return $x->bnan() if $$bs !~ /^[+-]?0b[01]+$/;

  my $mul = Math::BigInt->bzero(); $mul++;
  my $x256 = Math::BigInt->new(256);

  my $sign = '+'; $sign = '-' if ($$bs =~ /^\-/);
  $$bs =~ s/^[+-]//;				# strip sign
  if ($CALC->can('_from_bin'))
    {
    $x->{value} = $CALC->_from_bin($bs);
    }
  else
    {
    my $len = CORE::length($$bs)-2;
    $len = int($len/8);				# 8-digit parts, w/o '0b'
    my $val; my $i = -8;
    while ($len >= 0)
      {
      $val = substr($$bs,$i,8);
      $val =~ s/^[+-]?0b// if $len == 0;	# for last part only
      #$val = oct('0b'.$val);	# does not work on Perl prior to 5.6.0
      $val = ('0' x (8-CORE::length($val))).$val if CORE::length($val) < 8;
      $val = ord(pack('B8',$val));
      # print "$val ",substr($$bs,$i,16),"\n";
      $i -= 8; $len --;
      $x += $mul * $val if $val != 0;
      $mul *= $x256 if $len >= 0;		# skip last mul
      }
    }
  $x->{sign} = $sign if !$x->is_zero();
  return $x;
  }

sub _split
  {
  # (ref to num_str) return num_str
  # internal, take apart a string and return the pieces
  my $x = shift;

  # pre-parse input
  $$x =~ s/^\s+//g;			# strip white space at front
  $$x =~ s/\s+$//g;			# strip white space at end
  #$$x =~ s/\s+//g;			# strip white space (no longer)
  return if $$x eq "";

  return _from_hex($x) if $$x =~ /^[\-\+]?0x/;	# hex string
  return _from_bin($x) if $$x =~ /^[\-\+]?0b/;	# binary string

  return if $$x !~ /^[\-\+]?\.?[0-9]/;

  $$x =~ s/(\d)_(\d)/$1$2/g;		# strip underscores between digits
  $$x =~ s/(\d)_(\d)/$1$2/g;		# do twice for 1_2_3
  
  # some possible inputs: 
  # 2.1234 # 0.12        # 1 	      # 1E1 # 2.134E1 # 434E-10 # 1.02009E-2 
  # .2 	   # 1_2_3.4_5_6 # 1.4E1_2_3  # 1e3 # +.2

  #print "input: '$$x' ";
  my ($m,$e) = split /[Ee]/,$$x;
  $e = '0' if !defined $e || $e eq "";
  # print "m '$m' e '$e'\n";
  # sign,value for exponent,mantint,mantfrac
  my ($es,$ev,$mis,$miv,$mfv);
  # valid exponent?
  if ($e =~ /^([+-]?)0*(\d+)$/) # strip leading zeros
    {
    $es = $1; $ev = $2;
    #print "'$m' '$e' e: $es $ev ";
    # valid mantissa?
    return if $m eq '.' || $m eq '';
    my ($mi,$mf) = split /\./,$m;
    $mi = '0' if !defined $mi;
    $mi .= '0' if $mi =~ /^[\-\+]?$/;
    $mf = '0' if !defined $mf || $mf eq '';
    if ($mi =~ /^([+-]?)0*(\d+)$/) # strip leading zeros
      {
      $mis = $1||'+'; $miv = $2;
      # print "$mis $miv";
      # valid, existing fraction part of mantissa?
      return unless ($mf =~ /^(\d*?)0*$/);	# strip trailing zeros
      $mfv = $1;
      #print " split: $mis $miv . $mfv E $es $ev\n";
      return (\$mis,\$miv,\$mfv,\$es,\$ev);
      }
    }
  return; # NaN, not a number
  }

sub as_number
  {
  # an object might be asked to return itself as bigint on certain overloaded
  # operations, this does exactly this, so that sub classes can simple inherit
  # it or override with their own integer conversion routine
  my $self = shift;

  return $self->copy();
  }

##############################################################################
# internal calculation routines (others are in Math::BigInt::Calc etc)

sub cmp 
  {
  # post-normalized compare for internal use (honors signs)
  # input:  ref to value, ref to value, sign, sign
  # output: <0, 0, >0
  my ($cx,$cy,$sx,$sy) = @_;

  if ($sx eq '+') 
    {
    return 1 if $sy eq '-'; # 0 check handled above
    #return acmp($cx,$cy);
    return $CALC->_acmp($cx,$cy);
    }
  else
    {
    # $sx eq '-'
    return -1 if $sy eq '+';
    #return acmp($cy,$cx);
    return $CALC->_acmp($cy,$cx);
    }
  return 0; # equal
  }

sub _lcm 
  { 
  # (BINT or num_str, BINT or num_str) return BINT
  # does modify first argument
  # LCM
 
  my $x = shift; my $ty = shift;
  return $x->bnan() if ($x->{sign} eq $nan) || ($ty->{sign} eq $nan);
  return $x * $ty / bgcd($x,$ty);
  }

sub _gcd
  { 
  # (BINT or num_str, BINT or num_str) return BINT
  # does modify first arg
  # GCD -- Euclids algorithm E, Knuth Vol 2 pg 296
 
  my $x = shift; my $ty = $class->new(shift); # preserve y, but make class
  return $x->bnan() if $x->{sign} !~ /^[+-]$/ || $ty->{sign} !~ /^[+-]$/;

  while (!$ty->is_zero())
    {
    ($x, $ty) = ($ty,bmod($x,$ty));
    }
  $x;
  }

###############################################################################
# this method return 0 if the object can be modified, or 1 for not
# We use a fast use constant statement here, to avoid costly calls. Subclasses
# may override it with special code (f.i. Math::BigInt::Constant does so)

sub modify () { 0; }

1;
__END__

=head1 NAME

Math::BigInt - Arbitrary size integer math package

=head1 SYNOPSIS

  use Math::BigInt;

  # Number creation	
  $x = Math::BigInt->new($str);	# defaults to 0
  $nan  = Math::BigInt->bnan(); # create a NotANumber
  $zero = Math::BigInt->bzero();# create a "+0"

  # Testing
  $x->is_zero();		# return whether arg is zero or not
  $x->is_nan();			# return whether arg is NaN or not
  $x->is_one();			# true if arg is +1
  $x->is_one('-');		# true if arg is -1
  $x->is_odd();			# true if odd, false for even
  $x->is_even();		# true if even, false for odd
  $x->is_positive();		# true if >= 0
  $x->is_negative();		# true if <  0
  $x->is_inf(sign);		# true if +inf, or -inf (sign is default '+')

  $x->bcmp($y);			# compare numbers (undef,<0,=0,>0)
  $x->bacmp($y);		# compare absolutely (undef,<0,=0,>0)
  $x->sign();			# return the sign, either +,- or NaN
  $x->digit($n);		# return the nth digit, counting from right
  $x->digit(-$n);		# return the nth digit, counting from left

  # The following all modify their first argument:

  # set 
  $x->bzero();			# set $x to 0
  $x->bnan();			# set $x to NaN

  $x->bneg();			# negation
  $x->babs();			# absolute value
  $x->bnorm();			# normalize (no-op)
  $x->bnot();			# two's complement (bit wise not)
  $x->binc();			# increment x by 1
  $x->bdec();			# decrement x by 1
  
  $x->badd($y);			# addition (add $y to $x)
  $x->bsub($y);			# subtraction (subtract $y from $x)
  $x->bmul($y);			# multiplication (multiply $x by $y)
  $x->bdiv($y);			# divide, set $x to quotient
				# return (quo,rem) or quo if scalar

  $x->bmod($y);			# modulus (x % y)
  $x->bpow($y);			# power of arguments (x ** y)
  $x->blsft($y);		# left shift
  $x->brsft($y);		# right shift 
  $x->blsft($y,$n);		# left shift, by base $n (like 10)
  $x->brsft($y,$n);		# right shift, by base $n (like 10)
  
  $x->band($y);			# bitwise and
  $x->bior($y);			# bitwise inclusive or
  $x->bxor($y);			# bitwise exclusive or
  $x->bnot();			# bitwise not (two's complement)

  $x->bsqrt();			# calculate square-root

  $x->round($A,$P,$round_mode); # round to accuracy or precision using mode $r
  $x->bround($N);               # accuracy: preserve $N digits
  $x->bfround($N);              # round to $Nth digit, no-op for BigInts

  # The following do not modify their arguments in BigInt, but do in BigFloat:
  $x->bfloor();			# return integer less or equal than $x
  $x->bceil();			# return integer greater or equal than $x
  
  # The following do not modify their arguments:

  bgcd(@values);		# greatest common divisor
  blcm(@values);		# lowest common multiplicator
  
  $x->bstr();			# normalized string
  $x->bsstr();			# normalized string in scientific notation
  $x->length();			# return number of digits in number
  ($x,$f) = $x->length();	# length of number and length of fraction part

  $x->exponent();		# return exponent as BigInt
  $x->mantissa();		# return mantissa as BigInt
  $x->parts();			# return (mantissa,exponent) as BigInt
  $x->copy();			# make a true copy of $x (unlike $y = $x;)
  $x->as_number();		# return as BigInt (in BigInt: same as copy())

=head1 DESCRIPTION

All operators (inlcuding basic math operations) are overloaded if you
declare your big integers as

  $i = new Math::BigInt '123_456_789_123_456_789';

Operations with overloaded operators preserve the arguments which is
exactly what you expect.

=over 2

=item Canonical notation

Big integer values are strings of the form C</^[+-]\d+$/> with leading
zeros suppressed.

   '-0'                            canonical value '-0', normalized '0'
   '   -123_123_123'               canonical value '-123123123'
   '1_23_456_7890'                 canonical value '1234567890'

=item Input

Input values to these routines may be either Math::BigInt objects or
strings of the form C</^\s*[+-]?[\d]+\.?[\d]*E?[+-]?[\d]*$/>.

You can include one underscore between any two digits.

This means integer values like 1.01E2 or even 1000E-2 are also accepted.
Non integer values result in NaN.

Math::BigInt::new() defaults to 0, while Math::BigInt::new('') results
in 'NaN'.

bnorm() on a BigInt object is now effectively a no-op, since the numbers 
are always stored in normalized form. On a string, it creates a BigInt 
object.

=item Output

Output values are BigInt objects (normalized), except for bstr(), which
returns a string in normalized form.
Some routines (C<is_odd()>, C<is_even()>, C<is_zero()>, C<is_one()>,
C<is_nan()>) return true or false, while others (C<bcmp()>, C<bacmp()>)
return either undef, <0, 0 or >0 and are suited for sort.

=back

=head1 ACCURACY and PRECISION

Since version v1.33, Math::BigInt and Math::BigFloat have full support for
accuracy and precision based rounding, both automatically after every
operation as well as manually.

This section describes the accuracy/precision handling in Math::Big* as it
used to be and as it is now, complete with an explanation of all terms and
abbreviations.

Not yet implemented things (but with correct description) are marked with '!',
things that need to be answered are marked with '?'.

In the next paragraph follows a short description of terms used here (because
these may differ from terms used by other people or documentation).

During the rest of this document, the shortcuts A (for accuracy), P (for
precision), F (fallback) and R (rounding mode) will be used.

=head2 Precision P

A fixed number of digits before (positive) or after (negative)
the decimal point. For example, 123.45 has a precision of -2. 0 means an
integer like 123 (or 120). A precision of 2 means two digits to the left
of the decimal point are zero, so 123 with P = 1 becomes 120. Note that
numbers with zeros before the decimal point may have different precisions,
because 1200 can have p = 0, 1 or 2 (depending on what the inital value
was). It could also have p < 0, when the digits after the decimal point
are zero.

 !The string output of such a number should be padded with zeros:
 !
 !      Initial value   P       Result          String
 !      1234.01         -3      1000            1000
 !      1234            -2      1200            1200
 !      1234.5          -1      1230            1230
 !      1234.001        1       1234            1234.0
 !      1234.01         0       1234            1234
 !      1234.01         2       1234.01         1234.01
 !      1234.01         5       1234.01         1234.01000

=head2 Accuracy A

Number of significant digits. Leading zeros are not counted. A
number may have an accuracy greater than the non-zero digits
when there are zeros in it or trailing zeros. For example, 123.456 has
A of 6, 10203 has 5, 123.0506 has 7, 123.450000 has 8 and 0.000123 has 3.

=head2 Fallback F

When both A and P are undefined, this is used as a fallback accuracy.

=head2 Rounding mode R

When rounding a number, different 'styles' or 'kinds'
of rounding are possible. (Note that random rounding, as in
Math::Round, is not implemented.)

=over 2

=item 'trunc'

truncation invariably removes all digits following the
rounding place, replacing them with zeros. Thus, 987.65 rounded
to tens (P=1) becomes 980, and rounded to the fourth sigdig
becomes 987.6 (A=4). 123.456 rounded to the second place after the
decimal point (P=-2) becomes 123.46.

All other implemented styles of rounding attempt to round to the
"nearest digit." If the digit D immediately to the right of the
rounding place (skipping the decimal point) is greater than 5, the
number is incremented at the rounding place (possibly causing a
cascade of incrementation): e.g. when rounding to units, 0.9 rounds
to 1, and -19.9 rounds to -20. If D < 5, the number is similarly
truncated at the rounding place: e.g. when rounding to units, 0.4
rounds to 0, and -19.4 rounds to -19.

However the results of other styles of rounding differ if the
digit immediately to the right of the rounding place (skipping the
decimal point) is 5 and if there are no digits, or no digits other
than 0, after that 5. In such cases:

=item 'even'

rounds the digit at the rounding place to 0, 2, 4, 6, or 8
if it is not already. E.g., when rounding to the first sigdig, 0.45
becomes 0.4, -0.55 becomes -0.6, but 0.4501 becomes 0.5.

=item 'odd'

rounds the digit at the rounding place to 1, 3, 5, 7, or 9 if
it is not already. E.g., when rounding to the first sigdig, 0.45
becomes 0.5, -0.55 becomes -0.5, but 0.5501 becomes 0.6.

=item '+inf'

round to plus infinity, i.e. always round up. E.g., when
rounding to the first sigdig, 0.45 becomes 0.5, -0.55 becomes -0.5,
and 0.4501 also becomes 0.5.

=item '-inf'

round to minus infinity, i.e. always round down. E.g., when
rounding to the first sigdig, 0.45 becomes 0.4, -0.55 becomes -0.6,
but 0.4501 becomes 0.5.

=item 'zero'

round to zero, i.e. positive numbers down, negative ones up.
E.g., when rounding to the first sigdig, 0.45 becomes 0.4, -0.55
becomes -0.5, but 0.4501 becomes 0.5.

=back

The handling of A & P in MBI/MBF (the old core code shipped with Perl
versions <= 5.7.2) is like this:

=over 2

=item Precision

  * ffround($p) is able to round to $p number of digits after the decimal
    point
  * otherwise P is unused

=item Accuracy (significant digits)

  * fround($a) rounds to $a significant digits
  * only fdiv() and fsqrt() take A as (optional) paramater
    + other operations simply create the same number (fneg etc), or more (fmul)
      of digits
    + rounding/truncating is only done when explicitly calling one of fround
      or ffround, and never for BigInt (not implemented)
  * fsqrt() simply hands its accuracy argument over to fdiv.
  * the documentation and the comment in the code indicate two different ways
    on how fdiv() determines the maximum number of digits it should calculate,
    and the actual code does yet another thing
    POD:
      max($Math::BigFloat::div_scale,length(dividend)+length(divisor))
    Comment:
      result has at most max(scale, length(dividend), length(divisor)) digits
    Actual code:
      scale = max(scale, length(dividend)-1,length(divisor)-1);
      scale += length(divisior) - length(dividend);
    So for lx = 3, ly = 9, scale = 10, scale will actually be 16 (10+9-3).
    Actually, the 'difference' added to the scale is calculated from the
    number of "significant digits" in dividend and divisor, which is derived
    by looking at the length of the mantissa. Which is wrong, since it includes
    the + sign (oups) and actually gets 2 for '+100' and 4 for '+101'. Oups
    again. Thus 124/3 with div_scale=1 will get you '41.3' based on the strange
    assumption that 124 has 3 significant digits, while 120/7 will get you
    '17', not '17.1' since 120 is thought to have 2 significant digits.
    The rounding after the division then uses the reminder and $y to determine
    wether it must round up or down.
 ?  I have no idea which is the right way. That's why I used a slightly more
 ?  simple scheme and tweaked the few failing testcases to match it.

=back

This is how it works now:

=over 2

=item Setting/Accessing

  * You can set the A global via $Math::BigInt::accuracy or
    $Math::BigFloat::accuracy or whatever class you are using.
  * You can also set P globally by using $Math::SomeClass::precision likewise.
  * Globals are classwide, and not inherited by subclasses.
  * to undefine A, use $Math::SomeCLass::accuracy = undef
  * to undefine P, use $Math::SomeClass::precision = undef
  * To be valid, A must be > 0, P can have any value.
  * If P is negative, this means round to the P'th place to the right of the
    decimal point; positive values mean to the left of the decimal point.
    P of 0 means round to integer.
  * to find out the current global A, take $Math::SomeClass::accuracy
  * use $x->accuracy() for the local setting of $x.
  * to find out the current global P, take $Math::SomeClass::precision
  * use $x->precision() for the local setting

=item Creating numbers

 !* When you create a number, there should be a way to define its A & P
  * When a number without specific A or P is created, but the globals are
    defined, these should be used to round the number immediately and also
    stored locally with the number. Thus changing the global defaults later on
    will not change the A or P of previously created numbers (i.e., A and P of
    $x will be what was in effect when $x was created) 

=item Usage

  * If A or P are enabled/defined, they are used to round the result of each
    operation according to the rules below
  * Negative P is ignored in Math::BigInt, since BigInts never have digits
    after the decimal point
 !* Math::BigFloat uses Math::BigInts internally, but setting A or P inside
 !  Math::BigInt as globals should not tamper with the parts of a BigFloat.
 !  Thus a flag is used to mark all Math::BigFloat numbers as 'never round'

=item Precedence

  * It only makes sense that a number has only one of A or P at a time.
    Since you can set/get both A and P, there is a rule that will practically
    enforce only A or P to be in effect at a time, even if both are set.
    This is called precedence.
 !* If two objects are involved in an operation, and one of them has A in
 !  effect, and the other P, this should result in a warning or an error,
 !  probably in NaN.
  * A takes precendence over P (Hint: A comes before P). If A is defined, it
    is used, otherwise P is used. If neither of them is defined, nothing is
    used, i.e. the result will have as many digits as it can (with an
    exception for fdiv/fsqrt) and will not be rounded.
  * There is another setting for fdiv() (and thus for fsqrt()). If neither of
    A or P is defined, fdiv() will use a fallback (F) of $div_scale digits.
    If either the dividend's or the divisor's mantissa has more digits than
    the value of F, the higher value will be used instead of F.
    This is to limit the digits (A) of the result (just consider what would
    happen with unlimited A and P in the case of 1/3 :-)
  * fdiv will calculate 1 more digit than required (determined by
    A, P or F), and, if F is not used, round the result
    (this will still fail in the case of a result like 0.12345000000001 with A
    or P of 5, but this cannot be helped - or can it?)
  * Thus you can have the math done by on Math::Big* class in three modes:
    + never round (this is the default):
      This is done by setting A and P to undef. No math operation
      will round the result, with fdiv() and fsqrt() as exceptions to guard
      against overflows. You must explicitely call bround(), bfround() or
      round() (the latter with parameters).
      Note: Once you have rounded a number, the settings will 'stick' on it
      and 'infect' all other numbers engaged in math operations with it, since
      local settings have the highest precedence. So, to get SaferRound[tm],
      use a copy() before rounding like this:

        $x = Math::BigFloat->new(12.34);
        $y = Math::BigFloat->new(98.76);
        $z = $x * $y;                           # 1218.6984
        print $x->copy()->fround(3);            # 12.3 (but A is now 3!)
        $z = $x * $y;                           # still 1218.6984, without
                                                # copy would have been 1210!

    + round after each op:
      After each single operation (except for testing like is_zero()), the
      method round() is called and the result is rounded appropriately. By
      setting proper values for A and P, you can have all-the-same-A or
      all-the-same-P modes. For example, Math::Currency might set A to undef,
      and P to -2, globally.

 ?Maybe an extra option that forbids local A & P settings would be in order,
 ?so that intermediate rounding does not 'poison' further math? 

=item Overriding globals

  * you will be able to give A, P and R as an argument to all the calculation
    routines; the second parameter is A, the third one is P, and the fourth is
    R (shift place by one for binary operations like add). P is used only if
    the first parameter (A) is undefined. These three parameters override the
    globals in the order detailed as follows, i.e. the first defined value
    wins:
    (local: per object, global: global default, parameter: argument to sub)
      + parameter A
      + parameter P
      + local A (if defined on both of the operands: smaller one is taken)
      + local P (if defined on both of the operands: smaller one is taken)
      + global A
      + global P
      + global F
  * fsqrt() will hand its arguments to fdiv(), as it used to, only now for two
    arguments (A and P) instead of one

=item Local settings

  * You can set A and P locally by using $x->accuracy() and $x->precision()
    and thus force different A and P for different objects/numbers.
  * Setting A or P this way immediately rounds $x to the new value.

=item Rounding

  * the rounding routines will use the respective global or local settings.
    fround()/bround() is for accuracy rounding, while ffround()/bfround()
    is for precision
  * the two rounding functions take as the second parameter one of the
    following rounding modes (R):
    'even', 'odd', '+inf', '-inf', 'zero', 'trunc'
  * you can set and get the global R by using Math::SomeClass->round_mode()
    or by setting $Math::SomeClass::rnd_mode
  * after each operation, $result->round() is called, and the result may
    eventually be rounded (that is, if A or P were set either locally,
    globally or as parameter to the operation)
  * to manually round a number, call $x->round($A,$P,$rnd_mode);
    this will round the number by using the appropriate rounding function
    and then normalize it.
  * rounding modifies the local settings of the number:

        $x = Math::BigFloat->new(123.456);
        $x->accuracy(5);
        $x->bround(4);

    Here 4 takes precedence over 5, so 123.5 is the result and $x->accuracy()
    will be 4 from now on.

=item Default values

  * R: 'even'
  * F: 40
  * A: undef
  * P: undef

=item Remarks

  * The defaults are set up so that the new code gives the same results as
    the old code (except in a few cases on fdiv):
    + Both A and P are undefined and thus will not be used for rounding
      after each operation.
    + round() is thus a no-op, unless given extra parameters A and P

=back

=head1 INTERNALS

The actual numbers are stored as unsigned big integers, and math with them is
done (by default) by a module called Math::BigInt::Calc. This is equivalent to:

	use Math::BigInt lib => 'calc';

You can change this by using:

	use Math::BigInt lib => 'BitVect';

('Math::BitInt::BitVect' works, too.)

Calc.pm uses as internal format an array of elements of base 100000 digits
with the least significant digit first, BitVect.pm uses a bit vector of base 2,
most significant bit first.

The sign C</^[+-]$/> is stored separately. The string 'NaN' is used to 
represent the result when input arguments are not numbers. '+inf' and
'-inf' represent infinity.

You should neither care about nor depend on the internal representation; it
might change without notice. Use only method calls like C<< $x->sign(); >>
instead of relying on the internal hash keys like in C<< $x->{sign}; >>.

=head2 mantissa(), exponent() and parts()

C<mantissa()> and C<exponent()> return the said parts of the BigInt such
that:

        $m = $x->mantissa();
        $e = $x->exponent();
        $y = $m * ( 10 ** $e );
        print "ok\n" if $x == $y;

C<< ($m,$e) = $x->parts() >> is just a shortcut that gives you both of them
in one go. Both the returned mantissa and exponent have a sign.

Currently, for BigInts C<$e> will be always 0, except for NaN where it will be
NaN and for $x == 0, then it will be 1 (to be compatible with Math::BigFloat's
internal representation of a zero as C<0E1>).

C<$m> will always be a copy of the original number. The relation between $e
and $m might change in the future, but will always be equivalent in a
numerical sense, e.g. $m might get minimized.

=head1 EXAMPLES
 
  use Math::BigInt qw(bstr bint);
  $x = bstr("1234")                  	# string "1234"
  $x = "$x";                         	# same as bstr()
  $x = bneg("1234")                  	# Bigint "-1234"
  $x = Math::BigInt->bneg("1234");   	# Bigint "-1234"
  $x = Math::BigInt->babs("-12345"); 	# Bigint "12345"
  $x = Math::BigInt->bnorm("-0 00"); 	# BigInt "0"
  $x = bint(1) + bint(2);            	# BigInt "3"
  $x = bint(1) + "2";                	# ditto (auto-BigIntify of "2")
  $x = bint(1);                      	# BigInt "1"
  $x = $x + 5 / 2;                   	# BigInt "3"
  $x = $x ** 3;                      	# BigInt "27"
  $x *= 2;                           	# BigInt "54"
  $x = new Math::BigInt;             	# BigInt "0"
  $x--;                              	# BigInt "-1"
  $x = Math::BigInt->badd(4,5)		# BigInt "9"
  $x = Math::BigInt::badd(4,5)		# BigInt "9"
  print $x->bsstr();			# 9e+0

Examples for rounding:

  use Math::BigFloat;
  use Test;

  $x = Math::BigFloat->new(123.4567);
  $y = Math::BigFloat->new(123.456789);
  $Math::BigFloat::accuracy = 4;	# no more A than 4

  ok ($x->copy()->fround(),123.4);	# even rounding
  print $x->copy()->fround(),"\n";	# 123.4
  Math::BigFloat->round_mode('odd');	# round to odd
  print $x->copy()->fround(),"\n";	# 123.5
  $Math::BigFloat::accuracy = 5;	# no more A than 5
  Math::BigFloat->round_mode('odd');	# round to odd
  print $x->copy()->fround(),"\n";	# 123.46
  $y = $x->copy()->fround(4),"\n";	# A = 4: 123.4
  print "$y, ",$y->accuracy(),"\n";	# 123.4, 4

  $Math::BigFloat::accuracy = undef;    # A not important
  $Math::BigFloat::precision = 2;       # P important
  print $x->copy()->bnorm(),"\n";       # 123.46
  print $x->copy()->fround(),"\n";      # 123.46

=head1 Autocreating constants

After C<use Math::BigInt ':constant'> all the B<integer> decimal constants
in the given scope are converted to C<Math::BigInt>. This conversion
happens at compile time.

In particular,

  perl -MMath::BigInt=:constant -e 'print 2**100,"\n"'

prints the integer value of C<2**100>.  Note that without conversion of 
constants the expression 2**100 will be calculated as perl scalar.

Please note that strings and floating point constants are not affected,
so that

  	use Math::BigInt qw/:constant/;

	$x = 1234567890123456789012345678901234567890
		+ 123456789123456789;
	$y = '1234567890123456789012345678901234567890'
		+ '123456789123456789';

do not work. You need an explicit Math::BigInt->new() around one of the
operands.

=head1 PERFORMANCE

Using the form $x += $y; etc over $x = $x + $y is faster, since a copy of $x
must be made in the second case. For long numbers, the copy can eat up to 20%
of the work (in the case of addition/subtraction, less for
multiplication/division). If $y is very small compared to $x, the form
$x += $y is MUCH faster than $x = $x + $y since making the copy of $x takes
more time then the actual addition.

With a technique called copy-on-write, the cost of copying with overload could
be minimized or even completely avoided. This is currently not implemented.

The new version of this module is slower on new(), bstr() and numify(). Some
operations may be slower for small numbers, but are significantly faster for
big numbers. Other operations are now constant (O(1), like bneg(), babs()
etc), instead of O(N) and thus nearly always take much less time.

For more benchmark results see http://bloodgate.com/perl/benchmarks.html

=head2 Replacing the math library

You can use an alternative library to drive Math::BigInt via:

	use Math::BigInt lib => 'Module';

The default is called Math::BigInt::Calc and is a pure-perl base 100,000
math package that consists of the standard routine present in earlier versions
of Math::BigInt.

There are also Math::BigInt::Scalar (primarily for testing) and
Math::BigInt::BitVect; these and others can be found via
L<http://search.cpan.org/>:

	use Math::BigInt lib => 'BitVect';

	my $x = Math::BigInt->new(2);
	print $x ** (1024*1024);

=head1 BUGS

=over 2

=item :constant and eval()

Under Perl prior to 5.6.0 having an C<use Math::BigInt ':constant';> and 
C<eval()> in your code will crash with "Out of memory". This is probably an
overload/exporter bug. You can workaround by not having C<eval()> 
and ':constant' at the same time or upgrade your Perl.

=back

=head1 CAVEATS

Some things might not work as you expect them. Below is documented what is
known to be troublesome:

=over 1

=item stringify, bstr(), bsstr() and 'cmp'

Both stringify and bstr() now drop the leading '+'. The old code would return
'+3', the new returns '3'. This is to be consistent with Perl and to make
cmp (especially with overloading) to work as you expect. It also solves
problems with Test.pm, it's ok() uses 'eq' internally. 

Mark said, when asked about to drop the '+' altogether, or make only cmp work:

	I agree (with the first alternative), don't add the '+' on positive
	numbers.  It's not as important anymore with the new internal 
	form for numbers.  It made doing things like abs and neg easier,
	but those have to be done differently now anyway.

So, the following examples will now work all as expected:

	use Test;
        BEGIN { plan tests => 1 }
	use Math::BigInt;

	my $x = new Math::BigInt 3*3;
	my $y = new Math::BigInt 3*3;

	ok ($x,3*3);
	print "$x eq 9" if $x eq $y;
	print "$x eq 9" if $x eq '9';
	print "$x eq 9" if $x eq 3*3;

Additionally, the following still works:
	
	print "$x == 9" if $x == $y;
	print "$x == 9" if $x == 9;
	print "$x == 9" if $x == 3*3;

There is now a C<bsstr()> method to get the string in scientific notation aka
C<1e+2> instead of C<100>. Be advised that overloaded 'eq' always uses bstr()
for comparisation, but Perl will represent some numbers as 100 and others
as 1e+308. If in doubt, convert both arguments to Math::BigInt before doing eq:

	use Test;
        BEGIN { plan tests => 3 }
	use Math::BigInt;

	$x = Math::BigInt->new('1e56'); $y = 1e56;
	ok ($x,$y);			# will fail
	ok ($x->bsstr(),$y);		# okay
	$y = Math::BigInt->new($y);
	ok ($x,$y);			# okay

=item int()

C<int()> will return (at least for Perl v5.7.1 and up) another BigInt, not a 
Perl scalar:

	$x = Math::BigInt->new(123);
	$y = int($x);				# BigInt 123
	$x = Math::BigFloat->new(123.45);
	$y = int($x);				# BigInt 123

In all Perl versions you can use C<as_number()> for the same effect:

	$x = Math::BigFloat->new(123.45);
	$y = $x->as_number();			# BigInt 123

This also works for other subclasses, like Math::String.

=item bdiv

The following will probably not do what you expect:

	print $c->bdiv(10000),"\n";

It prints both quotient and reminder since print calls C<bdiv()> in list
context. Also, C<bdiv()> will modify $c, so be carefull. You probably want
to use
	
	print $c / 10000,"\n";
	print scalar $c->bdiv(10000),"\n";  # or if you want to modify $c

instead.

The quotient is always the greatest integer less than or equal to the
real-valued quotient of the two operands, and the remainder (when it is
nonzero) always has the same sign as the second operand; so, for
example,

	1 / 4   => ( 0, 1)
	1 / -4  => (-1,-3)
	-3 / 4  => (-1, 1)
	-3 / -4 => ( 0,-3)

As a consequence, the behavior of the operator % agrees with the
behavior of Perl's built-in % operator (as documented in the perlop
manpage), and the equation

	$x == ($x / $y) * $y + ($x % $y)

holds true for any $x and $y, which justifies calling the two return
values of bdiv() the quotient and remainder.

Perl's 'use integer;' changes the behaviour of % and / for scalars, but will
not change BigInt's way to do things. This is because under 'use integer' Perl
will do what the underlying C thinks is right and this is different for each
system. If you need BigInt's behaving exactly like Perl's 'use integer', bug
the author to implement it ;)

=item Modifying and =

Beware of:

        $x = Math::BigFloat->new(5);
        $y = $x;

It will not do what you think, e.g. making a copy of $x. Instead it just makes
a second reference to the B<same> object and stores it in $y. Thus anything
that modifies $x will modify $y, and vice versa.

        $x->bmul(2);
        print "$x, $y\n";       # prints '10, 10'

If you want a true copy of $x, use:

        $y = $x->copy();

See also the documentation for overload.pm regarding C<=>.

=item bpow

C<bpow()> (and the rounding functions) now modifies the first argument and
return it, unlike the old code which left it alone and only returned the
result. This is to be consistent with C<badd()> etc. The first three will
modify $x, the last one won't:

	print bpow($x,$i),"\n"; 	# modify $x
	print $x->bpow($i),"\n"; 	# ditto
	print $x **= $i,"\n";		# the same
	print $x ** $i,"\n";		# leave $x alone 

The form C<$x **= $y> is faster than C<$x = $x ** $y;>, though.

=item Overloading -$x

The following:

	$x = -$x;

is slower than

	$x->bneg();

since overload calls C<sub($x,0,1);> instead of C<neg($x)>. The first variant
needs to preserve $x since it does not know that it later will get overwritten.
This makes a copy of $x and takes O(N), but $x->bneg() is O(1).

With Copy-On-Write, this issue will be gone. Stay tuned...

=item Mixing different object types

In Perl you will get a floating point value if you do one of the following:

	$float = 5.0 + 2;
	$float = 2 + 5.0;
	$float = 5 / 2;

With overloaded math, only the first two variants will result in a BigFloat:

	use Math::BigInt;
	use Math::BigFloat;
	
	$mbf = Math::BigFloat->new(5);
	$mbi2 = Math::BigInteger->new(5);
	$mbi = Math::BigInteger->new(2);

					# what actually gets called:
	$float = $mbf + $mbi;		# $mbf->badd()
	$float = $mbf / $mbi;		# $mbf->bdiv()
	$integer = $mbi + $mbf;		# $mbi->badd()
	$integer = $mbi2 / $mbi;	# $mbi2->bdiv()
	$integer = $mbi2 / $mbf;	# $mbi2->bdiv()

This is because math with overloaded operators follows the first (dominating)
operand, this one's operation is called and returns thus the result. So,
Math::BigInt::bdiv() will always return a Math::BigInt, regardless whether
the result should be a Math::BigFloat or the second operant is one.

To get a Math::BigFloat you either need to call the operation manually,
make sure the operands are already of the proper type or casted to that type
via Math::BigFloat->new():
	
	$float = Math::BigFloat->new($mbi2) / $mbi;	# = 2.5

Beware of simple "casting" the entire expression, this would only convert
the already computed result:

	$float = Math::BigFloat->new($mbi2 / $mbi);	# = 2.0 thus wrong!

Beware also of the order of more complicated expressions like:

	$integer = ($mbi2 + $mbi) / $mbf;		# int / float => int
	$integer = $mbi2 / Math::BigFloat->new($mbi);	# ditto

If in doubt, break the expression into simpler terms, or cast all operands
to the desired resulting type.

Scalar values are a bit different, since:
	
	$float = 2 + $mbf;
	$float = $mbf + 2;

will both result in the proper type due to the way the overloaded math works.

This section also applies to other overloaded math packages, like Math::String.

=item bsqrt()

C<bsqrt()> works only good if the result is an big integer, e.g. the square
root of 144 is 12, but from 12 the square root is 3, regardless of rounding
mode.

If you want a better approximation of the square root, then use:

	$x = Math::BigFloat->new(12);
	$Math::BigFloat::precision = 0;
	Math::BigFloat->round_mode('even');
	print $x->copy->bsqrt(),"\n";		# 4

	$Math::BigFloat::precision = 2;
	print $x->bsqrt(),"\n";			# 3.46
	print $x->bsqrt(3),"\n";		# 3.464

=back

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Math::BigFloat> and L<Math::Big>.

=head1 AUTHORS

Original code by Mark Biggar, overloaded interface by Ilya Zakharevich.
Completely rewritten by Tels http://bloodgate.com in late 2000, 2001.

=cut

#!/usr/bin/perl -w

# mark.biggar@TrustedSysLabs.com
# eay@mincom.com is dead (math::BigInteger)
# see: http://www.cypherspace.org/~adam/rsa/pureperl.html (contacted c. adam
# on 2000/11/13 - but email is dead

# todo:
# - fully remove funky $# stuff (maybe)
# - use integer; vs 1e7 as base
# - speed issues (XS? Bit::Vector?)
# - split out actual math code to Math::BigNumber 

# Qs: what exactly happens on numify of HUGE numbers? overflow?
#     $a = -$a is much slower (making copy of $a) than $a->bneg(), hm!?
#     (copy_on_write will help there, but that is not yet implemented)

# The following hash values are used:
#   value: the internal array, base 100000
#   sign : +,-,NaN,+inf,-inf
#   _a   : accuracy
#   _p   : precision
#   _cow : copy on write: number of objects that share the data (NRY)
# Internally the numbers are stored in an array with at least 1 element, no
# leading zero parts (except the first) and in base 100000

# USE_MUL: due to problems on certain os (os390, posix-bc) "* 1e-5" is used 
# instead of "/ 1e5" at some places, (marked with USE_MUL). But instead of
# using the reverse only on problematic machines, I used it everytime to avoid
# the costly comparisations. This _should_ work everywhere. Thanx Peter Prymmer

package Math::BigInt;
my $class = "Math::BigInt";

$VERSION = 1.35;
use Exporter;
@ISA =       qw( Exporter );
@EXPORT_OK = qw( bneg babs bcmp badd bmul bdiv bmod bnorm bsub
                 bgcd blcm
		 bround 
                 blsft brsft band bior bxor bnot bpow bnan bzero 
                 bacmp bstr bsstr binc bdec bint binf bfloor bceil
                 is_odd is_even is_zero is_one is_nan is_inf sign
		 length as_number
		 trace objectify _swap
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

# are NaNs ok?
my $NaNOK=1;
# set to 1 for tracing
my $trace = 0;
# constants for easier life
my $nan = 'NaN';
my $BASE_LEN = 5;
my $BASE = int("1e".$BASE_LEN);		# var for trying to change it to 1e7
my $RBASE = 1e-5;			# see USE_MUL

# Rounding modes one of 'even', 'odd', '+inf', '-inf', 'zero' or 'trunc'
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
    if (ref($x->{$k}) eq 'ARRAY')
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
  # create a new BigInts object from a string or another bigint object. 
  # value => internal array representation 
  # sign  => sign (+/-), or "NaN"

  # the argument could be an object, so avoid ||, && etc on it, this would
  # cause costly overloaded code to be called. The only allowed op are ref() 
  # and definend.

  trace (@_);
  my $class = shift;
 
  my $wanted = shift; # avoid numify call by not using || here
  return $class->bzero() if !defined $wanted;	# default to 0
  return $class->copy($wanted) if ref($wanted);

  my $self = {}; bless $self, $class;
  # handle '+inf', '-inf' first
  if ($wanted =~ /^[+-]inf$/)
    {
    $self->{value} = [ 0 ];
    $self->{sign} = $wanted;
    return $self;
    }
  # split str in m mantissa, e exponent, i integer, f fraction, v value, s sign
  my ($mis,$miv,$mfv,$es,$ev) = _split(\$wanted);
  if (ref $mis && !ref $miv)
    {
    # _from_hex
    $self->{value} = $mis->{value};
    $self->{sign} = $mis->{sign};
    return $self;
    }
  if (!ref $mis)
    {
    die "$wanted is not a number initialized to $class" if !$NaNOK;
    #print "NaN 1\n";
    $self->{value} = [ 0 ];
    $self->{sign} = $nan;
    return $self;
    }
  # make integer from mantissa by adjusting exp, then convert to bigint
  $self->{sign} = $$mis;			# store sign
  $self->{value} = [ 0 ];			# for all the NaN cases
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
  $self->_internal($miv) if $self->{sign} ne $nan; 	# as internal array
  #print "$wanted => $self->{sign} $self->{value}->[0]\n";
  # if any of the globals is set, round to them and thus store them insid $self
  $self->round($accuracy,$precision,$rnd_mode)
   if defined $accuracy || defined $precision;
  return $self;
  }

# some shortcuts for easier life
sub bint
  {
  # exportable version of new
  trace(@_);
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
  $self->{value} = [ 0 ];
  $self->{sign} = $nan;
  trace('NaN');
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
  $self->{value} = [ 0 ];
  $self->{sign} = $sign.'inf';
  trace('inf');
  return $self;
  }

sub bzero
  {
  # create a bigint '+0', if given a BigInt, set it to 0
  my $self = shift;
  $self = $class if !defined $self;
  if (!ref($self))
    {
    my $c = $self; $self = {}; bless $self, $c;
    }
  return if $self->modify('bzero');
  $self->{value} = [ 0 ];
  $self->{sign} = '+';
  trace('0');
  return $self;
  }

##############################################################################
# string conversation

sub bsstr
  {
  # (ref to BFLOAT or num_str ) return num_str
  # Convert number from internal format to scientific string format.
  # internal format is always normalized (no leading zeros, "-0E0" => "+0E0")
  trace(@_);
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
  # (ref to BINT or num_str ) return num_str
  # Convert number from internal base 100000 format to string format.
  # internal format is always normalized (no leading zeros, "-0" => "+0")
  trace(@_);
  my $x = shift; $x = $class->new($x) unless ref $x;
  # my ($self,$x) = objectify(1,@_);

  return $x->{sign} if $x->{sign} !~ /^[+-]$/;
  my $ar = $x->{value} || return $nan;		# should not happen
  my $es = "";
  $es = $x->{sign} if $x->{sign} eq '-';	# get sign, but not '+'
  my $l = scalar @$ar;         # number of parts
  return $nan if $l < 1;       # should not happen   
  # handle first one different to strip leading zeros from it (there are no
  # leading zero parts in internal representation)
  $l --; $es .= $ar->[$l]; $l--; 
  # Interestingly, the pre-padd method uses more time
  # the old grep variant takes longer (14 to 10 sec)
  while ($l >= 0)
    {
    $es .= substr('0000'.$ar->[$l],-5);   # fastest way I could think of 
    $l--;
    }
  return $es;
  }

sub numify 
  {
  # Make a number from a BigInt object
  # old: simple return string and let Perl's atoi() handle the rest
  # new: calc because it is faster than bstr()+atoi()
  #trace (@_);
  #my ($self,$x) = objectify(1,@_);
  #return $x->bstr(); # ref($x); 
  my $x = shift; $x = $class->new($x) unless ref $x;

  return $nan if $x->{sign} eq $nan;
  my $fac = 1; $fac = -1 if $x->{sign} eq '-';
  return $fac*$x->{value}->[0] if @{$x->{value}} == 1;	# below $BASE
  my $num = 0;
  foreach (@{$x->{value}})
    {
    $num += $fac*$_; $fac *= $BASE;
    }
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
  return undef if (($x->{sign} eq $nan) || ($y->{sign} eq $nan));
  &cmp($x->{value},$y->{value},$x->{sign},$y->{sign}) <=> 0;
  }

sub bacmp 
  {
  # Compares 2 values, ignoring their signs. 
  # Returns one of undef, <0, =0, >0. (suitable for sort)
  # (BINT, BINT) return cond_code
  my ($self,$x,$y) = objectify(2,@_);
  return undef if (($x->{sign} eq $nan) || ($y->{sign} eq $nan));
  acmp($x->{value},$y->{value}) <=> 0;
  }

sub badd 
  {
  # add second arg (BINT or string) to first (BINT) (modifies first)
  # return result as BINT
  trace(@_);
  my ($self,$x,$y,$a,$p,$r) = objectify(2,@_);

  return $x if $x->modify('badd');
  return $x->bnan() if (($x->{sign} eq $nan) || ($y->{sign} eq $nan));

  # for round calls, make array
  my @bn = ($a,$p,$r,$y);
  # speed: no add for 0+y or x+0
  return $x->bnorm(@bn) if $y->is_zero();			# x+0
  if ($x->is_zero())						# 0+y
    {
    # make copy, clobbering up x
    $x->{value} = [ @{$y->{value}} ];
    $x->{sign} = $y->{sign} || $nan;
    return $x->round(@bn);
    }

  # shortcuts
  my $xv = $x->{value};
  my $yv = $y->{value};
  my ($sx, $sy) = ( $x->{sign}, $y->{sign} ); # get signs

  if ($sx eq $sy)  
    {
    add($xv,$yv);			# if same sign, absolute add
    $x->{sign} = $sx;
    }
  else 
    {
    my $a = acmp ($yv,$xv);		# absolute compare
    if ($a > 0)                           
      {
      #print "swapped sub (a=$a)\n";
      &sub($yv,$xv,1);			# absolute sub w/ swapped params
      $x->{sign} = $sy;
      } 
    elsif ($a == 0)
      {
      # speedup, if equal, set result to 0
      $x->{value} = [ 0 ];
      $x->{sign} = '+';
      }
    else # a < 0
      {
      #print "unswapped sub (a=$a)\n";
      &sub($xv, $yv);			# absolute sub
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

  trace(@_);
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
  trace(@_);
  return $x if $x->modify('binc');
  $x->badd($self->_one())->round($a,$p,$r);
  }

sub bdec
  {
  # decrement arg by one
  my ($self,$x,$a,$p,$r) = objectify(1,@_);
  trace(@_);
  return $x if $x->modify('bdec');
  $x->badd($self->_one('-'))->round($a,$p,$r);
  } 

sub blcm 
  { 
  # (BINT or num_str, BINT or num_str) return BINT
  # does not modify arguments, but returns new object
  # Lowest Common Multiplicator
  trace(@_);

  my ($self,@arg) = objectify(0,@_);
  my $x = $self->new(shift @arg);
  while (@arg) { $x = _lcm($x,shift @arg); } 
  $x;
  }

sub bgcd 
  { 
  # (BINT or num_str, BINT or num_str) return BINT
  # does not modify arguments, but returns new object
  # GCD -- Euclids algorithm, variant C (Knuth Vol 3, pg 341 ff)
  trace(@_);
  
  my ($self,@arg) = objectify(0,@_);
  my $x = $self->new(shift @arg); 
  while (@arg)
    {
    #$x = _gcd($x,shift @arg); last if $x->is_one(); # new fast, but is slower
    $x = _gcd_old($x,shift @arg); last if $x->is_one();	# old, slow, but faster
    } 
  $x;
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
  #trace(@_);
  my $x = shift; $x = $class->new($x) unless ref $x;
  return (@{$x->{value}} == 1) && ($x->{sign} eq '+') 
   && ($x->{value}->[0] == 0); 
  }

sub is_nan
  {
  # return true if arg (BINT or num_str) is NaN
  #my ($self,$x) = objectify(1,@_);
  #trace(@_);
  my $x = shift; $x = $class->new($x) unless ref $x;
  return ($x->{sign} eq $nan); 
  }

sub is_inf
  {
  # return true if arg (BINT or num_str) is +-inf
  #my ($self,$x) = objectify(1,@_);
  #trace(@_);
  my $x = shift; $x = $class->new($x) unless ref $x;
  my $sign = shift || '';

  return $x->{sign} =~ /^[+-]inf/ if $sign eq '';
  return $x->{sign} =~ /^[$sign]inf/;
  }

sub is_one
  {
  # return true if arg (BINT or num_str) is +1 (array '+', '1')
  # or -1 if signis given
  #my ($self,$x) = objectify(1,@_); 
  my $x = shift; $x = $class->new($x) unless ref $x;
  my $sign = shift || '+'; #$_[2] || '+';
  return (@{$x->{value}} == 1) && ($x->{sign} eq $sign) 
   && ($x->{value}->[0] == 1); 
  }

sub is_odd
  {
  # return true when arg (BINT or num_str) is odd, false for even
  my $x = shift; $x = $class->new($x) unless ref $x;
  #my ($self,$x) = objectify(1,@_);
  return (($x->{sign} ne $nan) && ($x->{value}->[0] & 1));
  }

sub is_even
  {
  # return true when arg (BINT or num_str) is even, false for odd
  my $x = shift; $x = $class->new($x) unless ref $x;
  #my ($self,$x) = objectify(1,@_);
  return (($x->{sign} ne $nan) && (!($x->{value}->[0] & 1)));
  }

sub bmul 
  { 
  # multiply two numbers -- stolen from Knuth Vol 2 pg 233
  # (BINT or num_str, BINT or num_str) return BINT
  my ($self,$x,$y,$a,$p,$r) = objectify(2,@_);
  #print "$self bmul $x ",ref($x)," $y ",ref($y),"\n";
  trace(@_);
  return $x if $x->modify('bmul');
  return $x->bnan() if (($x->{sign} eq $nan) || ($y->{sign} eq $nan));

  mul($x,$y);  # do actual math
  return $x->round($a,$p,$r,$y);
  }

sub bdiv 
  {
  # (dividend: BINT or num_str, divisor: BINT or num_str) return 
  # (BINT,BINT) (quo,rem) or BINT (only rem)
  trace(@_);
  my ($self,$x,$y,$a,$p,$r) = objectify(2,@_);

  return $x if $x->modify('bdiv');

  # NaN?
  return wantarray ? ($x->bnan(),bnan()) : $x->bnan()
   if ($x->{sign} eq $nan || $y->{sign} eq $nan || $y->is_zero());

  # 0 / something
  return wantarray ? ($x,$self->bzero()) : $x if $x->is_zero();
 
  # Is $x in the interval [0, $y) ?
  my $cmp = acmp($x->{value},$y->{value});
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
  if ((@{$y->{value}} == 1) && ($y->{value}->[0] == 1))
    {
    return wantarray ? ($x,$self->bzero()) : $x; 
    }

  # call div here 
  my $rem = $self->bzero(); 
  $rem->{sign} = $y->{sign};
  ($x->{value},$rem->{value}) = div($x->{value},$y->{value});
  # do not leave rest "-0";
  $rem->{sign} = '+' if (@{$rem->{value}} == 1) && ($rem->{value}->[0] == 0);
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
  #trace(@_);
  my ($self,$x,$y,$a,$p,$r) = objectify(2,@_);

  return $x if $x->modify('bpow');
 
  return $x->bnan() if $x->{sign} eq $nan || $y->{sign} eq $nan;
  return $x->_one() if $y->is_zero();
  return $x         if $x->is_one() || $y->is_one();
  if ($x->{sign} eq '-' && @{$x->{value}} == 1 && $x->{value}->[0] == 1)
    {
    # if $x == -1 and odd/even y => +1/-1
    return $y->is_odd() ? $x : $x->_set(1); # $x->babs() would work to
    # my Casio FX-5500L has here a bug, -1 ** 2 is -1, but -1 * -1 is 1 LOL
    }
  # shortcut for $x ** 2
  if ($y->{sign} eq '+' && @{$y->{value}} == 1 && $y->{value}->[0] == 2)
    {
    return $x->bmul($x)->bround($a,$p,$r);
    }
  # 1 ** -y => 1 / (1**y), so do test for negative $y after above's clause
  return $x->bnan() if $y->{sign} eq '-';
  return $x         if $x->is_zero();  # 0**y => 0 (if not y <= 0)

  # tels: 10**x is special (actually 100**x etc is special, too) but not here
  #if ((@{$x->{value}} == 1) && ($x->{value}->[0] == 10))
  #  {
  #  # 10**2
  #  my $yi = int($y); my $yi5 = int($yi/5);
  #  $x->{value} = [];		
  #  my $v = $x->{value};
  #  if ($yi5 > 0)
  #    { 
  #    # $x->{value}->[$yi5-1] = 0;		# pre-padd array (no use)
  #    for (my $i = 0; $i < $yi5; $i++)
  #      {
  #      $v->[$i] = 0;
  #      } 
  #    }
  #  push @{$v}, int( '1'.'0' x ($yi % 5));
  #  if ($x->{sign} eq '-')
  #    {
  #    $x->{sign} = $y->is_odd() ? '-' : '+';	# -10**2 = 100, -10**3 = -1000
  #    }
  #  return $x; 
  #  }

  # based on the assumption that shifting in base 10 is fast, and that bpow()
  # works faster if numbers are small: we count trailing zeros (this step is
  # O(1)..O(N), but in case of O(N) we save much more time), stripping them
  # out of the multiplication, and add $count * $y zeros afterwards:
  # 300 ** 3 == 300*300*300 == 3*3*3 . '0' x 2 * 3 == 27 . '0' x 6
  my $zeros = $x->_trailing_zeros();
  if ($zeros > 0)
    {
    $x->brsft($zeros,10);	# remove zeros
    $x->bpow($y);		# recursion (will not branch into here again)
    $zeros = $y * $zeros; 	# real number of zeros to add
    $x->blsft($zeros,10);
    return $x; 
    }

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
  if ($n != 10)
    {
    $x->bmul( $self->bpow($n, $y) );
    }
  else
    { 
    # shortcut (faster) for shifting by 10) since we are in base 10eX
    # multiples of 5:
    my $src = scalar @{$x->{value}};		# source
    my $len = $y->numify();			# shift-len as normal int
    my $rem = $len % 5;				# reminder to shift
    my $dst = $src + int($len/5);		# destination
    
    my $v = $x->{value};			# speed-up
    my $vd;					# further speedup
    #print "src $src:",$v->[$src]||0," dst $dst:",$v->[$dst]||0," rem $rem\n";
    $v->[$src] = 0;				# avoid first ||0 for speed
    while ($src >= 0)
      {
      $vd = $v->[$src]; $vd = '00000'.$vd;
      #print "s $src d $dst '$vd' ";
      $vd = substr($vd,-5+$rem,5-$rem);
      #print "'$vd' ";
      $vd .= $src > 0 ? substr('00000'.$v->[$src-1],-5,$rem) : '0' x $rem;
      #print "'$vd' ";
      $vd = substr($vd,-5,5) if length($vd) > 5;
      #print "'$vd'\n";
      $v->[$dst] = int($vd);
      $dst--; $src--; 
      }
    # set lowest parts to 0
    while ($dst >= 0) { $v->[$dst--] = 0; }
    # fix spurios last zero element
    splice @$v,-1 if $v->[-1] == 0;
    #print "elems: "; my $i = 0;
    #foreach (reverse @$v) { print "$i $_ "; $i++; } print "\n";
    # old way: $x->bmul( $self->bpow($n, $y) );
    }
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
  if ($n != 10)
    {
    scalar bdiv($x, $self->bpow($n, $y));
    }
  else
    { 
    # shortcut (faster) for shifting by 10)
    # multiples of 5:
    my $dst = 0;				# destination
    my $src = $y->numify();			# as normal int
    my $rem = $src % 5;				# reminder to shift	
    $src = int($src / 5);			# source
    my $len = scalar @{$x->{value}} - $src;	# elems to go
    my $v = $x->{value};			# speed-up
    if ($rem == 0)
      {
      splice (@$v,0,$src);			# even faster, 38.4 => 39.3
      }
    else
      {
      my $vd;
      $v->[scalar @$v] = 0;			# avoid || 0 test inside loop
      while ($dst < $len)
        {
        $vd = '00000'.$v->[$src];
        #print "$dst $src '$vd' ";
        $vd = substr($vd,-5,5-$rem);
        #print "'$vd' ";
        $src++; 
        $vd = substr('00000'.$v->[$src],-$rem,$rem) . $vd;
        #print "'$vd1' ";
        #print "'$vd'\n";
        $vd = substr($vd,-5,5) if length($vd) > 5;
        $v->[$dst] = int($vd);
        $dst++; 
        }
      splice (@$v,$dst) if $dst > 0;		# kill left-over array elems
      pop @$v if $v->[-1] == 0;			# kill last element
      } # else rem == 0
    # old way: scalar bdiv($x, $self->bpow($n, $y));
    }
  return $x;
  }

sub band 
  {
  #(BINT or num_str, BINT or num_str) return BINT
  # compute x & y
  trace(@_);
  my ($self,$x,$y) = objectify(2,@_);
  
  return $x if $x->modify('band');

  return $x->bnan() if ($x->{sign} !~ /^[+-]$/ || $y->{sign} !~ /^[+-]$/);
  return $x->bzero() if $y->is_zero();
  my $r = $self->bzero(); my $m = new Math::BigInt 1; my ($xr,$yr);
  my $x10000 = new Math::BigInt (0x10000);
  my $y1 = copy(ref($x),$y);		 		# make copy
  while (!$x->is_zero() && !$y1->is_zero())
    {
    ($x, $xr) = bdiv($x, $x10000);
    ($y1, $yr) = bdiv($y1, $x10000);
    $r->badd( bmul( new Math::BigInt ( $xr->numify() & $yr->numify()), $m ));
    $m->bmul($x10000);
    }
  $x = $r;
  }

sub bior 
  {
  #(BINT or num_str, BINT or num_str) return BINT
  # compute x | y
  trace(@_);
  my ($self,$x,$y) = objectify(2,@_);

  return $x if $x->modify('bior');

  return $x->bnan() if ($x->{sign} !~ /^[+-]$/ || $y->{sign} !~ /^[+-]$/);
  return $x if $y->is_zero();
  my $r = $self->bzero(); my $m = new Math::BigInt 1; my ($xr,$yr);
  my $x10000 = new Math::BigInt (0x10000);
  my $y1 = copy(ref($x),$y);		 		# make copy
  while (!$x->is_zero() || !$y1->is_zero())
    {
    ($x, $xr) = bdiv($x,$x10000);
    ($y1, $yr) = bdiv($y1,$x10000);
    $r->badd( bmul( new Math::BigInt ( $xr->numify() | $yr->numify()), $m ));
    $m->bmul($x10000);
    }
  $x = $r;
  }

sub bxor 
  {
  #(BINT or num_str, BINT or num_str) return BINT
  # compute x ^ y
  my ($self,$x,$y) = objectify(2,@_);

  return $x if $x->modify('bxor');

  return $x->bnan() if ($x->{sign} eq $nan || $y->{sign} eq $nan);
  return $x if $y->is_zero();
  return $x->bzero() if $x == $y; # shortcut
  my $r = $self->bzero(); my $m = new Math::BigInt 1; my ($xr,$yr);
  my $x10000 = new Math::BigInt (0x10000);
  my $y1 = copy(ref($x),$y);	 		# make copy
  while (!$x->is_zero() || !$y1->is_zero())
    {
    ($x, $xr) = bdiv($x, $x10000);
    ($y1, $yr) = bdiv($y1, $x10000);
    $r->badd( bmul( new Math::BigInt ( $xr->numify() ^ $yr->numify()), $m ));
    $m->bmul($x10000);
    }
  $x = $r;
  }

sub length
  {
  my ($self,$x) = objectify(1,@_);

  return (_digits($x->{value}), 0) if wantarray;
  _digits($x->{value});
  }

sub digit
  {
  # return the nth digit, negative values count backward
  my $x = shift;
  my $n = shift || 0; 

  my $len = $x->length();

  $n = $len+$n if $n < 0;		# -1 last, -2 second-to-last
  $n = abs($n);				# if negatives are to big
  $len--; $n = $len if $n > $len;	# n to big?
  
  my $elem = int($n / 5);		# which array element
  my $digit = $n % 5;			# which digit in this element
  $elem = '0000'.$x->{value}->[$elem];	# get element padded with 0's
  return substr($elem,-$digit-1,1);
  }

sub _trailing_zeros
  {
  # return the amount of trailing zeros in $x
  my $x = shift;
  $x = $class->new($x) unless ref $x;

  return 0 if $x->is_zero() || $x->is_nan();
  # check each array elem in _m for having 0 at end as long as elem == 0
  # Upon finding a elem != 0, stop
  my $zeros = 0; my $elem;
  foreach my $e (@{$x->{value}})
    {
    if ($e != 0)
      {
      $elem = "$e";				# preserve x
      $elem =~ s/.*?(0*$)/$1/;			# strip anything not zero
      $zeros *= 5;				# elems * 5
      $zeros += CORE::length($elem);		# count trailing zeros
      last;					# early out
      }
    $zeros ++;					# real else branch: 50% slower!
    }
  return $zeros;
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
 
  my $len = $x->length();
  return 0 if $len == 1;		# '5' is trailed by invisible zeros
  my $follow = $pad - 1;
  return 0 if $follow > $len || $follow < 1;
  #print "checking $x $r\n";
  # old, slow way checking string for non-zero characters
  my $r = substr ("$x",-$follow);
  return 1 if $r =~ /[^0]/; return 0;
  
  # faster way checking array contents; it is actually not faster (even in a
  # rounding-only-shoutout, so I leave the simpler code in)
  #my $rem = $follow % 5; my $div = $follow / 5; my $v = $x->{value};
  # pad with zeros and extract
  #print "last part : ",'00000'.$v->[$div]," $rem = '";
  #print substr('00000'.$v->[$div],-$rem,5),"'\n";
  #my $r1 = substr ('00000'.$v->[$div],-$rem,5);
  #print "$r1\n"; 
  #return 1 if $r1 =~ /[^0]/;
  #
  #for (my $j = $div-1; $j >= 0; $j --)
  #  {
  #  #print "part $v->[$j]\n";
  #  return 1 if $v->[$j] != 0;
  #  }
  #return 0;
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
  $digit_round = '0'; $digit_round = $x->digit($pad) if $pad < $len;
  $digit_after = '0'; $digit_after = $x->digit($pad-1) if $pad > 0;
  # print "r $x: pos:$pad l:$len s:$scale r:$digit_round a:$digit_after m: $mode\n";

  # in case of 01234 we round down, for 6789 up, and only in case 5 we look
  # closer at the remaining digits of the original $x, remember decision
  my $round_up = 1;					# default round up
  $round_up -- if
    ($mode eq 'trunc')				||	# trunc by round down
    ($digit_after =~ /[01234]/)			|| 	# round down anyway,
							# 6789 => round up
    ($digit_after eq '5')			&&	# not 5000...0000
    ($x->_scan_for_nonzero($pad) == 0)		&&
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
    # split mantissa at $scale and then pad with zeros
    my $s5 = int($pad / 5);
    my $i = 0;
    while ($i < $s5)
      {
      $x->{value}->[$i++] = 0;				# replace with 5 x 0
      }
    $x->{value}->[$s5] = '00000'.$x->{value}->[$s5];	# pad with 0
    my $rem = $pad % 5;					# so much left over
    if ($rem > 0)
      {
      #print "remainder $rem\n";
      #print "elem      $x->{value}->[$s5]\n";
      substr($x->{value}->[$s5],-$rem,$rem) = '0' x $rem;	# stamp w/ '0'
      }
    $x->{value}->[$s5] = int ($x->{value}->[$s5]);	# str '05' => int '5'
    }
  if ($round_up)					# what gave test above?
    {
    $pad = $len if $scale < 0;				# tlr: whack 0.51=>1.0	
    # modify $x in place, undef, undef to avoid rounding
    $x->badd( Math::BigInt->new($x->{sign}.'1'.'0'x$pad),
     undef,undef );					
    # str creation much faster than 10 ** something
    }
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

sub trace
  {
  # print out a number without using bstr (avoid deep recurse) for trace/debug
  return unless $trace;

  my ($package,$file,$line,$sub) = caller(1); 
  print "'$sub' called from '$package' line $line:\n ";

  foreach my $x (@_)
    {
    if (!defined $x) 
      {
      print "undef, "; next;
      }
    if (!ref($x)) 
      {
      print "'$x' "; next;
      }
    next if (ref($x) ne "HASH");
    print "$x->{sign} ";
    foreach (@{$x->{value}})
      {
      print "$_ ";
      }
    print ", ";
    }
  print "\n";
  }

sub _set
  {
  # internal set routine to set X fast to an integer value < [+-]100000
  my $self = shift;
  my $wanted = shift || 0;

  $self->{sign} = $nan, return if $wanted !~ /^[+-]?[0-9]+$/;
  $self->{sign} = '-'; $self->{sign} = '+' if $wanted >= 0;
  $self->{value} = [ abs($wanted) ];
  return $self;
  }

sub _one
  {
  # internal speedup, set argument to 1, or create a +/- 1
  my $self = shift;
  my $x = $self->bzero(); $x->{value} = [ 1 ]; $x->{sign} = shift || '+'; $x;
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
  # $class,1,2. (We can not take '1' as class ;o)
  # badd($class,1) is not supported (it should, eventually, try to add undef)
  # currently it tries 'Math::BigInt' + 1, which will not work.
 
  trace(@_); 
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
  for ( my $i = 0; $i < @_ ; $i++ )
    {
    if ( $_[$i] eq ':constant' )
      {
      # this rest causes overlord er load to step in
      overload::constant integer => sub { $self->new(shift) };
      splice @_, $i, 1; last;
      }
    }
  # any non :constant stuff is handled by our parent, Exporter
  # even if @_ is empty, to give it a chance 
  #$self->SUPER::import(@_);			# does not work
  $self->export_to_level(1,$self,@_);		# need this instead
  }

sub _internal 
  { 
  # (ref to self, ref to string) return ref to num_array
  # Convert a number from string format to internal base 100000 format.
  # Assumes normalized value as input.
  my ($s,$d) = @_;
  my $il = CORE::length($$d)-1;
  # these leaves '00000' instead of int 0 and will be corrected after any op
  $s->{value} = [ reverse(unpack("a" . ($il%5+1) . ("a5" x ($il/5)), $$d)) ];
  $s;
  }

sub _strip_zeros
  {
  # internal normalization function that strips leading zeros from the array
  # args: ref to array
  #trace(@_);
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

  my $mul = Math::BigInt->bzero(); $mul++;
  my $x65536 = Math::BigInt->new(65536);

  my $len = CORE::length($$hs)-2; my $sign = '+';
  if ($$hs =~ /^\-/)
    {
    $sign = '-'; $len--;
    }
  $len = int($len/4);				# 4-digit parts, w/o '0x'
  my $val; my $i = -4;
  while ($len >= 0)
    {
    $val = substr($$hs,$i,4);
    $val =~ s/^[\-\+]?0x// if $len == 0;	# for last part only because
    $val = hex($val); 				# hex does not like wrong chars
    # print "$val ",substr($$hs,$i,4),"\n";
    $i -= 4; $len --;
    $x += $mul * $val if $val != 0;
    $mul *= $x65536 if $len >= 0;		# skip last mul
    }
  $x->{sign} = $sign if !$x->is_zero();
  return $x;
  }

sub _from_bin
  {
  # convert a (ref to) big binary string to BigInt, return undef for error
  my $bs = shift;

  my $x = Math::BigInt->bzero();
  return $x->bnan() if $$bs !~ /^[\-\+]?0b[01]+$/;

  my $mul = Math::BigInt->bzero(); $mul++;
  my $x256 = Math::BigInt->new(256);

  my $len = CORE::length($$bs)-2; my $sign = '+';
  if ($$bs =~ /^\-/)
    {
    $sign = '-'; $len--;
    }
  $len = int($len/8);				# 8-digit parts, w/o '0b'
  my $val; my $i = -8;
  while ($len >= 0)
    {
    $val = substr($$bs,$i,8);
    $val =~ s/^[\-\+]?0b// if $len == 0;	# for last part only
    #$val = oct('0b'.$val);	# does not work on Perl prior 5.6.0
    $val = ('0' x (8-CORE::length($val))).$val if CORE::length($val) < 8;
    $val = ord(pack('B8',$val));
    # print "$val ",substr($$bs,$i,16),"\n";
    $i -= 8; $len --;
    $x += $mul * $val if $val != 0;
    $mul *= $x256 if $len >= 0;			# skip last mul
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
      #print "$mis $miv";
      # valid, existing fraction part of mantissa?
      return unless ($mf =~ /^(\d*?)0*$/);	# strip trailing zeros
      $mfv = $1;
      #print " split: $mis $miv . $mfv E $es $ev\n";
      return (\$mis,\$miv,\$mfv,\$es,\$ev);
      }
    }
  return; # NaN, not a number
  }

sub _digits
  {
  # computer number of digits in bigint, minus the sign
  # int() because add/sub leaves sometimes strings (like '00005') instead of
  # int ('5') in this place, causing length to fail
  my $cx = shift;

  #print "len: ",(@$cx-1)*5+CORE::length(int($cx->[-1])),"\n";
  return (@$cx-1)*5+CORE::length(int($cx->[-1]));
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
# internal calculation routines

sub acmp
  {
  # internal absolute post-normalized compare (ignore signs)
  # ref to array, ref to array, return <0, 0, >0
  # arrays must have at least on entry, this is not checked for

  my ($cx, $cy) = @_;

  #print "$cx $cy\n"; 
  my ($i,$a,$x,$y,$k);
  # calculate length based on digits, not parts
  $x = _digits($cx); $y = _digits($cy);
  # print "length: ",($x-$y),"\n";
  return $x-$y if ($x - $y);              # if different in length
  #print "full compare\n";
  $i = 0; $a = 0;
  # first way takes 5.49 sec instead of 4.87, but has the early out advantage
  # so grep is slightly faster, but more unflexible. hm. $_ instead if $k
  # yields 5.6 instead of 5.5 sec huh?
  # manual way (abort if unequal, good for early ne)
  my $j = scalar @$cx - 1;
  while ($j >= 0)
   {
   # print "$cx->[$j] $cy->[$j] $a",$cx->[$j]-$cy->[$j],"\n";
   last if ($a = $cx->[$j] - $cy->[$j]); $j--;
   }
  return $a;
  # while it early aborts, it is even slower than the manual variant
  #grep { return $a if ($a = $_ - $cy->[$i++]); } @$cx;
  # grep way, go trough all (bad for early ne)
  #grep { $a = $_ - $cy->[$i++]; } @$cx;
  #return $a;
  }

sub cmp 
  {
  # post-normalized compare for internal use (honors signs)
  # ref to array, ref to array, return < 0, 0, >0
  my ($cx,$cy,$sx,$sy) = @_;

  #return 0 if (is0($cx,$sx) && is0($cy,$sy));

  if ($sx eq '+') 
    {
    return 1 if $sy eq '-'; # 0 check handled above
    return acmp($cx,$cy);
    }
  else
    {
    # $sx eq '-'
    return -1 if ($sy eq '+');
    return acmp($cy,$cx);
    }
  return 0; # equal
  }

sub add 
  {
  # (ref to int_num_array, ref to int_num_array)
  # routine to add two base 1e5 numbers
  # stolen from Knuth Vol 2 Algorithm A pg 231
  # there are separate routines to add and sub as per Kunth pg 233
  # This routine clobbers up array x, but not y. 

  my ($x,$y) = @_;

  # for each in Y, add Y to X and carry. If after that, something is left in
  # X, foreach in X add carry to X and then return X, carry
  # Trades one "$j++" for having to shift arrays, $j could be made integer
  # but this would impose a limit to number-length to 2**32.
  my $i; my $car = 0; my $j = 0;
  for $i (@$y)
    {
    $x->[$j] -= $BASE 
      if $car = (($x->[$j] += $i + $car) >= $BASE) ? 1 : 0; 
    $j++;
    }
  while ($car != 0)
    {
    $x->[$j] -= $BASE if $car = (($x->[$j] += $car) >= $BASE) ? 1 : 0; $j++;
    }
  }

sub sub
  {
  # (ref to int_num_array, ref to int_num_array)
  # subtract base 1e5 numbers -- stolen from Knuth Vol 2 pg 232, $x > $y
  # subtract Y from X (X is always greater/equal!) by modifiyng x in place
  my ($sx,$sy,$s) = @_;

  my $car = 0; my $i; my $j = 0;
  if (!$s)
    {
    #print "case 2\n";
    for $i (@$sx)
      {
      last unless defined $sy->[$j] || $car;
      #print "x: $i y: $sy->[$j] c: $car\n";
      $i += $BASE if $car = (($i -= ($sy->[$j] || 0) + $car) < 0); $j++;
      #print "x: $i y: $sy->[$j-1] c: $car\n";
      }
    # might leave leading zeros, so fix that
    _strip_zeros($sx);
    return $sx;
    }
  else
    { 
    #print "case 1 (swap)\n";
    for $i (@$sx)
      {
      last unless defined $sy->[$j] || $car;
      #print "$sy->[$j] $i $car => $sx->[$j]\n";
      $sy->[$j] += $BASE
       if $car = (($sy->[$j] = $i-($sy->[$j]||0) - $car) < 0); 
      #print "$sy->[$j] $i $car => $sy->[$j]\n";
      $j++;
      }
    # might leave leading zeros, so fix that
    _strip_zeros($sy);
    return $sy;
    }
  }
    
sub mul 
  {
  # (BINT, BINT) return nothing
  # multiply two numbers in internal representation
  # modifies first arg, second needs not be different from first
  my ($x,$y) = @_;

  $x->{sign} = $x->{sign} ne $y->{sign} ? '-' : '+';
  my @prod = (); my ($prod,$car,$cty,$xi,$yi);
  my $xv = $x->{value};
  my $yv = $y->{value};
  # since multiplying $x with $x fails, make copy in this case
  $yv = [@$xv] if "$xv" eq "$yv";
  for $xi (@$xv) 
    {
    $car = 0; $cty = 0;
    for $yi (@$yv)  
      {
      $prod = $xi * $yi + ($prod[$cty] || 0) + $car;
      $prod[$cty++] =
       $prod - ($car = int($prod * 1e-5)) * $BASE;	# see USE_MUL
      }
    $prod[$cty] += $car if $car; # need really to check for 0?
    $xi = shift @prod;
    }
  push @$xv, @prod;
  _strip_zeros($x->{value});
  # normalize (handled last to save check for $y->is_zero()
  $x->{sign} = '+' if @$xv == 1 && $xv->[0] == 0; # not is_zero due to '-' 
  }

sub div
  {
  # ref to array, ref to array, modify first array and return reminder if 
  # in list context
  # does no longer handle sign
  my ($x,$yorg) = @_;
  my ($car,$bar,$prd,$dd,$xi,$yi,@q,$v2,$v1);

  my (@d,$tmp,$q,$u2,$u1,$u0);

  $car = $bar = $prd = 0;
  
  my $y = [ @$yorg ];
  if (($dd = int($BASE/($y->[-1]+1))) != 1) 
    {
    for $xi (@$x) 
      {
      $xi = $xi * $dd + $car;
      $xi -= ($car = int($xi * $RBASE)) * $BASE;	# see USE_MUL
      }
    push(@$x, $car); $car = 0;
    for $yi (@$y) 
      {
      $yi = $yi * $dd + $car;
      $yi -= ($car = int($yi * $RBASE)) * $BASE;	# see USE_MUL
      }
    }
  else 
    {
    push(@$x, 0);
    }
  @q = (); ($v2,$v1) = @$y[-2,-1];
  $v2 = 0 unless $v2;
  while ($#$x > $#$y) 
    {
    ($u2,$u1,$u0) = @$x[-3..-1];
    $u2 = 0 unless $u2;
    print "oups v1 is 0, u0: $u0 $y->[-2] $y->[-1] l ",scalar @$y,"\n"
     if $v1 == 0;
    $q = (($u0 == $v1) ? 99999 : int(($u0*$BASE+$u1)/$v1));
    --$q while ($v2*$q > ($u0*1e5+$u1-$q*$v1)*$BASE+$u2);
    if ($q)
      {
      ($car, $bar) = (0,0);
      for ($yi = 0, $xi = $#$x-$#$y-1; $yi <= $#$y; ++$yi,++$xi) 
        {
        $prd = $q * $y->[$yi] + $car;
        $prd -= ($car = int($prd * $RBASE)) * $BASE;	# see USE_MUL
	$x->[$xi] += 1e5 if ($bar = (($x->[$xi] -= $prd + $bar) < 0));
	}
      if ($x->[-1] < $car + $bar) 
        {
        $car = 0; --$q;
	for ($yi = 0, $xi = $#$x-$#$y-1; $yi <= $#$y; ++$yi,++$xi) 
          {
	  $x->[$xi] -= 1e5
	   if ($car = (($x->[$xi] += $y->[$yi] + $car) > $BASE));
	  }
	}   
      }
      pop(@$x); unshift(@q, $q);
    }
  if (wantarray) 
    {
    @d = ();
    if ($dd != 1)  
      {
      $car = 0; 
      for $xi (reverse @$x) 
        {
        $prd = $car * $BASE + $xi;
        $car = $prd - ($tmp = int($prd / $dd)) * $dd; # see USE_MUL
        unshift(@d, $tmp);
        }
      }
    else 
      {
      @d = @$x;
      }
    @$x = @q;
    _strip_zeros($x); 
    _strip_zeros(\@d);
    return ($x,\@d);
    }
  @$x = @q;
  _strip_zeros($x); 
  return $x;
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

sub _gcd_old
  { 
  # (BINT or num_str, BINT or num_str) return BINT
  # does modify first arg
  # GCD -- Euclids algorithm E, Knuth Vol 2 pg 296
  trace(@_);
 
  my $x = shift; my $ty = $class->new(shift); # preserve y
  return $x->bnan() if ($x->{sign} eq $nan) || ($ty->{sign} eq $nan);

  while (!$ty->is_zero())
    {
    ($x, $ty) = ($ty,bmod($x,$ty));
    }
  $x;
  }

sub _gcd 
  { 
  # (BINT or num_str, BINT or num_str) return BINT
  # does not modify arguments
  # GCD -- Euclids algorithm, variant L (Lehmer), Knuth Vol 3 pg 347 ff
  # unfortunately, it is slower and also seems buggy (the A=0, B=1, C=1, D=0
  # case..)
  trace(@_);
 
  my $u = $class->new(shift); my $v = $class->new(shift);	# preserve u,v
  return $u->bnan() if ($u->{sign} eq $nan) || ($v->{sign} eq $nan);
  
  $u->babs(); $v->babs();		# Euclid is valid for |u| and |v|

  my ($U,$V,$A,$B,$C,$D,$T,$Q);		# single precision variables
  my ($t);				# multiprecision variables

  while ($v > $BASE)
    {
    #sleep 1;
    ($u,$v) = ($v,$u) if ($u < $v); 		# make sure that u >= v
    #print "gcd: $u $v\n";
    # step L1, initialize
    $A = 1; $B = 0; $C = 0; $D = 1;
    $U = $u->{value}->[-1];			# leading digits of u
    $V = $v->{value}->[-1];			# leading digits of v
      
    # step L2, test quotient
    if (($V + $C != 0) && ($V + $D != 0))	# div by zero => go to L4
      {
      $Q = int(($U + $A)/($V + $C));		# quotient
      #print "L1 A=$A B=$B C=$C D=$D U=$U V=$V Q=$Q\n";
      # do L3? (div by zero => go to L4)
      while ($Q == int(($U + $B)/($V + $D)))
        {
        # step L3, emulate Euclid
        #print "L3a A=$A B=$B C=$C D=$D U=$U V=$V Q=$Q\n";
        $T = $A - $Q*$C; $A = $C; $C = $T;
        $T = $B - $Q*$D; $B = $D; $D = $T;
        $T = $U - $Q*$V; $U = $V; $V = $T;
        last if ($V + $D == 0) || ($V + $C == 0);	# div by zero => L4
        $Q = int(($U + $A)/($V + $C));	# quotient for next test
        #print "L3b A=$A B=$B C=$C D=$D U=$U V=$V Q=$Q\n";
        }
      }
    # step L4, multiprecision step
    # was if ($B == 0)
    # in case A = 0, B = 1, C = 0 and D = 1, this case would simple swap u & v
    # and loop endless. Not sure why this happens, Knuth does not make a
    # remark about this special case. bug?
    if (($B == 0) || (($A == 0) && ($C == 1) && ($D == 0)))
      {
      #print "L4b1: u=$u v=$v\n";
      ($u,$v) = ($v,bmod($u,$v)); 
      #$t = $u % $v; $u = $v->copy(); $v = $t;
      #print "L4b12: u=$u v=$v\n";
      }
    else
      {
      #print "L4b: $u $v $A $B $C $D\n";
      $t = $A*$u + $B*$v; $v *= $D; $v += $C*$u; $u = $t;
      #print "L4b2: $u $v\n";
      }
    } # back to L1

  return _gcd_old($u,$v) if $v != 1;	# v too small
  return $v;				# 1
  }

###############################################################################
# this method return 0 if the object can be modified, or 1 for not
# We use a fast use constant statement here, to avoid costly calls. Subclasses
# may override it with special code (f.i. Math::BigInt::Constant does so)

use constant modify => 0;

#sub modify
#  {
#  my $self = shift;
#  my $method = shift;
#  print "original $self modify by $method\n";
#  return 0; # $self;
#  }

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
  $x->is_one();			# return true if arg is +1
  $x->is_one('-');		# return true if arg is -1
  $x->is_odd();			# return true if odd, false for even
  $x->is_even();		# return true if even, false for odd
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

=head2 Rounding

Only C<bround()> is defined for BigInts, for further details of rounding see
L<Math::BigFloat>.

=over 2

=item bfround ( +$scale ) rounds to the $scale'th place left from the '.'

=item bround  ( +$scale ) preserves accuracy to $scale sighnificant digits counted from the left and paddes the number with zeros

=item bround  ( -$scale ) preserves accuracy to $scale significant digits counted from the right and paddes the number with zeros.

=back

C<bfround()> does nothing in case of negative C<$scale>. Both C<bround()> and
C<bfround()> are a no-ops for a scale of 0.

All rounding functions take as a second parameter a rounding mode from one of
the following: 'even', 'odd', '+inf', '-inf', 'zero' or 'trunc'.

The default is 'even'. By using C<< Math::BigInt->round_mode($rnd_mode); >>
you can get and set the default round mode for subsequent rounding. 

The second parameter to the round functions than overrides the default
temporarily.

=head2 Internals

Actual math is done in an internal format consisting of an array of
elements of base 100000 digits with the least significant digit first.
The sign C</^[+-]$/> is stored separately. The string 'NaN' is used to 
represent the result when input arguments are not numbers, as well as 
the result of dividing by zero.

You sould neither care nor depend on the internal represantation, it might
change without notice. Use only method calls like C<< $x->sign(); >> instead
relying on the internal hash keys like in C<< $x->{sign}; >>. 

=head2 mantissa(), exponent() and parts()

C<mantissa()> and C<exponent()> return the said parts of the BigInt such
that:

        $m = $x->mantissa();
        $e = $x->exponent();
        $y = $m * ( 10 ** $e );
        print "ok\n" if $x == $y;

C<($m,$e) = $x->parts()> is just a shortcut that gives you both of them in one
go. Both the returned mantissa and exponent do have a sign.

Currently, for BigInts C<$e> will be always 0, except for NaN where it will be
NaN and for $x == 0, then it will be 1 (to be compatible with Math::BigFlaot's
internal representation of a zero as C<0E1>).

C<$m> will always be a copy of the original number. The relation between $e
and $m might change in the future, but will be always equivalent in a
numerical sense, e.g. $m might get minized.
 
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

=head1 Autocreating constants

After C<use Math::BigInt ':constant'> all the B<integer> decimal constants
in the given scope are converted to C<Math::BigInt>. This conversion
happens at compile time.

In particular

  perl -MMath::BigInt=:constant -e 'print 2**100,"\n"'

prints the integer value of C<2**100>.  Note that without conversion of 
constants the expression 2**100 will be calculated as floating point 
number.

Please note that strings and floating point constants are not affected,
so that

  	use Math::BigInt qw/:constant/;

	$x = 1234567890123456789012345678901234567890
		+ 123456789123456789;
	$x = '1234567890123456789012345678901234567890'
		+ '123456789123456789';

do both not work. You need a explicit Math::BigInt->new() around one of them.

=head1 PERFORMANCE

Using the form $x += $y; etc over $x = $x + $y is faster, since a copy of $x
must be made in the second case. For long numbers, the copy can eat up to 20%
of the work (in case of addition/subtraction, less for
multiplication/division). If $y is very small compared to $x, the form
$x += $y is MUCH faster than $x = $x + $y since making the copy of $x takes
more time then the actual addition.

With a technic called copy-on-write the cost of copying with overload could
be minimized or even completely avoided. This is currently not implemented.

The new version of this module is slower on new(), bstr() and numify(). Some
operations may be slower for small numbers, but are significantly faster for
big numbers. Other operations are now constant (O(1), like bneg(), babs()
etc), instead of O(N) and thus nearly always take much less time.

For more benchmark results see http://bloodgate.com/perl/benchmarks.html

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

See also the documentation in L<overload> regarding C<=>.

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
This makes a copy of $x and takes O(N). But $x->bneg() is O(1).

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

Beware of the order of more complicated expressions like:

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

=head1 AUTHORS

Original code by Mark Biggar, overloaded interface by Ilya Zakharevich.
Completely rewritten by Tels http://bloodgate.com in late 2000, 2001.

=cut

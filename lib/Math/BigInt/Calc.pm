package Math::BigInt::Calc;

use 5.005;
use strict;
# use warnings;	# dont use warnings for older Perls

require Exporter;

use vars qw/ @ISA @EXPORT $VERSION/;
@ISA = qw(Exporter);

@EXPORT = qw(
	_add _mul _div _mod _sub
	_new
	_str _num _acmp _len
	_digit
	_is_zero _is_one
	_is_even _is_odd
	_check _zero _one _copy _zeros
        _rsft _lsft
);
$VERSION = '0.09';

# Package to store unsigned big integers in decimal and do math with them

# Internally the numbers are stored in an array with at least 1 element, no
# leading zero parts (except the first) and in base 100000 

# todo:
# - fully remove funky $# stuff (maybe)
# - use integer; vs 1e7 as base 

# USE_MUL: due to problems on certain os (os390, posix-bc) "* 1e-5" is used
# instead of "/ 1e5" at some places, (marked with USE_MUL). But instead of
# using the reverse only on problematic machines, I used it everytime to avoid
# the costly comparisons. This _should_ work everywhere. Thanx Peter Prymmer

##############################################################################
# global constants, flags and accessory
 
# constants for easier life
my $nan = 'NaN';

my $BASE_LEN = 7;
my $BASE = int("1e".$BASE_LEN);		# var for trying to change it to 1e7
my $RBASE = abs('1e-'.$BASE_LEN);	# see USE_MUL

BEGIN
  {
  # Daniel Pfeiffer: determine largest group of digits that is precisely
  # multipliable with itself plus carry
  my ($e, $num) = 4;
  do {
     $num = ('9' x ++$e) + 0;
    $num *= $num + 1;
  } until ($num == $num - 1 or $num - 1 == $num - 2);
  $BASE_LEN = $e-1;
  $BASE = int("1e".$BASE_LEN);
  $RBASE = abs('1e-'.$BASE_LEN);	# see USE_MUL
  }

# for quering and setting, to debug/benchmark things
sub _base_len 
  {
  my $b = shift;
  if (defined $b)
    {
    $BASE_LEN = $b;
    $BASE = int("1e".$BASE_LEN);
    $RBASE = abs('1e-'.$BASE_LEN);	# see USE_MUL
    }
  $BASE_LEN;
  }

##############################################################################
# create objects from various representations

sub _new
  {
  # (string) return ref to num_array
  # Convert a number from string format to internal base 100000 format.
  # Assumes normalized value as input.
  my $d = $_[1];
  # print "_new $d $$d\n";
  my $il = CORE::length($$d)-1;
  # these leaves '00000' instead of int 0 and will be corrected after any op
  return [ reverse(unpack("a" . ($il % $BASE_LEN+1) 
    . ("a$BASE_LEN" x ($il / $BASE_LEN)), $$d)) ];
  }                                                                             

sub _zero
  {
  # create a zero
  return [ 0 ];
  }

sub _one
  {
  # create a one
  return [ 1 ];
  }

sub _copy
  {
  return [ @{$_[1]} ];
  }

##############################################################################
# convert back to string and number

sub _str
  {
  # (ref to BINT) return num_str
  # Convert number from internal base 100000 format to string format.
  # internal format is always normalized (no leading zeros, "-0" => "+0")
  my $ar = $_[1];
  my $ret = "";
  my $l = scalar @$ar;         # number of parts
  return $nan if $l < 1;       # should not happen
  # handle first one different to strip leading zeros from it (there are no
  # leading zero parts in internal representation)
  $l --; $ret .= $ar->[$l]; $l--;
  # Interestingly, the pre-padd method uses more time
  # the old grep variant takes longer (14 to 10 sec)
  my $z = '0' x ($BASE_LEN-1);                            
  while ($l >= 0)
    {
    $ret .= substr($z.$ar->[$l],-$BASE_LEN); # fastest way I could think of
    $l--;
    }
  return \$ret;
  }                                                                             

sub _num
  {
  # Make a number (scalar int/float) from a BigInt object
  my $x = $_[1];
  return $x->[0] if scalar @$x == 1;  # below $BASE
  my $fac = 1;
  my $num = 0;
  foreach (@$x)
    {
    $num += $fac*$_; $fac *= $BASE;
    }
  return $num; 
  }

##############################################################################
# actual math code

sub _add
  {
  # (ref to int_num_array, ref to int_num_array)
  # routine to add two base 1eX numbers
  # stolen from Knuth Vol 2 Algorithm A pg 231
  # there are separate routines to add and sub as per Knuth pg 233
  # This routine clobbers up array x, but not y.
 
  my ($c,$x,$y) = @_;
 
  # for each in Y, add Y to X and carry. If after that, something is left in
  # X, foreach in X add carry to X and then return X, carry
  # Trades one "$j++" for having to shift arrays, $j could be made integer
  # but this would impose a limit to number-length of 2**32.
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
    return $x;
  }                                                                             

sub _sub
  {
  # (ref to int_num_array, ref to int_num_array)
  # subtract base 1eX numbers -- stolen from Knuth Vol 2 pg 232, $x > $y
  # subtract Y from X (X is always greater/equal!) by modifying x in place
  my ($c,$sx,$sy,$s) = @_;
 
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
    __strip_zeros($sx);
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
    __strip_zeros($sy);
    return $sy;
    }
  }                                                                             

sub _mul
  {
  # (BINT, BINT) return nothing
  # multiply two numbers in internal representation
  # modifies first arg, second need not be different from first
  my ($c,$xv,$yv) = @_;
 
  my @prod = (); my ($prod,$car,$cty,$xi,$yi);
  # since multiplying $x with $x fails, make copy in this case
  $yv = [@$xv] if "$xv" eq "$yv";	# same references?
  for $xi (@$xv)
    {
    $car = 0; $cty = 0;

    # slow variant
#    for $yi (@$yv)
#      {
#      $prod = $xi * $yi + ($prod[$cty] || 0) + $car;
#      $prod[$cty++] =
#       $prod - ($car = int($prod * RBASE)) * $BASE;  # see USE_MUL
#      }
#    $prod[$cty] += $car if $car; # need really to check for 0?
#    $xi = shift @prod;

    # faster variant
    # looping through this if $xi == 0 is silly - so optimize it away!
    $xi = (shift @prod || 0), next if $xi == 0;
    for $yi (@$yv)
      {
      $prod = $xi * $yi + ($prod[$cty] || 0) + $car;
##     this is actually a tad slower
##        $prod = $prod[$cty]; $prod += ($car + $xi * $yi);	# no ||0 here
      $prod[$cty++] =
       $prod - ($car = int($prod * $RBASE)) * $BASE;  # see USE_MUL
      }
    $prod[$cty] += $car if $car; # need really to check for 0?
    $xi = shift @prod;
    }
  push @$xv, @prod;
  __strip_zeros($xv);
  # normalize (handled last to save check for $y->is_zero()
  return $xv;
  }                                                                             

sub _div
  {
  # ref to array, ref to array, modify first array and return remainder if 
  # in list context
  # no longer handles sign
  my ($c,$x,$yorg) = @_;
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
    #warn "oups v1 is 0, u0: $u0 $y->[-2] $y->[-1] l ",scalar @$y,"\n"
    # if $v1 == 0;
    $q = (($u0 == $v1) ? 99999 : int(($u0*$BASE+$u1)/$v1));
    --$q while ($v2*$q > ($u0*$BASE+$u1-$q*$v1)*$BASE+$u2);
    if ($q)
      {
      ($car, $bar) = (0,0);
      for ($yi = 0, $xi = $#$x-$#$y-1; $yi <= $#$y; ++$yi,++$xi) 
        {
        $prd = $q * $y->[$yi] + $car;
        $prd -= ($car = int($prd * $RBASE)) * $BASE;	# see USE_MUL
	$x->[$xi] += $BASE if ($bar = (($x->[$xi] -= $prd + $bar) < 0));
	}
      if ($x->[-1] < $car + $bar) 
        {
        $car = 0; --$q;
	for ($yi = 0, $xi = $#$x-$#$y-1; $yi <= $#$y; ++$yi,++$xi) 
          {
	  $x->[$xi] -= $BASE
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
    __strip_zeros($x); 
    __strip_zeros(\@d);
    return ($x,\@d);
    }
  @$x = @q;
  __strip_zeros($x); 
  return $x;
  }

##############################################################################
# shifts

sub _rsft
  {
  my ($c,$x,$y,$n) = @_;

  if ($n != 10)
    {
    return;	# we cant do this here, due to now _pow, so signal failure
    }
  else
    {
    # shortcut (faster) for shifting by 10)
    # multiples of $BASE_LEN
    my $dst = 0;				# destination
    my $src = _num($c,$y);			# as normal int
    my $rem = $src % $BASE_LEN;			# reminder to shift
    $src = int($src / $BASE_LEN);		# source
    if ($rem == 0)
      {
      splice (@$x,0,$src);			# even faster, 38.4 => 39.3
      }
    else
      {
      my $len = scalar @$x - $src;		# elems to go
      my $vd; my $z = '0'x $BASE_LEN;
      $x->[scalar @$x] = 0;			# avoid || 0 test inside loop
      while ($dst < $len)
        {
        $vd = $z.$x->[$src];
        #print "$dst $src '$vd' ";
        $vd = substr($vd,-$BASE_LEN,$BASE_LEN-$rem);
        #print "'$vd' ";
        $src++;
        $vd = substr($z.$x->[$src],-$rem,$rem) . $vd;
        #print "'$vd1' ";
        #print "'$vd'\n";
        $vd = substr($vd,-$BASE_LEN,$BASE_LEN) if length($vd) > $BASE_LEN;
        $x->[$dst] = int($vd);
        $dst++;
        }
      splice (@$x,$dst) if $dst > 0;		# kill left-over array elems
      pop @$x if $x->[-1] == 0;			# kill last element if 0
      } # else rem == 0
    }
  $x;
  }

sub _lsft
  {
  my ($c,$x,$y,$n) = @_;

  if ($n != 10)
    {
    return;	# we cant do this here, due to now _pow, so signal failure
    }
  else
    {
    # shortcut (faster) for shifting by 10) since we are in base 10eX
    # multiples of $BASE_LEN:
    my $src = scalar @$x;			# source
    my $len = _num($c,$y);			# shift-len as normal int
    my $rem = $len % $BASE_LEN;			# reminder to shift
    my $dst = $src + int($len/$BASE_LEN);	# destination
    my $vd;					# further speedup
    #print "src $src:",$x->[$src]||0," dst $dst:",$v->[$dst]||0," rem $rem\n";
    $x->[$src] = 0;				# avoid first ||0 for speed
    my $z = '0' x $BASE_LEN;
    while ($src >= 0)
      {
      $vd = $x->[$src]; $vd = $z.$vd;
      #print "s $src d $dst '$vd' ";
      $vd = substr($vd,-$BASE_LEN+$rem,$BASE_LEN-$rem);
      #print "'$vd' ";
      $vd .= $src > 0 ? substr($z.$x->[$src-1],-$BASE_LEN,$rem) : '0' x $rem;
      #print "'$vd' ";
      $vd = substr($vd,-$BASE_LEN,$BASE_LEN) if length($vd) > $BASE_LEN;
      #print "'$vd'\n";
      $x->[$dst] = int($vd);
      $dst--; $src--;
      }
    # set lowest parts to 0
    while ($dst >= 0) { $x->[$dst--] = 0; }
    # fix spurios last zero element
    splice @$x,-1 if $x->[-1] == 0;
    #print "elems: "; my $i = 0;
    #foreach (reverse @$v) { print "$i $_ "; $i++; } print "\n";
    }
  $x;
  }

##############################################################################
# testing

sub _acmp
  {
  # internal absolute post-normalized compare (ignore signs)
  # ref to array, ref to array, return <0, 0, >0
  # arrays must have at least one entry; this is not checked for

  my ($c,$cx, $cy) = @_;

  #print "$cx $cy\n"; 
  my ($i,$a,$x,$y,$k);
  # calculate length based on digits, not parts
  $x = _len('',$cx); $y = _len('',$cy);
  # print "length: ",($x-$y),"\n";
  my $lxy = $x - $y;				# if different in length
  return -1 if $lxy < 0;
  return 1 if $lxy > 0;
  #print "full compare\n";
  $i = 0; $a = 0;
  # first way takes 5.49 sec instead of 4.87, but has the early out advantage
  # so grep is slightly faster, but more inflexible. hm. $_ instead of $k
  # yields 5.6 instead of 5.5 sec huh?
  # manual way (abort if unequal, good for early ne)
  my $j = scalar @$cx - 1;
  while ($j >= 0)
   {
   # print "$cx->[$j] $cy->[$j] $a",$cx->[$j]-$cy->[$j],"\n";
   last if ($a = $cx->[$j] - $cy->[$j]); $j--;
   }
  return 1 if $a > 0;
  return -1 if $a < 0;
  return 0;					# equal
  # while it early aborts, it is even slower than the manual variant
  #grep { return $a if ($a = $_ - $cy->[$i++]); } @$cx;
  # grep way, go trough all (bad for early ne)
  #grep { $a = $_ - $cy->[$i++]; } @$cx;
  #return $a;
  }

sub _len
  {
  # computer number of digits in bigint, minus the sign
  # int() because add/sub sometimes leaves strings (like '00005') instead of
  # int ('5') in this place, causing length to fail
  my $cx = $_[1];

  return (@$cx-1)*$BASE_LEN+length(int($cx->[-1]));
  }

sub _digit
  {
  # return the nth digit, negative values count backward
  # zero is rightmost, so _digit(123,0) will give 3
  my ($c,$x,$n) = @_;

  my $len = _len('',$x);

  $n = $len+$n if $n < 0;		# -1 last, -2 second-to-last
  $n = abs($n);				# if negative was too big
  $len--; $n = $len if $n > $len;	# n to big?
  
  my $elem = int($n / $BASE_LEN);	# which array element
  my $digit = $n % $BASE_LEN;		# which digit in this element
  $elem = '0000'.@$x[$elem];		# get element padded with 0's
  return substr($elem,-$digit-1,1);
  }

sub _zeros
  {
  # return amount of trailing zeros in decimal
  # check each array elem in _m for having 0 at end as long as elem == 0
  # Upon finding a elem != 0, stop
  my $x = $_[1];
  my $zeros = 0; my $elem;
  foreach my $e (@$x)
    {
    if ($e != 0)
      {
      $elem = "$e";				# preserve x
      $elem =~ s/.*?(0*$)/$1/;			# strip anything not zero
      $zeros *= $BASE_LEN;			# elems * 5
      $zeros += CORE::length($elem);		# count trailing zeros
      last;					# early out
      }
    $zeros ++;					# real else branch: 50% slower!
    }
  return $zeros;
  }

##############################################################################
# _is_* routines

sub _is_zero
  {
  # return true if arg (BINT or num_str) is zero (array '+', '0')
  my $x = $_[1];
  return (((scalar @$x == 1) && ($x->[0] == 0))) <=> 0;
  }

sub _is_even
  {
  # return true if arg (BINT or num_str) is even
  my $x = $_[1];
  return (!($x->[0] & 1)) <=> 0; 
  }

sub _is_odd
  {
  # return true if arg (BINT or num_str) is even
  my $x = $_[1];
  return (($x->[0] & 1)) <=> 0; 
  }

sub _is_one
  {
  # return true if arg (BINT or num_str) is one (array '+', '1')
  my $x = $_[1];
  return (scalar @$x == 1) && ($x->[0] == 1) <=> 0; 
  }

sub __strip_zeros
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

###############################################################################
# check routine to test internal state of corruptions

sub _check
  {
  # no checks yet, pull it out from the test suite
  my $x = $_[1];

  return "$x is not a reference" if !ref($x);

  # are all parts are valid?
  my $i = 0; my $j = scalar @$x; my ($e,$try);
  while ($i < $j)
    {
    $e = $x->[$i]; $e = 'undef' unless defined $e;
    $try = '=~ /^[\+]?[0-9]+\$/; '."($x, $e)";
    last if $e !~ /^[+]?[0-9]+$/;
    $try = ' < 0 || >= $BASE; '."($x, $e)";
    last if $e <0 || $e >= $BASE;
    # this test is disabled, since new/bnorm and certain ops (like early out
    # in add/sub) are allowed/expected to leave '00000' in some elements
    #$try = '=~ /^00+/; '."($x, $e)";
    #last if $e =~ /^00+/;
    $i++;
    }
  return "Illegal part '$e' at pos $i (tested: $try)" if $i < $j;
  return 0;
  }

1;
__END__

=head1 NAME

Math::BigInt::Calc - Pure Perl module to support Math::BigInt

=head1 SYNOPSIS

Provides support for big integer calculations. Not intended
to be used by other modules. Other modules which export the
same functions can also be used to support Math::Bigint

=head1 DESCRIPTION

In order to allow for multiple big integer libraries, Math::BigInt
was rewritten to use library modules for core math routines. Any
module which follows the same API as this can be used instead by
using the following call:

	use Math::BigInt lib => BigNum;

=head1 EXPORT

The following functions MUST be exported in order to support
the use by Math::BigInt:

	_new(string)	return ref to new object from ref to decimal string
	_zero()		return a new object with value 0
	_one()		return a new object with value 1

	_str(obj)	return ref to a string representing the object
	_num(obj)	returns a Perl integer/floating point number
			NOTE: because of Perl numeric notation defaults,
			the _num'ified obj may lose accuracy due to 
			machine-dependend floating point size limitations
                    
	_add(obj,obj)	Simple addition of two objects
	_mul(obj,obj)	Multiplication of two objects
	_div(obj,obj)	Division of the 1st object by the 2nd
			In list context, returns (result,remainder).
			NOTE: this is integer math, so no
			fractional part will be returned.
	_sub(obj,obj)	Simple subtraction of 1 object from another
			a third, optional parameter indicates that the params
			are swapped. In this case, the first param needs to
			be preserved, while you can destroy the second.
			sub (x,y,1) => return x - y and keep x intact!

	_acmp(obj,obj)	<=> operator for objects (return -1, 0 or 1)

	_len(obj)	returns count of the decimal digits of the object
	_digit(obj,n)	returns the n'th decimal digit of object

	_is_one(obj)	return true if argument is +1
	_is_zero(obj)	return true if argument is 0
	_is_even(obj)	return true if argument is even (0,2,4,6..)
	_is_odd(obj)	return true if argument is odd (1,3,5,7..)

	_copy		return a ref to a true copy of the object

	_check(obj)	check whether internal representation is still intact
			return 0 for ok, otherwise error message as string

The following functions are optional, and can be exported if the underlying lib
has a fast way to do them. If not defined, Math::BigInt will use a pure, but
slow, Perl function as fallback to emulate these:

	_from_hex(str)	return ref to new object from ref to hexadecimal string
	_from_bin(str)	return ref to new object from ref to binary string
	
	_rsft(obj,N,B)	shift object in base B by N 'digits' right
	_lsft(obj,N,B)	shift object in base B by N 'digits' left
	
	_xor(obj1,obj2)	XOR (bit-wise) object 1 with object 2
			Mote: XOR, AND and OR pad with zeros if size mismatches
	_and(obj1,obj2)	AND (bit-wise) object 1 with object 2
	_or(obj1,obj2)	OR (bit-wise) object 1 with object 2

	_sqrt(obj)	return the square root of object
	_pow(obj,obj)	return object 1 to the power of object 2
	_gcd(obj,obj)	return Greatest Common Divisor of two objects
	
	_zeros(obj)	return number of trailing decimal zeros

	_dec(obj)	decrement object by one (input is >= 1)
	_inc(obj)	increment object by one

Input strings come in as unsigned but with prefix (i.e. as '123', '0xabc'
or '0b1101').

Testing of input parameter validity is done by the caller, so you need not
worry about underflow (f.i. in C<_sub()>, C<_dec()>) nor about division by
zero or similar cases.

The first parameter can be modified, that includes the possibility that you
return a reference to a completely different object instead. Although keeping
the reference the same is prefered.

Return values are always references to objects or strings. Exceptions are
C<_lsft()> and C<_rsft()>, which return undef if they can not shift the
argument. This is used to delegate shifting of bases different than 10 back
to BigInt, which will use some generic code to calculate the result.

=head1 WRAP YOUR OWN

If you want to port your own favourite c-lib for big numbers to the
Math::BigInt interface, you can take any of the already existing modules as
a rough guideline. You should really wrap up the latest BigInt and BigFloat
testsuites with your module, and replace the following line:

	use Math::BigInt;

by

	use Math::BigInt lib => 'yourlib';

This way you ensure that your library really works 100% within Math::BigInt.

=head1 LICENSE
 
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. 

=head1 AUTHORS

Original math code by Mark Biggar, rewritten by Tels L<http://bloodgate.com/>
in late 2000, 2001.
Seperated from BigInt and shaped API with the help of John Peacock.

=head1 SEE ALSO

L<Math::BigInt>, L<Math::BigFloat>, L<Math::BigInt::BitVect> and
L<Math::BigInt::Pari>.

=cut

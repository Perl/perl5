package Math::BigInt::Calc;

use 5.005;
use strict;
# use warnings;	# dont use warnings for older Perls

require Exporter;
use vars qw/@ISA $VERSION/;
@ISA = qw(Exporter);

$VERSION = '0.17';

# Package to store unsigned big integers in decimal and do math with them

# Internally the numbers are stored in an array with at least 1 element, no
# leading zero parts (except the first) and in base 1eX where X is determined
# automatically at loading time to be the maximum possible value

# todo:
# - fully remove funky $# stuff (maybe)

# USE_MUL: due to problems on certain os (os390, posix-bc) "* 1e-5" is used
# instead of "/ 1e5" at some places, (marked with USE_MUL). Other platforms
# BS2000, some Crays need USE_DIV instead.
# The BEGIN block is used to determine which of the two variants gives the
# correct result.

##############################################################################
# global constants, flags and accessory
 
# constants for easier life
my $nan = 'NaN';
my ($BASE,$RBASE,$BASE_LEN,$MAX_VAL,$BASE_LEN2);
my ($AND_BITS,$XOR_BITS,$OR_BITS);
my ($AND_MASK,$XOR_MASK,$OR_MASK);

sub _base_len 
  {
  # set/get the BASE_LEN and assorted other, connected values
  # used only be the testsuite, set is used only by the BEGIN block below
  shift;

  my $b = shift;
  if (defined $b)
    {
    $b = 5 if $^O =~ /^uts/;	# UTS needs 5, because 6 and 7 break
    $BASE_LEN = $b+1;
    my $caught;
    while (--$BASE_LEN > 5)
      {
      $BASE = int("1e".$BASE_LEN);
      $RBASE = abs('1e-'.$BASE_LEN);			# see USE_MUL
      $caught = 0;
      $caught += 1 if (int($BASE * $RBASE) != 1);	# should be 1
      $caught += 2 if (int($BASE / $BASE) != 1);	# should be 1
      # print "caught $caught\n";
      last if $caught != 3;
      }
    $BASE = int("1e".$BASE_LEN);
    $RBASE = abs('1e-'.$BASE_LEN);			# see USE_MUL
    $MAX_VAL = $BASE-1;
    $BASE_LEN2 = int($BASE_LEN / 2);			# for mul shortcut
    # print "BASE_LEN: $BASE_LEN MAX_VAL: $MAX_VAL BASE: $BASE RBASE: $RBASE\n";
    
    if ($caught & 1 != 0)
      {
      # must USE_MUL
      *{_mul} = \&_mul_use_mul;
      *{_div} = \&_div_use_mul;
      }
    else		# $caught must be 2, since it can't be 1 nor 3
      {
      # can USE_DIV instead
      *{_mul} = \&_mul_use_div;
      *{_div} = \&_div_use_div;
      }
    }
  if (wantarray)
    {
    return ($BASE_LEN, $AND_BITS, $XOR_BITS, $OR_BITS);
    }
  $BASE_LEN;
  }

BEGIN
  {
  # from Daniel Pfeiffer: determine largest group of digits that is precisely
  # multipliable with itself plus carry
  # Test now changed to expect the proper pattern, not a result off by 1 or 2
  my ($e, $num) = 3;	# lowest value we will use is 3+1-1 = 3
  do 
    {
    $num = ('9' x ++$e) + 0;
    $num *= $num + 1.0;
    # print "$num $e\n";
    } while ("$num" =~ /9{$e}0{$e}/);	# must be a certain pattern
  $e--; 				# last test failed, so retract one step
  # the limits below brush the problems with the test above under the rug:
  # the test should be able to find the proper $e automatically
  $e = 5 if $^O =~ /^uts/;	# UTS get's some special treatment
  $e = 5 if $^O =~ /^unicos/;	# unicos is also problematic (6 seems to work
				# there, but we play safe)
  $e = 8 if $e > 8;		# cap, for VMS, OS/390 and other 64 bit systems

  __PACKAGE__->_base_len($e);	# set and store

  # find out how many bits _and, _or and _xor can take (old default = 16)
  # I don't think anybody has yet 128 bit scalars, so let's play safe.
  use integer;
  local $^W = 0;	# don't warn about 'nonportable number'
  $AND_BITS = 15; $XOR_BITS = 15; $OR_BITS  = 15;

  # find max bits, we will not go higher than numberofbits that fit into $BASE
  # to make _and etc simpler (and faster for smaller, slower for large numbers)
  my $max = 16;
  while (2 ** $max < $BASE) { $max++; }
  my ($x,$y,$z);
  do {
    $AND_BITS++;
    $x = oct('0b' . '1' x $AND_BITS); $y = $x & $x;
    $z = (2 ** $AND_BITS) - 1;
    } while ($AND_BITS < $max && $x == $z && $y == $x);
  $AND_BITS --;						# retreat one step
  do {
    $XOR_BITS++;
    $x = oct('0b' . '1' x $XOR_BITS); $y = $x ^ 0;
    $z = (2 ** $XOR_BITS) - 1;
    } while ($XOR_BITS < $max && $x == $z && $y == $x);
  $XOR_BITS --;						# retreat one step
  do {
    $OR_BITS++;
    $x = oct('0b' . '1' x $OR_BITS); $y = $x | $x;
    $z = (2 ** $OR_BITS) - 1;
    } while ($OR_BITS < $max && $x == $z && $y == $x);
  $OR_BITS --;						# retreat one step
  
  # print "AND $AND_BITS XOR $XOR_BITS OR $OR_BITS\n";
  }

##############################################################################
# create objects from various representations

sub _new
  {
  # (ref to string) return ref to num_array
  # Convert a number from string format to internal base 100000 format.
  # Assumes normalized value as input.
  my $d = $_[1];
  my $il = CORE::length($$d)-1;
  # these leaves '00000' instead of int 0 and will be corrected after any op
  return [ reverse(unpack("a" . ($il % $BASE_LEN+1) 
    . ("a$BASE_LEN" x ($il / $BASE_LEN)), $$d)) ];
  }                                                                             
  
BEGIN
  {
  $AND_MASK = __PACKAGE__->_new( \( 2 ** $AND_BITS ));
  $XOR_MASK = __PACKAGE__->_new( \( 2 ** $XOR_BITS ));
  $OR_MASK = __PACKAGE__->_new( \( 2 ** $OR_BITS ));
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

sub _two
  {
  # create a two (for _pow)
  return [ 2 ];
  }

sub _copy
  {
  return [ @{$_[1]} ];
  }

# catch and throw away
sub import { }

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
    $x->[$j] -= $BASE if $car = (($x->[$j] += $i + $car) >= $BASE) ? 1 : 0;
    $j++;
    }
  while ($car != 0)
    {
    $x->[$j] -= $BASE if $car = (($x->[$j] += $car) >= $BASE) ? 1 : 0; $j++;
    }
  return $x;
  }                                                                             

sub _inc
  {
  # (ref to int_num_array, ref to int_num_array)
  # routine to add 1 to a base 1eX numbers
  # This routine clobbers up array x, but not y.
  my ($c,$x) = @_;

  for my $i (@$x)
    {
    return $x if (($i += 1) < $BASE);		# early out
    $i -= $BASE;
    }
  if ($x->[-1] == 0)				# last overflowed
    {
    push @$x,1;					# extend
    }
  return $x;
  }                                                                             

sub _dec
  {
  # (ref to int_num_array, ref to int_num_array)
  # routine to add 1 to a base 1eX numbers
  # This routine clobbers up array x, but not y.
  my ($c,$x) = @_;

  for my $i (@$x)
    {
    last if (($i -= 1) >= 0);			# early out
    $i = $MAX_VAL;
    }
  pop @$x if $x->[-1] == 0 && @$x > 1;		# last overflowed (but leave 0)
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
      $i += $BASE if $car = (($i -= ($sy->[$j] || 0) + $car) < 0); $j++;
      }
    # might leave leading zeros, so fix that
    return __strip_zeros($sx);
    }
  #print "case 1 (swap)\n";
  for $i (@$sx)
    {
    last unless defined $sy->[$j] || $car;
    $sy->[$j] += $BASE
     if $car = (($sy->[$j] = $i-($sy->[$j]||0) - $car) < 0);
    $j++;
    }
  # might leave leading zeros, so fix that
  __strip_zeros($sy);
  }                                                                             

sub _mul_use_mul
  {
  # (BINT, BINT) return nothing
  # multiply two numbers in internal representation
  # modifies first arg, second need not be different from first
  my ($c,$xv,$yv) = @_;

  # shortcut for two very short numbers
  # +0 since part maybe string '00001' from new()
  if ((@$xv == 1) && (@$yv == 1)
   && (length($xv->[0]+0) <= $BASE_LEN2)
   && (length($yv->[0]+0) <= $BASE_LEN2))
   {
   $xv->[0] *= $yv->[0];
   return $xv;
   }
  
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
    $xi = shift @prod || 0;	# || 0 makes v5.005_3 happy
    }
  push @$xv, @prod;
  __strip_zeros($xv);
  }                                                                             

sub _mul_use_div
  {
  # (BINT, BINT) return nothing
  # multiply two numbers in internal representation
  # modifies first arg, second need not be different from first
  my ($c,$xv,$yv) = @_;
 
  # shortcut for two very short numbers
  # +0 since part maybe string '00001' from new()
  if ((@$xv == 1) && (@$yv == 1)
   && (length($xv->[0]+0) <= $BASE_LEN2)
   && (length($yv->[0]+0) <= $BASE_LEN2))
   {
   $xv->[0] *= $yv->[0];
   return $xv;
   }
  
  my @prod = (); my ($prod,$car,$cty,$xi,$yi);
  # since multiplying $x with $x fails, make copy in this case
  $yv = [@$xv] if "$xv" eq "$yv";	# same references?
  for $xi (@$xv)
    {
    $car = 0; $cty = 0;
    # looping through this if $xi == 0 is silly - so optimize it away!
    $xi = (shift @prod || 0), next if $xi == 0;
    for $yi (@$yv)
      {
      $prod = $xi * $yi + ($prod[$cty] || 0) + $car;
      $prod[$cty++] =
       $prod - ($car = int($prod / $BASE)) * $BASE;
      }
    $prod[$cty] += $car if $car; # need really to check for 0?
    $xi = shift @prod || 0;	# || 0 makes v5.005_3 happy
    }
  push @$xv, @prod;
  __strip_zeros($xv);
  }                                                                             

sub _div_use_mul
  {
  # ref to array, ref to array, modify first array and return remainder if 
  # in list context
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
    # $q = (($u0 == $v1) ? 99999 : int(($u0*$BASE+$u1)/$v1));
     $q = (($u0 == $v1) ? $MAX_VAL : int(($u0*$BASE+$u1)/$v1));
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
    _check('',$x);
    _check('',\@d);
    return ($x,\@d);
    }
  @$x = @q;
  __strip_zeros($x); 
    _check('',$x);
  }

sub _div_use_div
  {
  # ref to array, ref to array, modify first array and return remainder if 
  # in list context
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
      $xi -= ($car = int($xi / $BASE)) * $BASE;
      }
    push(@$x, $car); $car = 0;
    for $yi (@$y) 
      {
      $yi = $yi * $dd + $car;
      $yi -= ($car = int($yi / $BASE)) * $BASE;
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
    # $q = (($u0 == $v1) ? 99999 : int(($u0*$BASE+$u1)/$v1));
     $q = (($u0 == $v1) ? $MAX_VAL : int(($u0*$BASE+$u1)/$v1));
    --$q while ($v2*$q > ($u0*$BASE+$u1-$q*$v1)*$BASE+$u2);
    if ($q)
      {
      ($car, $bar) = (0,0);
      for ($yi = 0, $xi = $#$x-$#$y-1; $yi <= $#$y; ++$yi,++$xi) 
        {
        $prd = $q * $y->[$yi] + $car;
        $prd -= ($car = int($prd / $BASE)) * $BASE;
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
        $car = $prd - ($tmp = int($prd / $dd)) * $dd;
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
  }

##############################################################################
# testing

sub _acmp
  {
  # internal absolute post-normalized compare (ignore signs)
  # ref to array, ref to array, return <0, 0, >0
  # arrays must have at least one entry; this is not checked for

  my ($c,$cx,$cy) = @_;

  # fat comp based on array elements
  my $lxy = scalar @$cx - scalar @$cy;
  return -1 if $lxy < 0;				# already differs, ret
  return 1 if $lxy > 0;					# ditto
  
  # now calculate length based on digits, not parts
  $lxy = _len($c,$cx) - _len($c,$cy);			# difference
  return -1 if $lxy < 0;
  return 1 if $lxy > 0;

  # hm, same lengths,  but same contents?
  my $i = 0; my $a;
  # first way takes 5.49 sec instead of 4.87, but has the early out advantage
  # so grep is slightly faster, but more inflexible. hm. $_ instead of $k
  # yields 5.6 instead of 5.5 sec huh?
  # manual way (abort if unequal, good for early ne)
  my $j = scalar @$cx - 1;
  while ($j >= 0)
   {
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
  # compute number of digits in bigint, minus the sign

  # int() because add/sub sometimes leaves strings (like '00005') instead of
  # '5' in this place, thus causing length() to report wrong length
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
  push @$s,0 if $i < 0;		# div might return empty results, so fix it

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
  $s;                                                                    
  }                                                                             

###############################################################################
# check routine to test internal state of corruptions

sub _check
  {
  # used by the test suite
  my $x = $_[1];

  return "$x is not a reference" if !ref($x);

  # are all parts are valid?
  my $i = 0; my $j = scalar @$x; my ($e,$try);
  while ($i < $j)
    {
    $e = $x->[$i]; $e = 'undef' unless defined $e;
    $try = '=~ /^[\+]?[0-9]+\$/; '."($x, $e)";
    last if $e !~ /^[+]?[0-9]+$/;
    $try = '=~ /^[\+]?[0-9]+\$/; '."($x, $e) (stringify)";
    last if "$e" !~ /^[+]?[0-9]+$/;
    $try = '=~ /^[\+]?[0-9]+\$/; '."($x, $e) (cat-stringify)";
    last if '' . "$e" !~ /^[+]?[0-9]+$/;
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


###############################################################################
###############################################################################
# some optional routines to make BigInt faster

sub _mod
  {
  # if possible, use mod shortcut
  my ($c,$x,$yo) = @_;

  # slow way since $y to big
  if (scalar @$yo > 1)
    {
    my ($xo,$rem) = _div($c,$x,$yo);
    return $rem;
    }
  my $y = $yo->[0];
  # both are single element arrays
  if (scalar @$x == 1)
    {
    $x->[0] %= $y;
    return $x;
    }

  # @y is single element, but  @x has more than one
  my $b = $BASE % $y;
  if ($b == 0)
    {
    # when BASE % Y == 0 then (B * BASE) % Y == 0
    # (B * BASE) % $y + A % Y => A % Y
    # so need to consider only last element: O(1)
    $x->[0] %= $y;
    }
  elsif ($b == 1)
    {
    # else need to go trough all elements: O(N),  but loop is a bit simplified
    my $r = 0;
    foreach (@$x)
      {
      $r += $_ % $y;
      $r %= $y;
      }
    $r = 0 if $r == $y;
    $x->[0] = $r;
    }
  else
    {
    # else need to go trough all elements: O(N)
    my $r = 0; my $bm = 1;
    foreach (@$x)
      {
      $r += ($_ % $y) * $bm;
      $bm *= $b;
      $bm %= $y;
      $r %= $y;
      }
    $r = 0 if $r == $y;
    $x->[0] = $r;
    }
  splice (@$x,1);
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
    my $rem = $src % $BASE_LEN;			# remainder to shift
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
        $vd = substr($vd,-$BASE_LEN,$BASE_LEN-$rem);
        $src++;
        $vd = substr($z.$x->[$src],-$rem,$rem) . $vd;
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
    my $rem = $len % $BASE_LEN;			# remainder to shift
    my $dst = $src + int($len/$BASE_LEN);	# destination
    my $vd;					# further speedup
    $x->[$src] = 0;				# avoid first ||0 for speed
    my $z = '0' x $BASE_LEN;
    while ($src >= 0)
      {
      $vd = $x->[$src]; $vd = $z.$vd;
      $vd = substr($vd,-$BASE_LEN+$rem,$BASE_LEN-$rem);
      $vd .= $src > 0 ? substr($z.$x->[$src-1],-$BASE_LEN,$rem) : '0' x $rem;
      $vd = substr($vd,-$BASE_LEN,$BASE_LEN) if length($vd) > $BASE_LEN;
      $x->[$dst] = int($vd);
      $dst--; $src--;
      }
    # set lowest parts to 0
    while ($dst >= 0) { $x->[$dst--] = 0; }
    # fix spurios last zero element
    splice @$x,-1 if $x->[-1] == 0;
    }
  $x;
  }

sub _pow
  {
  # power of $x to $y
  # ref to array, ref to array, return ref to array
  my ($c,$cx,$cy) = @_;

  my $pow2 = _one();
  my $two = _two();
  my $y1 = _copy($c,$cy);
  while (!_is_one($c,$y1))
    {
    _mul($c,$pow2,$cx) if _is_odd($c,$y1);
    _div($c,$y1,$two);
    _mul($c,$cx,$cx);
    }
  _mul($c,$cx,$pow2) unless _is_one($c,$pow2);
  return $cx;
  }

sub _sqrt
  {
  # square-root of $x
  # ref to array, return ref to array
  my ($c,$x) = @_;

  if (scalar @$x == 1)
    {
    # fit's into one Perl scalar
    $x->[0] = int(sqrt($x->[0]));
    return $x;
    } 
  my $y = _copy($c,$x);
  my $l = [ _len($c,$x) / 2 ];

  splice @$x,0; $x->[0] = 1; 	# keep ref($x), but modify it

  _lsft($c,$x,$l,10);

  my $two = _two();
  my $last = _zero();
  my $lastlast = _zero();
  while (_acmp($c,$last,$x) != 0 && _acmp($c,$lastlast,$x) != 0)
    {
    $lastlast = _copy($c,$last);
    $last = _copy($c,$x);
    _add($c,$x, _div($c,_copy($c,$y),$x));
    _div($c,$x, $two );
    }
  _dec($c,$x) if _acmp($c,$y,_mul($c,_copy($c,$x),$x)) < 0;	# overshot? 
  $x;
  }

##############################################################################
# binary stuff

sub _and
  {
  my ($c,$x,$y) = @_;

  # the shortcut makes equal, large numbers _really_ fast, and makes only a
  # very small performance drop for small numbers (e.g. something with less
  # than 32 bit) Since we optimize for large numbers, this is enabled.
  return $x if _acmp($c,$x,$y) == 0;		# shortcut
  
  my $m = _one(); my ($xr,$yr);
  my $mask = $AND_MASK;

  my $x1 = $x;
  my $y1 = _copy($c,$y);			# make copy
  $x = _zero();
  my ($b,$xrr,$yrr);
  use integer;
  while (!_is_zero($c,$x1) && !_is_zero($c,$y1))
    {
    ($x1, $xr) = _div($c,$x1,$mask);
    ($y1, $yr) = _div($c,$y1,$mask);

    # make ints() from $xr, $yr
    # this is when the AND_BITS are greater tahn $BASE and is slower for
    # small (<256 bits) numbers, but faster for large numbers. Disabled
    # due to KISS principle

#    $b = 1; $xrr = 0; foreach (@$xr) { $xrr += $_ * $b; $b *= $BASE; }
#    $b = 1; $yrr = 0; foreach (@$yr) { $yrr += $_ * $b; $b *= $BASE; }
#    _add($c,$x, _mul($c, _new( $c, \($xrr & $yrr) ), $m) );
    
    _add($c,$x, _mul($c, [ $xr->[0] & $yr->[0] ], $m) );
    _mul($c,$m,$mask);
    }
  $x;
  }

sub _xor
  {
  my ($c,$x,$y) = @_;

  return _zero() if _acmp($c,$x,$y) == 0;	# shortcut (see -and)

  my $m = _one(); my ($xr,$yr);
  my $mask = $XOR_MASK;

  my $x1 = $x;
  my $y1 = _copy($c,$y);			# make copy
  $x = _zero();
  my ($b,$xrr,$yrr);
  use integer;
  while (!_is_zero($c,$x1) && !_is_zero($c,$y1))
    {
    ($x1, $xr) = _div($c,$x1,$mask);
    ($y1, $yr) = _div($c,$y1,$mask);
    # make ints() from $xr, $yr (see _and())
    #$b = 1; $xrr = 0; foreach (@$xr) { $xrr += $_ * $b; $b *= $BASE; }
    #$b = 1; $yrr = 0; foreach (@$yr) { $yrr += $_ * $b; $b *= $BASE; }
    #_add($c,$x, _mul($c, _new( $c, \($xrr ^ $yrr) ), $m) );
    
    _add($c,$x, _mul($c, [ $xr->[0] ^ $yr->[0] ], $m) );
    _mul($c,$m,$mask);
    }
  # the loop stops when the shorter of the two numbers is exhausted
  # the remainder of the longer one will survive bit-by-bit, so we simple
  # multiply-add it in
  _add($c,$x, _mul($c, $x1, $m) ) if !_is_zero($c,$x1);
  _add($c,$x, _mul($c, $y1, $m) ) if !_is_zero($c,$y1);
  
  $x;
  }

sub _or
  {
  my ($c,$x,$y) = @_;

  return $x if _acmp($c,$x,$y) == 0;		# shortcut (see _and)

  my $m = _one(); my ($xr,$yr);
  my $mask = $OR_MASK;

  my $x1 = $x;
  my $y1 = _copy($c,$y);			# make copy
  $x = _zero();
  my ($b,$xrr,$yrr);
  use integer;
  while (!_is_zero($c,$x1) && !_is_zero($c,$y1))
    {
    ($x1, $xr) = _div($c,$x1,$mask);
    ($y1, $yr) = _div($c,$y1,$mask);
    # make ints() from $xr, $yr (see _and())
#    $b = 1; $xrr = 0; foreach (@$xr) { $xrr += $_ * $b; $b *= $BASE; }
#    $b = 1; $yrr = 0; foreach (@$yr) { $yrr += $_ * $b; $b *= $BASE; }
#    _add($c,$x, _mul($c, _new( $c, \($xrr | $yrr) ), $m) );
    
    _add($c,$x, _mul($c, [ $xr->[0] | $yr->[0] ], $m) );
    _mul($c,$m,$mask);
    }
  # the loop stops when the shorter of the two numbers is exhausted
  # the remainder of the longer one will survive bit-by-bit, so we simple
  # multiply-add it in
  _add($c,$x, _mul($c, $x1, $m) ) if !_is_zero($c,$x1);
  _add($c,$x, _mul($c, $y1, $m) ) if !_is_zero($c,$y1);
  
  $x;
  }

sub _from_hex
  {
  # convert a hex number to decimal (ref to string, return ref to array)
  my ($c,$hs) = @_;

  my $mul = _one();
  my $m = [ 0x10000 ];				# 16 bit at a time
  my $x = _zero();

  my $len = CORE::length($$hs)-2;
  $len = int($len/4);				# 4-digit parts, w/o '0x'
  my $val; my $i = -4;
  while ($len >= 0)
    {
    $val = substr($$hs,$i,4);
    $val =~ s/^[+-]?0x// if $len == 0;		# for last part only because
    $val = hex($val);				# hex does not like wrong chars
    $i -= 4; $len --;
    _add ($c, $x, _mul ($c, [ $val ], $mul ) ) if $val != 0;
    _mul ($c, $mul, $m ) if $len >= 0; 		# skip last mul
    }
  $x;
  }

sub _from_bin
  {
  # convert a hex number to decimal (ref to string, return ref to array)
  my ($c,$bs) = @_;

  my $mul = _one();
  my $m = [ 0x100 ];				# 8 bit at a time
  my $x = _zero();

  my $len = CORE::length($$bs)-2;
  $len = int($len/8);				# 4-digit parts, w/o '0x'
  my $val; my $i = -8;
  while ($len >= 0)
    {
    $val = substr($$bs,$i,8);
    $val =~ s/^[+-]?0b// if $len == 0;		# for last part only

    #$val = oct('0b'.$val);   # does not work on Perl prior to 5.6.0
    # $val = ('0' x (8-CORE::length($val))).$val if CORE::length($val) < 8;
    $val = ord(pack('B8',substr('00000000'.$val,-8,8))); 

    $i -= 8; $len --;
    _add ($c, $x, _mul ($c, [ $val ], $mul ) ) if $val != 0;
    _mul ($c, $mul, $m ) if $len >= 0; 		# skip last mul
    }
  $x;
  }

##############################################################################
##############################################################################

1;
__END__

=head1 NAME

Math::BigInt::Calc - Pure Perl module to support Math::BigInt

=head1 SYNOPSIS

Provides support for big integer calculations. Not intended to be used by other
modules (except Math::BigInt::Cached). Other modules which sport the same
functions can also be used to support Math::Bigint, like Math::BigInt::Pari.

=head1 DESCRIPTION

In order to allow for multiple big integer libraries, Math::BigInt was
rewritten to use library modules for core math routines. Any module which
follows the same API as this can be used instead by using the following:

	use Math::BigInt lib => 'libname';

'libname' is either the long name ('Math::BigInt::Pari'), or only the short
version like 'Pari'.

=head1 EXPORT

The following functions MUST be defined in order to support the use by
Math::BigInt:

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
	_dec(obj)	decrement object by one (input is garant. to be > 0)
	_inc(obj)	increment object by one


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

The following functions are optional, and can be defined if the underlying lib
has a fast way to do them. If undefined, Math::BigInt will use pure Perl (hence
slow) fallback routines to emulate these:

	_from_hex(str)	return ref to new object from ref to hexadecimal string
	_from_bin(str)	return ref to new object from ref to binary string
	
	_as_hex(str)	return ref to scalar string containing the value as
			unsigned hex string, with the '0x' prepended.
			Leading zeros must be stripped.
	_as_bin(str)	Like as_hex, only as binary string containing only
			zeros and ones. Leading zeros must be stripped and a
			'0b' must be prepended.
	
	_rsft(obj,N,B)	shift object in base B by N 'digits' right
			For unsupported bases B, return undef to signal failure
	_lsft(obj,N,B)	shift object in base B by N 'digits' left
			For unsupported bases B, return undef to signal failure
	
	_xor(obj1,obj2)	XOR (bit-wise) object 1 with object 2
			Note: XOR, AND and OR pad with zeros if size mismatches
	_and(obj1,obj2)	AND (bit-wise) object 1 with object 2
	_or(obj1,obj2)	OR (bit-wise) object 1 with object 2

	_mod(obj,obj)	Return remainder of div of the 1st by the 2nd object
	_sqrt(obj)	return the square root of object (truncate to int)
	_pow(obj,obj)	return object 1 to the power of object 2
	_gcd(obj,obj)	return Greatest Common Divisor of two objects
	
	_zeros(obj)	return number of trailing decimal zeros

Input strings come in as unsigned but with prefix (i.e. as '123', '0xabc'
or '0b1101').

Testing of input parameter validity is done by the caller, so you need not
worry about underflow (f.i. in C<_sub()>, C<_dec()>) nor about division by
zero or similar cases.

The first parameter can be modified, that includes the possibility that you
return a reference to a completely different object instead. Although keeping
the reference and just changing it's contents is prefered over creating and
returning a different reference.

Return values are always references to objects or strings. Exceptions are
C<_lsft()> and C<_rsft()>, which return undef if they can not shift the
argument. This is used to delegate shifting of bases different than the one
you can support back to Math::BigInt, which will use some generic code to
calculate the result.

=head1 WRAP YOUR OWN

If you want to port your own favourite c-lib for big numbers to the
Math::BigInt interface, you can take any of the already existing modules as
a rough guideline. You should really wrap up the latest BigInt and BigFloat
testsuites with your module, and replace in them any of the following:

	use Math::BigInt;

by this:

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

L<Math::BigInt>, L<Math::BigFloat>, L<Math::BigInt::BitVect>,
L<Math::BigInt::GMP>, L<Math::BigInt::Cached> and L<Math::BigInt::Pari>.

=cut

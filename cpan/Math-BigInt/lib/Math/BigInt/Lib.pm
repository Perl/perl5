package Math::BigInt::Lib;

use 5.006001;
use strict;
use warnings;

our $VERSION = '1.999806';

use Carp;

use overload

  # overload key: with_assign

  '+'    => sub {
                my $class = ref $_[0];
                my $x = $class -> _copy($_[0]);
                my $y = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                return $class -> _add($x, $y);
            },

  '-'    => sub {
                my $class = ref $_[0];
                my ($x, $y);
                if ($_[2]) {            # if swapped
                    $y = $_[0];
                    $x = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                } else {
                    $x = $class -> _copy($_[0]);
                    $y = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                }
                return $class -> _sub($x, $y);
            },

  '*'    => sub {
                my $class = ref $_[0];
                my $x = $class -> _copy($_[0]);
                my $y = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                return $class -> _mul($x, $y);
            },

  '/'    => sub {
                my $class = ref $_[0];
                my ($x, $y);
                if ($_[2]) {            # if swapped
                    $y = $_[0];
                    $x = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                } else {
                    $x = $class -> _copy($_[0]);
                    $y = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                }
                return $class -> _div($x, $y);
            },

  '%'    => sub {
                my $class = ref $_[0];
                my ($x, $y);
                if ($_[2]) {            # if swapped
                    $y = $_[0];
                    $x = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                } else {
                    $x = $class -> _copy($_[0]);
                    $y = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                }
                return $class -> _mod($x, $y);
            },

  '**'   => sub {
                my $class = ref $_[0];
                my ($x, $y);
                if ($_[2]) {            # if swapped
                    $y = $_[0];
                    $x = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                } else {
                    $x = $class -> _copy($_[0]);
                    $y = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                }
                return $class -> _pow($x, $y);
            },

  '<<'   => sub {
                my $class = ref $_[0];
                my ($x, $y);
                if ($_[2]) {            # if swapped
                    $y = $class -> _num($_[0]);
                    $x = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                } else {
                    $x = $_[0];
                    $y = ref($_[1]) ? $class -> _num($_[1]) : $_[1];
                }
                return $class -> _blsft($x, $y);
            },

  '>>'   => sub {
                my $class = ref $_[0];
                my ($x, $y);
                if ($_[2]) {            # if swapped
                    $y = $_[0];
                    $x = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                } else {
                    $x = $class -> _copy($_[0]);
                    $y = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                }
                return $class -> _brsft($x, $y);
            },

  # overload key: num_comparison

  '<'    => sub {
                my $class = ref $_[0];
                my ($x, $y);
                if ($_[2]) {            # if swapped
                    $y = $_[0];
                    $x = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                } else {
                    $x = $class -> _copy($_[0]);
                    $y = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                }
                return $class -> _acmp($x, $y) < 0;
            },

  '<='   => sub {
                my $class = ref $_[0];
                my ($x, $y);
                if ($_[2]) {            # if swapped
                    $y = $_[0];
                    $x = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                } else {
                    $x = $class -> _copy($_[0]);
                    $y = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                }
                return $class -> _acmp($x, $y) <= 0;
            },

  '>'    => sub {
                my $class = ref $_[0];
                my ($x, $y);
                if ($_[2]) {            # if swapped
                    $y = $_[0];
                    $x = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                } else {
                    $x = $class -> _copy($_[0]);
                    $y = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                }
                return $class -> _acmp($x, $y) > 0;
            },

  '>='   => sub {
                my $class = ref $_[0];
                my ($x, $y);
                if ($_[2]) {            # if swapped
                    $y = $_[0];
                    $x = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                } else {
                    $x = $class -> _copy($_[0]);
                    $y = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                }
                return $class -> _acmp($x, $y) >= 0;
          },

  '=='   => sub {
                my $class = ref $_[0];
                my $x = $class -> _copy($_[0]);
                my $y = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                return $class -> _acmp($x, $y) == 0;
            },

  '!='   => sub {
                my $class = ref $_[0];
                my $x = $class -> _copy($_[0]);
                my $y = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                return $class -> _acmp($x, $y) != 0;
            },

  # overload key: 3way_comparison

  '<=>'  => sub {
                my $class = ref $_[0];
                my ($x, $y);
                if ($_[2]) {            # if swapped
                    $y = $_[0];
                    $x = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                } else {
                    $x = $class -> _copy($_[0]);
                    $y = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                }
                return $class -> _acmp($x, $y);
            },

  # overload key: binary

  '&'    => sub {
                my $class = ref $_[0];
                my ($x, $y);
                if ($_[2]) {            # if swapped
                    $y = $_[0];
                    $x = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                } else {
                    $x = $class -> _copy($_[0]);
                    $y = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                }
                return $class -> _and($x, $y);
            },

  '|'    => sub {
                my $class = ref $_[0];
                my ($x, $y);
                if ($_[2]) {            # if swapped
                    $y = $_[0];
                    $x = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                } else {
                    $x = $class -> _copy($_[0]);
                    $y = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                }
                return $class -> _or($x, $y);
            },

  '^'    => sub {
                my $class = ref $_[0];
                my ($x, $y);
                if ($_[2]) {            # if swapped
                    $y = $_[0];
                    $x = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                } else {
                    $x = $class -> _copy($_[0]);
                    $y = ref($_[1]) ? $_[1] : $class -> _new($_[1]);
                }
                return $class -> _xor($x, $y);
            },

  # overload key: func

  'abs'  => sub { $_[0] },

  'sqrt' => sub {
                my $class = ref $_[0];
                return $class -> _sqrt($class -> _copy($_[0]));
            },

  'int'  => sub { $_[0] -> copy() -> bint(); },

  # overload key: conversion

  'bool' => sub { ref($_[0]) -> _is_zero($_[0]) ? '' : 1; },

  '""'   => sub { ref($_[0]) -> _str($_[0]); },

  '0+'   => sub { ref($_[0]) -> _num($_[0]); },

  '='    => sub { ref($_[0]) -> _copy($_[0]); },

  ;

# Do we need api_version() at all, now that we have a virtual parent class that
# will provide any missing methods? Fixme!

sub api_version () {
    croak "@{[(caller 0)[3]]} method not implemented";
}

sub _new {
    croak "@{[(caller 0)[3]]} method not implemented";
}

sub _zero {
    my $class = shift;
    return $class -> _new("0");
}

sub _one {
    my $class = shift;
    return $class -> _new("1");
}

sub _two {
    my $class = shift;
    return $class -> _new("2");

}
sub _ten {
    my $class = shift;
    return $class -> _new("10");
}

sub _1ex {
    my ($class, $exp) = @_;
    $exp = $class -> _num($exp) if ref($exp);
    return $class -> _new("1" . ("0" x $exp));
}

sub _copy {
    my ($class, $x) = @_;
    return $class -> _new($class -> _str($x));
}

# catch and throw away
sub import { }

##############################################################################
# convert back to string and number

sub _str {
    # Convert number from internal base 1eN format to string format. Internal
    # format is always normalized, i.e., no leading zeros.
    croak "@{[(caller 0)[3]]} method not implemented";
}

sub _num {
    my ($class, $x) = @_;
    0 + $class -> _str($x);
}

##############################################################################
# actual math code

sub _add {
    croak "@{[(caller 0)[3]]} method not implemented";
}

sub _sub {
    croak "@{[(caller 0)[3]]} method not implemented";
}

sub _mul {
    my ($class, $x, $y) = @_;
    my $sum = $class -> _zero();
    my $i   = $class -> _zero();
    while ($class -> _acmp($i, $y) < 0) {
        $sum = $class -> _add($sum, $x);
        $i   = $class -> _inc($i);
    }
    return $sum;
}

sub _div {
    my ($class, $x, $y) = @_;

    croak "@{[(caller 0)[3]]} requires non-zero divisor"
      if $class -> _is_zero($y);

    my $r = $class -> _copy($x);
    my $q = $class -> _zero();
    while ($class -> _acmp($r, $y) >= 0) {
        $q = $class -> _inc($q);
        $r = $class -> _sub($r, $y);
    }

    return $q, $r if wantarray;
    return $q;
}

sub _inc {
    my ($class, $x) = @_;
    $class -> _add($x, $class -> _one());
}

sub _dec {
    my ($class, $x) = @_;
    $class -> _sub($x, $class -> _one());
}

##############################################################################
# testing

sub _acmp {
    # Compare two (absolute) values. Return -1, 0, or 1.
    my ($class, $x, $y) = @_;
    my $xstr = $class -> _str($x);
    my $ystr = $class -> _str($y);

    length($xstr) <=> length($ystr) || $xstr cmp $ystr;
}

sub _len {
    my ($class, $x) = @_;
    CORE::length($class -> _str($x));
}

sub _alen {
    my ($class, $x) = @_;
    $class -> _len($x);
}

sub _digit {
    my ($class, $x, $n) = @_;
    substr($class ->_str($x), -($n+1), 1);
}

sub _zeros {
    my ($class, $x) = @_;
    my $str = $class -> _str($x);
    $str =~ /[^0](0*)\z/;
    CORE::length($1);
}

##############################################################################
# _is_* routines

sub _is_zero {
    # return true if arg is zero
    my ($class, $x) = @_;
    $class -> _str($x) == 0;
}

sub _is_even {
    # return true if arg is even
    my ($class, $x) = @_;
    substr($class -> _str($x), -1, 1) % 2 == 0;
}

sub _is_odd {
    # return true if arg is odd
    my ($class, $x) = @_;
    substr($class -> _str($x), -1, 1) % 2 != 0;
}

sub _is_one {
    # return true if arg is one
    my ($class, $x) = @_;
    $class -> _str($x) == 1;
}

sub _is_two {
    # return true if arg is two
    my ($class, $x) = @_;
    $class -> _str($x) == 2;
}

sub _is_ten {
    # return true if arg is ten
    my ($class, $x) = @_;
    $class -> _str($x) == 10;
}

###############################################################################
# check routine to test internal state for corruptions

sub _check {
    # used by the test suite
    my ($class, $x) = @_;
    return "Input is undefined" unless defined $x;
    return "$x is not a reference" unless ref($x);
    return 0;
}

###############################################################################

sub _mod {
    # modulus
    my ($class, $x, $y) = @_;

    croak "@{[(caller 0)[3]]} requires non-zero second operand"
      if $class -> _is_zero($y);

    my $r = $class -> _copy($x);
    while ($class -> _acmp($r, $y) >= 0) {
        $r = $class -> _sub($r, $y);
    }

    return $r;
}

##############################################################################
# shifts

sub _rsft {
    my ($class, $x, $n, $b) = @_;
    $b = $class -> _new($b) unless ref $b;
    return scalar $class -> _div($x, $class -> _pow($class -> _copy($b), $n));
}

sub _lsft {
    my ($class, $x, $n, $b) = @_;
    $b = $class -> _new($b) unless ref $b;
    return $class -> _mul($x, $class -> _pow($class -> _copy($b), $n));
}

sub _pow {
    # power of $x to $y
    # ref to array, ref to array, return ref to array
    my ($class, $x, $y) = @_;

    if ($class -> _is_zero($y)) {
        return $class -> _one();        # y == 0 => x => 1
    }

    if (($class -> _is_one($x)) ||      #    x == 1
        ($class -> _is_one($y)))        # or y == 1
    {
        return $x;
    }

    if ($class -> _is_zero($x)) {
        return $class -> _zero();       # 0 ** y => 0 (if not y <= 0)
    }

    my $pow2 = $class -> _one();

    my $y_bin = $class -> _as_bin($y);
    $y_bin =~ s/^0b//;
    my $len = length($y_bin);

    while (--$len > 0) {
        $pow2 = $class -> _mul($pow2, $x) if substr($y_bin, $len, 1) eq '1';
        $x = $class -> _mul($x, $x);
    }

    $x = $class -> _mul($x, $pow2);
    return $x;
}

sub _nok {
    # Return binomial coefficient (n over k).
    # Given refs to arrays, return ref to array.
    # First input argument is modified.

    my ($class, $n, $k) = @_;

    # If k > n/2, or, equivalently, 2*k > n, compute nok(n, k) as
    # nok(n, n-k), to minimize the number if iterations in the loop.

    {
        my $twok = $class -> _mul($class -> _two(), $class -> _copy($k));
        if ($class -> _acmp($twok, $n) > 0) {
            $k = $class -> _sub($class -> _copy($n), $k);
        }
    }

    # Example:
    #
    # / 7 \       7!       1*2*3*4 * 5*6*7   5 * 6 * 7       6   7
    # |   | = --------- =  --------------- = --------- = 5 * - * -
    # \ 3 /   (7-3)! 3!    1*2*3*4 * 1*2*3   1 * 2 * 3       2   3

    if ($class -> _is_zero($k)) {
        return $class -> _one();
    }

    # Make a copy of the original n, since we'll be modifying n in-place.

    my $n_orig = $class -> _copy($n);

    # n = 5, f = 6, d = 2 (cf. example above)

    $n = $class -> _sub($n, $k);
    $n = $class -> _inc($n);

    my $f = $class -> _copy($n);
    $class -> _inc($f);

    my $d = $class -> _two();

    # while f <= n (the original n, that is) ...

    while ($class -> _acmp($f, $n_orig) <= 0) {

        # n = (n * f / d) == 5 * 6 / 2 (cf. example above)

        $n = $class -> _mul($n, $f);
        $n = $class -> _div($n, $d);

        # f = 7, d = 3 (cf. example above)

        $f = $class -> _inc($f);
        $d = $class -> _inc($d);
    }

    return $n;
}

sub _fac {
    # factorial
    my ($class, $x) = @_;

    my $two = $class -> _two();

    if ($class -> _acmp($x, $two) < 0) {
        return $class -> _one();
    }

    my $i = $class -> _copy($x);
    while ($class -> _acmp($i, $two) > 0) {
        $i = $class -> _dec($i);
        $x = $class -> _mul($x, $i);
    }

    return $x;
}

sub _log_int {
    # calculate integer log of $x to base $base
    # ref to array, ref to array - return ref to array

    my ($class, $x, $base) = @_;

    # X == 0 => NaN
    return if $class -> _is_zero($x);

    $base = $class -> _new(2)     unless defined($base);
    $base = $class -> _new($base) unless ref($base);

    # BASE 0 or 1 => NaN
    return if $class -> _is_zero($base) || $class -> _is_one($base);

    # X == 1 => 0 (is exact)
    if ($class -> _is_one($x)) {
        return $class -> _zero(), 1;
    }

    my $cmp = $class -> _acmp($x, $base);

    # X == BASE => 1 (is exact)
    if ($cmp == 0) {
        return $class -> _one(), 1;
    }

    # 1 < X < BASE => 0 (is truncated)
    if ($cmp < 0) {
        return $class -> _zero(), 0;
    }

    my $y;

    # log(x) / log(b) = log(xm * 10^xe) / log(bm * 10^be)
    #                 = (log(xm) + xe*(log(10))) / (log(bm) + be*log(10))

    {
        my $x_str = $class -> _str($x);
        my $b_str = $class -> _str($base);
        my $xm    = "." . $x_str;
        my $bm    = "." . $b_str;
        my $xe    = length($x_str);
        my $be    = length($b_str);
        my $log10 = log(10);
        my $guess = int((log($xm) + $xe * $log10) / (log($bm) + $be * $log10));
        $y = $class -> _new($guess);
    }

    my $trial = $class -> _pow($class -> _copy($base), $y);
    my $acmp  = $class -> _acmp($trial, $x);

    # Did we get the exact result?

    return $y, 1 if $acmp == 0;

    # Too small?

    while ($acmp < 0) {
        $trial = $class -> _mul($trial, $base);
        $y     = $class -> _inc($y);
        $acmp  = $class -> _acmp($trial, $x);
    }

    # Too big?

    while ($acmp > 0) {
        $trial = $class -> _div($trial, $base);
        $y     = $class -> _dec($y);
        $acmp  = $class -> _acmp($trial, $x);
    }

    return $y, 1 if $acmp == 0;         # result is exact
    return $y, 0;                       # result is too small
}

sub _sqrt {
    # square-root of $x in place
    my ($class, $x) = @_;

    return $x if $class -> _is_zero($x);

    my $x_str = $class -> _str($x);
    my $x_len = length($x_str);

    # Compute the guess $y.

    my $ym;
    my $ye;
    if ($x_len % 2 == 0) {
        $ym = sqrt("." . $x_str);
        $ye = $x_len / 2;
        $ym = sprintf "%.0f", int($ym * 1e15);
        $ye -= 15;
    } else {
        $ym = sqrt(".0" . $x_str);
        $ye = ($x_len + 1) / 2;
        $ym = sprintf "%.0f", int($ym * 1e16);
        $ye -= 16;
    }

    my $y;
    if ($ye < 0) {
        $y = substr $ym, 0, length($ym) + $ye;
    } else {
        $y = $ym . ("0" x $ye);
    }

    $y = $class -> _new($y);

    # Newton's method for computing square root of x. Generally, the algorithm
    # below should undershoot.
    #
    # y(i+1) = y(i) - f(y(i)) / f'(y(i))
    #        = y(i) - (y(i)^2 - x) / (2 * y(i))
    #        = y(i) + (x - y(i)^2) / (2 * y(i))

    my $two  = $class -> _two();
    my $zero = $class -> _zero();
    my $over;
    my $acmp;

    {
        my $ysq = $class -> _mul($class -> _copy($y), $y);      # y(i)^2
        $acmp = $class -> _acmp($x, $ysq);                      # x <=> y(i)^2
        last if $acmp == 0;
        if ($acmp < 0) {           # if we overshot
            $over = 1;
            last;
        }

        my $num = $class -> _sub($class -> _copy($x), $ysq);    # x - y(i)^2
        my $den = $class -> _mul($class -> _copy($two), $y);    # 2 * y(i)

        my $delta = $class -> _div($num, $den);
        last if $class -> _acmp($delta, $zero) == 0;
        $y = $class -> _add($y, $delta);
        redo;
    }

    # If we did overshoot, adjust now.

    while ($acmp < 0) {
        $class -> _dec($y);
        my $ysq = $class -> _mul($class -> _copy($y), $y);      # y(i)^2
        $acmp = $class -> _acmp($x, $ysq);                      # x <=> y(i)^2
    }

    return $y;
}

sub _root {
    my ($class, $x, $n) = @_;

    return undef if $class -> _is_zero($n);

    return $x if $class -> _is_zero($x) || $class -> _is_one($x) ||
                 $class -> _is_one($n);

    my $x_str = $class -> _str($x);
    my $x_len = length($x_str);

    return $class -> _one() if $class -> _acmp($x, $n) <= 0;

    # Compute the guess $y.

    my $n_num = $class -> _num($n);
    my $p = int(($x_len - 1) / $n_num);
    my $q = $x_len - $p * $n_num;

    my $DEBUG = 0;

    if ($DEBUG) {
        print "\n";
        print substr($x_str, 0, $p), " ", "0" x $q, "\n";
        print "\n";
    }

    my $ymant = substr($x_str, 0, $q) ** (1 / $n_num);
    my $yexpo = $p;

    my $y = (1 + int $ymant) . ("0" x $p);
    $y = $class -> _new($y);

    if ($DEBUG) {
        print "\n";
        print "p  = $p\n";
        print "q  = $q\n";
        print "\n";
        print "ym = $ymant\n";
        print "ye = $yexpo\n";
        print "\n";
        print "y  = $y (initial guess)\n";
        print "\n";
    }

    # Newton's method for computing n'th root of x. Generally, the algorithm
    # below should undershoot.
    #
    # y(i+1) = y(i) - f(y(i)) / f'(y(i))
    #        = y(i) - (y(i)^n - x) / (n * y(i)^(n-1))
    #        = y(i) + (x - y(i)^n) / (n * y(i)^(n-1))

    my $nm1  = $class -> _dec($class -> _copy($n));             # n - 1
    my $zero = $class -> _zero();
    my $over;
    my $acmp;

    {
        my $ypowm1 = $class -> _pow($class -> _copy($y), $nm1);     # y(i)^(n-1)
        my $ypow   = $class -> _mul($class -> _copy($ypowm1), $y);  # y(i)^n
        $acmp = $class -> _acmp($x, $ypow);                         # x <=> y(i)^n
        last if $acmp == 0;

        my $num = $acmp > 0
                ? $class -> _sub($class -> _copy($x), $ypow)        # x - y(i)^n
                : $class -> _sub($ypow, $class -> _copy($x));       # y(i)^n - x
        my $den = $class -> _mul($class -> _copy($n), $ypowm1);     # n * y(i)^(n-1)
        my $delta = $class -> _div($num, $den);
        last if $class -> _acmp($delta, $zero) == 0;

        $y = $acmp > 0
           ? $class -> _add($y, $delta)
           : $class -> _sub($y, $delta);

        if ($DEBUG) {
            print "y  = $y\n";
        }

        redo;
    }

    # Never overestimate. The output should always be exact or truncated.

    while ($acmp < 0) {
        $class -> _dec($y);
        if ($DEBUG) {
            print "y  = $y\n";
        }
        my $ypow = $class -> _pow($class -> _copy($y), $n);     # y(i)^n
        $acmp = $class -> _acmp($x, $ypow);                     # x <=> y(i)^2
    }

    if ($DEBUG) {
        print "\n";
    }

    return $y;
}

##############################################################################
# binary stuff

sub _and {
    my ($class, $x, $y) = @_;

    return $x if $class -> _acmp($x, $y) == 0;

    my $m    = $class -> _one();
    my $mask = $class -> _new("32768");

    my ($xr, $yr);                # remainders after division

    my $xc = $class -> _copy($x);
    my $yc = $class -> _copy($y);
    my $z  = $class -> _zero();

    until ($class -> _is_zero($xc) || $class -> _is_zero($yc)) {
        ($xc, $xr) = $class -> _div($xc, $mask);
        ($yc, $yr) = $class -> _div($yc, $mask);
        my $bits = $class -> _new($class -> _num($xr) & $class -> _num($yr));
        $z = $class -> _add($z, $class -> _mul($bits, $m));
        $m = $class -> _mul($m, $mask);
    }

    return $z;
}

sub _xor {
    my ($class, $x, $y) = @_;

    return $class -> _zero() if $class -> _acmp($x, $y) == 0;

    my $m    = $class -> _one();
    my $mask = $class -> _new("32768");

    my ($xr, $yr);                # remainders after division

    my $xc = $class -> _copy($x);
    my $yc = $class -> _copy($y);
    my $z  = $class -> _zero();

    until ($class -> _is_zero($xc) || $class -> _is_zero($yc)) {
        ($xc, $xr) = $class -> _div($xc, $mask);
        ($yc, $yr) = $class -> _div($yc, $mask);
        my $bits = $class -> _new($class -> _num($xr) ^ $class -> _num($yr));
        $z = $class -> _add($z, $class -> _mul($bits, $m));
        $m = $class -> _mul($m, $mask);
    }

    # The loop above stops when the smallest of the two numbers is exhausted.
    # The remainder of the longer one will survive bit-by-bit, so we simple
    # multiply-add it in.

    $z = $class -> _add($z, $class -> _mul($xc, $m))
      unless $class -> _is_zero($xc);
    $z = $class -> _add($z, $class -> _mul($yc, $m))
      unless $class -> _is_zero($yc);

    return $z;
}

sub _or {
    my ($class, $x, $y) = @_;

    return $x if $class -> _acmp($x, $y) == 0; # shortcut (see _and)

    my $m    = $class -> _one();
    my $mask = $class -> _new("32768");

    my ($xr, $yr);                # remainders after division

    my $xc = $class -> _copy($x);
    my $yc = $class -> _copy($y);
    my $z  = $class -> _zero();

    until ($class -> _is_zero($xc) || $class -> _is_zero($yc)) {
        ($xc, $xr) = $class -> _div($xc, $mask);
        ($yc, $yr) = $class -> _div($yc, $mask);
        my $bits = $class -> _new($class -> _num($xr) | $class -> _num($yr));
        $z = $class -> _add($z, $class -> _mul($bits, $m));
        $m = $class -> _mul($m, $mask);
    }

    # The loop above stops when the smallest of the two numbers is exhausted.
    # The remainder of the longer one will survive bit-by-bit, so we simple
    # multiply-add it in.

    $z = $class -> _add($z, $class -> _mul($xc, $m))
      unless $class -> _is_zero($xc);
    $z = $class -> _add($z, $class -> _mul($yc, $m))
      unless $class -> _is_zero($yc);

    return $z;
}

sub _as_hex {
    # convert a decimal number to hex
    my ($class, $x) = @_;
    my $str  = '';
    my $tmp  = $class -> _copy($x);
    my $zero = $class -> _zero();
    my $base = $class -> _new("16");
    my $rem;
    while ($tmp > $zero) {
        ($tmp, $rem) = $class -> _div($tmp, $base);
        $str = sprintf("%0x", $rem) . $str;
    }
    $str = '0' if length($str) == 0;
    return '0x' . $str;
}

sub _as_bin {
    # convert a decimal number to bin
    my ($class, $x) = @_;
    my $str  = '';
    my $tmp  = $class -> _copy($x);
    my $zero = $class -> _zero();
    my $base = $class -> _new("2");
    my $rem;
    while ($tmp > $zero) {
        ($tmp, $rem) = $class -> _div($tmp, $base);
        $str = ($class -> _is_zero($rem) ? '0' : '1') . $str;
    }
    $str = '0' if length($str) == 0;
    return '0b' . $str;
}

sub _as_oct {
    # convert a decimal number to octal
    my ($class, $x) = @_;
    my $str  = '';
    my $tmp  = $class -> _copy($x);
    my $zero = $class -> _zero();
    my $base = $class -> _new("8");
    my $rem;
    while ($tmp > $zero) {
        ($tmp, $rem) = $class -> _div($tmp, $base);
        $str = sprintf("%0o", $rem) . $str;
    }
    $str = '0' if length($str) == 0;
    return '0' . $str;          # yes, 0 becomes "00".
}

sub _as_bytes {
    # convert a decimal number to a byte string
    my ($class, $x) = @_;
    my $str  = '';
    my $tmp  = $class -> _copy($x);
    my $base = $class -> _new("256");
    my $rem;
    until ($class -> _is_zero($tmp)) {
        ($tmp, $rem) = $class -> _div($tmp, $base);
        my $byte = pack 'C', $rem;
        $str = $byte . $str;
    }
    return "\x00" unless length($str);
    return $str;
}

sub _from_oct {
    # convert a octal string to a decimal number
    my ($class, $str) = @_;
    $str =~ s/^0+//;
    my $x    = $class -> _zero();
    my $base = $class -> _new("8");
    my $n    = length($str);
    for (my $i = 0 ; $i < $n ; ++$i) {
        $x = $class -> _mul($x, $base);
        $x = $class -> _add($x, $class -> _new(substr($str, $i, 1)));
    }
    return $x;
}

sub _from_hex {
    # convert a hexadecimal string to a decimal number
    my ($class, $str) = @_;
    $str =~ s/^0[Xx]//;
    my $x    = $class -> _zero();
    my $base = $class -> _new("16");
    my $n    = length($str);
    for (my $i = 0 ; $i < $n ; ++$i) {
        $x = $class -> _mul($x, $base);
        $x = $class -> _add($x, $class -> _new(hex substr($str, $i, 1)));
    }
    return $x;
}

sub _from_bin {
    # convert a binary string to a decimal number
    my ($class, $str) = @_;
    $str =~ s/^0[Bb]//;
    my $x    = $class -> _zero();
    my $base = $class -> _new("2");
    my $n    = length($str);
    for (my $i = 0 ; $i < $n ; ++$i) {
        $x = $class -> _mul($x, $base);
        $x = $class -> _add($x, $class -> _new(substr($str, $i, 1)));
    }
    return $x;
}

sub _from_bytes {
    # convert a byte string to a decimal number
    my ($class, $str) = @_;
    my $x    = $class -> _zero();
    my $base = $class -> _new("256");
    my $n    = length($str);
    for (my $i = 0 ; $i < $n ; ++$i) {
        $x = $class -> _mul($x, $base);
        my $byteval = $class -> _new(unpack 'C', substr($str, $i, 1));
        $x = $class -> _add($x, $byteval);
    }
    return $x;
}

##############################################################################
# special modulus functions

sub _modinv {
    # modular multiplicative inverse
    my ($class, $x, $y) = @_;

    # modulo zero
    if ($class -> _is_zero($y)) {
        return (undef, undef);
    }

    # modulo one
    if ($class -> _is_one($y)) {
        return ($class -> _zero(), '+');
    }

    my $u = $class -> _zero();
    my $v = $class -> _one();
    my $a = $class -> _copy($y);
    my $b = $class -> _copy($x);

    # Euclid's Algorithm for bgcd().

    my $q;
    my $sign = 1;
    {
        ($a, $q, $b) = ($b, $class -> _div($a, $b));
        last if $class -> _is_zero($b);

        my $vq = $class -> _mul($class -> _copy($v), $q);
        my $t = $class -> _add($vq, $u);
        $u = $v;
        $v = $t;
        $sign = -$sign;
        redo;
    }

    # if the gcd is not 1, then return NaN
    return (undef, undef) unless $class -> _is_one($a);

    ($v, $sign == 1 ? '+' : '-');
}

sub _modpow {
    # modulus of power ($x ** $y) % $z
    my ($class, $num, $exp, $mod) = @_;

    # a^b (mod 1) = 0 for all a and b
    if ($class -> _is_one($mod)) {
        return $class -> _zero();
    }

    # 0^a (mod m) = 0 if m != 0, a != 0
    # 0^0 (mod m) = 1 if m != 0
    if ($class -> _is_zero($num)) {
        return $class -> _is_zero($exp) ? $class -> _one()
                                        : $class -> _zero();
    }

    #  $num = $class -> _mod($num, $mod);   # this does not make it faster

    my $acc = $class -> _copy($num);
    my $t   = $class -> _one();

    my $expbin = $class -> _as_bin($exp);
    $expbin =~ s/^0b//;
    my $len = length($expbin);

    while (--$len >= 0) {
        if (substr($expbin, $len, 1) eq '1') {
            $t = $class -> _mul($t, $acc);
            $t = $class -> _mod($t, $mod);
        }
        $acc = $class -> _mul($acc, $acc);
        $acc = $class -> _mod($acc, $mod);
    }
    return $t;
}

sub _gcd {
    # Greatest common divisor.

    my ($class, $x, $y) = @_;

    # gcd(0, 0) = 0
    # gcd(0, a) = a, if a != 0

    if ($class -> _acmp($x, $y) == 0) {
        return $class -> _copy($x);
    }

    if ($class -> _is_zero($x)) {
        if ($class -> _is_zero($y)) {
            return $class -> _zero();
        } else {
            return $class -> _copy($y);
        }
    } else {
        if ($class -> _is_zero($y)) {
            return $class -> _copy($x);
        } else {

            # Until $y is zero ...

            $x = $class -> _copy($x);
            until ($class -> _is_zero($y)) {

                # Compute remainder.

                $x = $class -> _mod($x, $y);

                # Swap $x and $y.

                my $tmp = $x;
                $x = $class -> _copy($y);
                $y = $tmp;
            }

            return $x;
        }
    }
}

sub _lcm {
    # Least common multiple.

    my ($class, $x, $y) = @_;

    # lcm(0, x) = 0 for all x

    return $class -> _zero()
      if ($class -> _is_zero($x) ||
          $class -> _is_zero($y));

    my $gcd = $class -> _gcd($class -> _copy($x), $y);
    $x = $class -> _div($x, $gcd);
    $x = $class -> _mul($x, $y);
    return $x;
}

##############################################################################
##############################################################################

1;

__END__

=pod

=head1 NAME

Math::BigInt::Lib - virtual parent class for Math::BigInt libraries

=head1 SYNOPSIS

This module provides support for big integer calculations. It is not intended
to be used directly, but rather as a parent class for backend libraries used by
Math::BigInt, Math::BigFloat, Math::BigRat, and related modules. Backend
libraries include Math::BigInt::Calc, Math::BigInt::FastCalc,
Math::BigInt::GMP, Math::BigInt::Pari and others.

=head1 DESCRIPTION

In order to allow for multiple big integer libraries, Math::BigInt was
rewritten to use a plug-in library for core math routines. Any module which
conforms to the API can be used by Math::BigInt by using this in your program:

        use Math::BigInt lib => 'libname';

'libname' is either the long name, like 'Math::BigInt::Pari', or only the short
version, like 'Pari'.

=head2 General Notes

A library only needs to deal with unsigned big integers. Testing of input
parameter validity is done by the caller, so there is no need to worry about
underflow (e.g., in C<_sub()> and C<_dec()>) nor about division by zero (e.g.,
in C<_div()>) or similar cases.

Some libraries use methods that don't modify their argument, and some libraries
don't even use objects. Because of this, liberary methods are always called as
class methods, not instance methods:

    $x = Class -> method($x, $y);     # like this
    $x = $x -> method($y);            # not like this ...
    $x -> method($y);                 # ... or like this

And with boolean methods

    $bool = Class -> method($x, $y);  # like this
    $bool = $x -> method($y);         # not like this ...

Return values are always objects, strings, Perl scalars, or true/false for
comparison routines.

=head3 API version

=over 4

=item api_version()

Return API version as a Perl scalar, 1 for Math::BigInt v1.70, 2 for
Math::BigInt v1.83.

This method is no longer used. Methods that are not implemented by a subclass
will be inherited from this class.

=back

=head3 Constructors

The following methods are mandatory: _new(), _str(), _add(), and _sub().
However, computations will be very slow without _mul() and _div().

=over 4

=item _new(STR)

Convert a string representing an unsigned decimal number to an object
representing the same number. The input is normalize, i.e., it matches
C<^(0|[1-9]\d*)$>.

=item _zero()

Return an object representing the number zero.

=item _one()

Return an object representing the number one.

=item _two()

Return an object representing the number two.

=item _ten()

Return an object representing the number ten.

=item _from_bin(STR)

Return an object given a string representing a binary number. The input has a
'0b' prefix and matches the regular expression C<^0[bB](0|1[01]*)$>.

=item _from_oct(STR)

Return an object given a string representing an octal number. The input has a
'0' prefix and matches the regular expression C<^0[1-7]*$>.

=item _from_hex(STR)

Return an object given a string representing a hexadecimal number. The input
has a '0x' prefix and matches the regular expression
C<^0x(0|[1-9a-fA-F][\da-fA-F]*)$>.

=item _from_bytes(STR)

Returns an object given a byte string representing the number. The byte string
is in big endian byte order, so the two-byte input string "\x01\x00" should
give an output value representing the number 256.

=back

=head3 Mathematical functions

=over 4

=item _add(OBJ1, OBJ2)

Returns the result of adding OBJ2 to OBJ1.

=item _mul(OBJ1, OBJ2)

Returns the result of multiplying OBJ2 and OBJ1.

=item _div(OBJ1, OBJ2)

Returns the result of dividing OBJ1 by OBJ2 and truncating the result to an
integer.

=item _sub(OBJ1, OBJ2, FLAG)

=item _sub(OBJ1, OBJ2)

Returns the result of subtracting OBJ2 by OBJ1. If C<flag> is false or omitted,
OBJ1 might be modified. If C<flag> is true, OBJ2 might be modified.

=item _dec(OBJ)

Decrement OBJ by one.

=item _inc(OBJ)

Increment OBJ by one.

=item _mod(OBJ1, OBJ2)

Return OBJ1 modulo OBJ2, i.e., the remainder after dividing OBJ1 by OBJ2.

=item _sqrt(OBJ)

Return the square root of the object, truncated to integer.

=item _root(OBJ, N)

Return Nth root of the object, truncated to int. N is E<gt>= 3.

=item _fac(OBJ)

Return factorial of object (1*2*3*4*...).

=item _pow(OBJ1, OBJ2)

Return OBJ1 to the power of OBJ2. By convention, 0**0 = 1.

=item _modinv(OBJ1, OBJ2)

Return modular multiplicative inverse, i.e., return OBJ3 so that

    (OBJ3 * OBJ1) % OBJ2 = 1 % OBJ2

The result is returned as two arguments. If the modular multiplicative
inverse does not exist, both arguments are undefined. Otherwise, the
arguments are a number (object) and its sign ("+" or "-").

The output value, with its sign, must either be a positive value in the
range 1,2,...,OBJ2-1 or the same value subtracted OBJ2. For instance, if the
input arguments are objects representing the numbers 7 and 5, the method
must either return an object representing the number 3 and a "+" sign, since
(3*7) % 5 = 1 % 5, or an object representing the number 2 and "-" sign,
since (-2*7) % 5 = 1 % 5.

=item _modpow(OBJ1, OBJ2, OBJ3)

Return modular exponentiation, (OBJ1 ** OBJ2) % OBJ3.

=item _rsft(OBJ, N, B)

Shift object N digits right in base B and return the resulting object. This is
equivalent to performing integer division by B**N and discarding the remainder,
except that it might be much faster, depending on how the number is represented
internally.

For instance, if the object $obj represents the hexadecimal number 0xabcde,
then C<_rsft($obj, 2, 16)> returns an object representing the number 0xabc. The
"remainer", 0xde, is discarded and not returned.

=item _lsft(OBJ, N, B)

Shift the object N digits left in base B. This is equivalent to multiplying by
B**N, except that it might be much faster, depending on how the number is
represented internally.

=item _log_int(OBJ, B)

Return integer log of OBJ to base BASE. This method has two output arguments,
the OBJECT and a STATUS. The STATUS is Perl scalar; it is 1 if OBJ is the exact
result, 0 if the result was truncted to give OBJ, and undef if it is unknown
whether OBJ is the exact result.

=item _gcd(OBJ1, OBJ2)

Return the greatest common divisor of OBJ1 and OBJ2.

=item _lcm(OBJ1, OBJ2)

Return the least common multiple of OBJ1 and OBJ2.

=back

=head3 Bitwise operators

Each of these methods may modify the first input argument.

=over 4

=item _and(OBJ1, OBJ2)

Return bitwise and. If necessary, the smallest number is padded with leading
zeros.

=item _or(OBJ1, OBJ2)

Return bitwise or. If necessary, the smallest number is padded with leading
zeros.

=item _xor(OBJ1, OBJ2)

Return bitwise exclusive or. If necessary, the smallest number is padded
with leading zeros.

=back

=head3 Boolean operators

=over 4

=item _is_zero(OBJ)

Returns a true value if OBJ is zero, and false value otherwise.

=item _is_one(OBJ)

Returns a true value if OBJ is one, and false value otherwise.

=item _is_two(OBJ)

Returns a true value if OBJ is two, and false value otherwise.

=item _is_ten(OBJ)

Returns a true value if OBJ is ten, and false value otherwise.

=item _is_even(OBJ)

Return a true value if OBJ is an even integer, and a false value otherwise.

=item _is_odd(OBJ)

Return a true value if OBJ is an even integer, and a false value otherwise.

=item _acmp(OBJ1, OBJ2)

Compare OBJ1 and OBJ2 and return -1, 0, or 1, if OBJ1 is less than, equal
to, or larger than OBJ2, respectively.

=back

=head3 String conversion

=over 4

=item _str(OBJ)

Return a string representing the object. The returned string should have no
leading zeros, i.e., it should match C<^(0|[1-9]\d*)$>.

=item _as_bin(OBJ)

Return the binary string representation of the number. The string must have a
'0b' prefix.

=item _as_oct(OBJ)

Return the octal string representation of the number. The string must have
a '0x' prefix.

Note: This method was required from Math::BigInt version 1.78, but the required
API version number was not incremented, so there are older libraries that
support API version 1, but do not support C<_as_oct()>.

=item _as_hex(OBJ)

Return the hexadecimal string representation of the number. The string must
have a '0x' prefix.

=item _as_bytes(OBJ)

Return a byte string representation of the number. The byte string is in big
endian byte order, so if the object represents the number 256, the output
should be the two-byte string "\x01\x00".

=back

=head3 Numeric conversion

=over 4

=item _num(OBJ)

Given an object, return a Perl scalar number (int/float) representing this
number.

=back

=head3 Miscellaneous

=over 4

=item _copy(OBJ)

Return a true copy of the object.

=item _len(OBJ)

Returns the number of the decimal digits in the number. The output is a
Perl scalar.

=item _zeros(OBJ)

Return the number of trailing decimal zeros. The output is a Perl scalar.

=item _digit(OBJ, N)

Return the Nth digit as a Perl scalar. N is a Perl scalar, where zero refers to
the rightmost (least significant) digit, and negative values count from the
left (most significant digit). If $obj represents the number 123, then
I<$obj->_digit(0)> is 3 and I<_digit(123, -1)> is 1.

=item _check(OBJ)

Return true if the object is invalid and false otherwise. Preferably, the true
value is a string describing the problem with the object. This is a check
routine to test the internal state of the object for corruption.

=back

=head2 API version 2

The following methods are required for an API version of 2 or greater.

=head3 Constructors

=over 4

=item _1ex(N)

Return an object representing the number 10**N where N E<gt>= 0 is a Perl
scalar.

=back

=head3 Mathematical functions

=over 4

=item _nok(OBJ1, OBJ2)

Return the binomial coefficient OBJ1 over OBJ1.

=back

=head3 Miscellaneous

=over 4

=item _alen(OBJ)

Return the approximate number of decimal digits of the object. The output is a
Perl scalar.

=back

=head2 API optional methods

The following methods are optional, and can be defined if the underlying lib
has a fast way to do them. If undefined, Math::BigInt will use pure Perl (hence
slow) fallback routines to emulate these:

=head3 Signed bitwise operators.

=over 4

=item _signed_or(OBJ1, OBJ2, SIGN1, SIGN2)

Return the signed bitwise or.

=item _signed_and(OBJ1, OBJ2, SIGN1, SIGN2)

Return the signed bitwise and.

=item _signed_xor(OBJ1, OBJ2, SIGN1, SIGN2)

Return the signed bitwise exclusive or.

=back

=head1 WRAP YOUR OWN

If you want to port your own favourite C library for big numbers to the
Math::BigInt interface, you can take any of the already existing modules as a
rough guideline. You should really wrap up the latest Math::BigInt and
Math::BigFloat testsuites with your module, and replace in them any of the
following:

        use Math::BigInt;

by this:

        use Math::BigInt lib => 'yourlib';

This way you ensure that your library really works 100% within Math::BigInt.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-bigint at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt>
(requires login).
We will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::BigInt::Calc

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-BigInt>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-BigInt>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Math-BigInt>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-BigInt/>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-BigInt>

=item * The Bignum mailing list

=over 4

=item * Post to mailing list

C<bignum at lists.scsys.co.uk>

=item * View mailing list

L<http://lists.scsys.co.uk/pipermail/bignum/>

=item * Subscribe/Unsubscribe

L<http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/bignum>

=back

=back

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Peter John Acklam, E<lt>pjacklam@online.noE<gt>

Code and documentation based on the Math::BigInt::Calc module by Tels
E<lt>nospam-abuse@bloodgate.comE<gt>

=head1 SEE ALSO

L<Math::BigInt>, L<Math::BigInt::Calc>, L<Math::BigInt::GMP>,
L<Math::BigInt::FastCalc> and L<Math::BigInt::Pari>.

=cut

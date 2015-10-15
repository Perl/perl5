#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        require Test::More;
        Test::More::plan(skip_all => 'these tests are for release candidate testing');
    }
}

use strict;
use warnings;

use Test::More tests => 139;
use Scalar::Util qw< refaddr >;

my $class;

BEGIN { $class = 'Math::BigFloat'; }
BEGIN { use_ok($class) }

while (<DATA>) {
    s/\s+\z//;
    next if /^#/ || ! /\S/;

    # $in0 - the x value
    # $in1 - the base
    # $out0 - the wanted output value
    # $type - the type of the wanted number (real, non-real, ...)
    # $expr - mathematical expression of the wanted number

    my ($in0, $in1, $out0, $type, $expr) = split /:/;

    # Some of the test data use rational numbers.
    # - with Math::BigInt, we skip them
    # - with Math::BigFloat, we convert them to floats
    # - with Math::BigRat, we use them as they are

    $in0  = eval $in0  if $in0  =~ m|/|;
    $in1  = eval $in1  if $in1  =~ m|/|;
    $out0 = eval $out0 if $out0 =~ m|/|;

    my ($x, $y);        # input values as objects
    my ($yo);           # copy of input value
    my ($got);          # test output

    my $test = qq|\$x = $class -> new("$in0"); | .
               qq|\$y = $class -> new("$in1"); | .
               qq|\$yo = \$y -> copy(); | .
               qq|\$got = \$x -> blog(\$y);|;

    my $desc = "logarithm of $in0 to base $in1";

    print("#\n",
          "# Now about to execute the following test.\n",
          "#\n",
          "# $test\n",
          "#\n");

    if ($in0 ne 'NaN' && $in1 ne 'NaN') {
        print("# Enter log($in1, $in0) into Wolfram Alpha",
              " (http://www.wolframalpha.com/), and it says that the result",
              " is ", length($type) ? $type : "real",
              length($expr) ? ": $expr" : "",
              ".", "\n",
              "#\n");
    }

    eval $test;
    die $@ if $@;       # this should never happen

    subtest $desc, sub {
        plan tests => 5,

        # Check output.

        is(ref($got), $class, "output arg is a $class");
        is($got, $out0, 'output arg has the right value');
        is(refaddr($got), refaddr($x), 'output arg is the invocand');

        # The second argument (if the invocand is the first) shall *not* be
        # modified.

        is(ref($y), $class, "second input arg is still a $class");
        is_deeply($y, $yo, 'second output arg is unmodified');

    };

}

__END__

# base = -inf

-inf:-inf:NaN:undefined:
-4:-inf:0::
-2:-inf:0::
-1:-inf:0::
-1/2:-inf:0::
0:-inf:NaN:undefined:
1/2:-inf:0::
1:-inf:0::
2:-inf:0::
4:-inf:0::
inf:-inf:NaN:undefined:
NaN:-inf:NaN:undefined:

# base = -4

-4:-4:1::
-2:-4:NaN:non-real and finite:(log(2)+i pi)/(log(4)+i pi)
0:-4:NaN:non-real (directed) infinity:(-sqrt(pi^2+log^2(4))/(log(4)+i pi))infinity
1/2:-4:NaN:non-real and finite:-(log(2))/(log(4)+i pi)
1:-4:0::
2:-4:NaN:non-real and finite:(log(2))/(log(4)+i pi)
4:-4:NaN:non-real and finite:(log(4))/(log(4)+i pi)
NaN:-4:NaN:undefined:

# base = -2

-inf:-2:NaN:non-real (directed) infinity:sqrt(pi^2+log^2(2))/(log(2)+i pi)infinity
-4:-2:NaN:non-real and finite:(log(4)+i pi)/(log(2)+i pi)
-2:-2:1::
-1:-2:NaN:non-real and finite:(i pi)/(log(2)+i pi)
-1/2:-2:NaN:non-real and finite:(-log(2)+i pi)/(log(2)+i pi)
0:-2:NaN:complex infinity:
1/2:-2:NaN:non-real and finite:-(log(2))/(log(2)+i pi)
1:-2:0::
2:-2:NaN:non-real and finite:(log(2))/(log(2)+i pi)
4:-2:NaN:non-real and finite:(log(4))/(log(2)+i pi)
inf:-2:NaN:non-real (directed) infinity:
NaN:-2:NaN:undefined:

# base = -1

-inf:-1:NaN:non-real (directed) infinity:
-4:-1:NaN:non-real and finite:-(i (log(4)+i pi))/pi
-2:-1:NaN:non-real and finite:-(i (log(2)+i pi))/pi
-1:-1:1::
-1/2:-1:NaN:non-real and finite:-(i (-log(2)+i pi))/pi
0:-1:NaN:complex infinity:
1:-1:0::
1/2:-1:NaN:non-real and finite:(i log(2))/pi
2:-1:NaN:non-real and finite:-(i log(2))/pi
4:-1:NaN:non-real and finite:-(i log(4))/pi
inf:-1:NaN:non-real (directed) infinity:
NaN:-1:NaN:undefined:

# base = -1/2

-inf:-1/2:NaN:non-real (directed) infinity:
-4:-1/2:NaN:non-real and finite:(log(4)+i pi)/(-log(2)+i pi)
-2:-1/2:NaN:non-real and finite:(log(2)+i pi)/(-log(2)+i pi)
-1:-1/2:NaN:non-real and finite:(i pi)/(-log(2)+i pi)
-1/2:-1/2:1::
0:-1/2:NaN:complex infinity:
1:-1/2:0::
1/2:-1/2:NaN:non-real and finite:-(log(2))/(-log(2)+i pi)
2:-1/2:NaN:non-real and finite:(log(2))/(-log(2)+i pi)
4:-1/2:NaN:non-real and finite:(log(4))/(-log(2)+i pi)
inf:-1/2:NaN:non-real (directed) infinity:
NaN:-1/2:NaN:undefined:

# base = 0

-inf:0:NaN:undefined:
-4:0:0::
-2:0:0::
-1:0:0::
-1/2:0:0::
0:0:NaN:undefined:
1/2:0:0::
1:0:0::
2:0:0::
4:0:0::
inf:0:NaN:undefined:
NaN:0:NaN:undefined:

# base = 1/2

-inf:1/2:-inf::
-2:-1/2:NaN:non-real and finite:(log(2)+i pi)/(-log(2)+i pi)
-1:1/2:NaN:non-real and finite:-(i pi)/(log(2))
-1/2:1/2:NaN:non-real and finite:-(-log(2)+i pi)/(log(2))
0:1/2:inf::
1/2:1/2:1::
1:1/2:0::
2:1/2:-1::
inf:1/2:-inf::
NaN:1/2:NaN:undefined:

# base = 1

-inf:1:NaN:complex infinity:
-4:1:NaN:complex infinity:
-2:1:NaN:complex infinity:
-1:1:NaN:complex infinity:
-1/2:1:NaN:complex infinity:
0:1:NaN:complex infinity:
1/2:1:NaN:complex infinity:
1:1:NaN:undefined:
2:1:NaN:complex infinity:
4:1:NaN:complex infinity:
inf:1:NaN:complex infinity:
NaN:1:NaN:undefined:

# base = 2

-inf:2:inf::
-4:2:NaN:non-real and finite:(log(4)+i pi)/(log(2))
-2:2:NaN:non-real and finite:(log(2)+i pi)/(log(2))
-1:2:NaN:non-real and finite:(i pi)/(log(2))
-1/2:2:NaN:non-real and finite:(-log(2)+i pi)/(log(2))
0:2:-inf::
1/2:2:-1::
1:2:0::
2:2:1::
4:2:2::
4:4:1::
inf:2:inf::
NaN:2:NaN:undefined:

# base = 4

-inf:4:inf::
-4:4:NaN:non-real and finite:(log(4)+i pi)/(log(4))
-2:4:NaN:non-real and finite:(log(2)+i pi)/(log(4))
-1/2:4:NaN:non-real and finite:(-log(2)+i pi)/(log(4))
0:4:-inf::
1:4:0::
1/2:4:-1/2::
2:4:1/2::
4:4:1::
inf:4:inf::
NaN:4:NaN:undefined:

# base = inf

-inf:inf:NaN:undefined:
-4:inf:0::
-2:inf:0::
-1:inf:0::
-1/2:inf:0::
0:inf:NaN:undefined:
1:inf:0::
1/2:inf:0::
2:inf:0::
4:inf:0::
inf:inf:NaN:undefined:
NaN:inf:NaN:undefined:

# base is NaN

-inf:NaN:NaN:undefined:
-4:NaN:NaN:undefined:
-2:NaN:NaN:undefined:
-1:NaN:NaN:undefined:
-1/2:NaN:NaN:undefined:
0:NaN:NaN:undefined:
1:NaN:NaN:undefined:
1/2:NaN:NaN:undefined:
2:NaN:NaN:undefined:
4:NaN:NaN:undefined:
inf:NaN:NaN:undefined:
NaN:NaN:NaN:undefined:

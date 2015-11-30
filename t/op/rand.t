#!./perl

# From Tom Phoenix <rootbeer@teleport.com> 22 Feb 1997
# Based upon a test script by kgb@ast.cam.ac.uk (Karl Glazebrook)

# Looking for the hints? You're in the right place. 
# The hints are near each test, so search for "TEST #", where
# the pound sign is replaced by the number of the test.

# I'd like to include some more robust tests, but anything
# too subtle to be detected here would require a time-consuming
# test. Also, of course, we're here to detect only flaws in Perl;
# if there are flaws in the underlying system rand, that's not
# our responsibility. But if you want better tests, see
# The Art of Computer Programming, Donald E. Knuth, volume 2,
# chapter 3. ISBN 0-201-03822-6 (v. 2)

BEGIN {
    chdir "t" if -d "t";
    @INC = qw(. ../lib);
}

use strict;
use Config;

require "./test.pl";
plan(tests => 9);


my $reps = 15000;	# How many times to try rand each time.
			# May be changed, but should be over 500.
			# The more the better! (But slower.)

sub bits ($) {
    # Takes a small integer and returns the number of one-bits in it.
    my $total;
    my $bits = sprintf "%o", $_[0];
    while (length $bits) {
	$total += (0,1,1,2,1,2,2,3)[chop $bits];	# Oct to bits
    }
    $total;
}

# First, let's see whether randbits is set right
{
    my($max, $min, $sum);	# Characteristics of rand
    my($off, $shouldbe);	# Problems with randbits
    my($dev, $bits);		# Number of one bits
    my $randbits = $Config{randbits};
    $max = -1;
    $min = 2;
    for (1..$reps) {
	my $n = rand(1);
	if ($n < 0.0 or $n >= 1.0) {
	    diag(<<EOM);
WHOA THERE!  \$Config{drand01} is set to '$Config{drand01}',
but that apparently produces values ($n) < 0.0 or >= 1.0.
Make sure \$Config{drand01} is a valid expression in the
C-language, and produces values in the range [0.0,1.0).

I give up.
EOM
	    exit;
	}
	$sum += $n;
	$bits += bits($n * 256);	# Don't be greedy; 8 is enough
		    # It's too many if randbits is less than 8!
		    # But that should never be the case... I hope.
		    # Note: If you change this, you must adapt the
		    # formula for absolute standard deviation, below.
	$max = $n if $n > $max;
	$min = $n if $n < $min;
    }

    # This is just a crude test. The average number produced
    # by rand should be about one-half. But once in a while
    # it will be relatively far away. Note: This test will
    # occasionally fail on a perfectly good system!
    # See the hints for test 4 to see why.
    #
    $sum /= $reps;
    ok($sum >= 0.4 && $sum <= 0.6, "average is 0.5")
	or diag("Average random number ($sum) is far from 0.5");


    #   NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
    # This test will fail .006% of the time on a normal system.
    #				also
    # This test asks you to see these hints 100% of the time!
    #   NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
    #
    # There is probably no reason to be alarmed that
    # something is wrong with your rand function. But,
    # if you're curious or if you can't help being 
    # alarmed, keep reading.
    #
    # This is a less-crude test than test 3. But it has
    # the same basic flaw: Unusually distributed random
    # values should occasionally appear in every good
    # random number sequence. (If you flip a fair coin
    # twenty times every day, you'll see it land all
    # heads about one time in a million days, on the
    # average. That might alarm you if you saw it happen
    # on the first day!)
    #
    # So, if this test failed on you once, run it a dozen
    # times. If it keeps failing, it's likely that your
    # rand is bogus. If it keeps passing, it's likely
    # that the one failure was bogus. If it's a mix,
    # read on to see about how to interpret the tests.
    #
    # The number printed in square brackets is the
    # standard deviation, a statistical measure
    # of how unusual rand's behavior seemed. It should
    # fall in these ranges with these *approximate*
    # probabilities:
    #
    #		under 1		68.26% of the time
    #		1-2		27.18% of the time
    #		2-3		 4.30% of the time
    #		over 3		 0.26% of the time
    #
    # If the numbers you see are not scattered approximately
    # (not exactly!) like that table, check with your vendor
    # to find out what's wrong with your rand. Or with this
    # algorithm. :-)
    #
    # Calculating absolute standard deviation for number of bits set
    # (eight bits per rep)
    $dev = abs ($bits - $reps * 4) / sqrt($reps * 2);

    cmp_ok($dev,  '<',  4.0, "standard deviation");

    if ($dev < 1.96) {
	print "# Your rand seems fine. If this test failed\n";
	print "# previously, you may want to run it again.\n";
    } elsif ($dev < 2.575) {
	print "# This is ok, but suspicious. But it will happen\n";
	print "# one time out of 25, more or less.\n";
	print "# You should run this test again to be sure.\n";
    } elsif ($dev < 3.3) {
	print "# This is very suspicious. It will happen only\n";
	print "# about one time out of 100, more or less.\n";
	print "# You should run this test again to be sure.\n";
    } elsif ($dev < 3.9) {
	print "# This is VERY suspicious. It will happen only\n";
	print "# about one time out of 1000, more or less.\n";
	print "# You should run this test again to be sure.\n";
    } else {
	print "# This is VERY VERY suspicious.\n";
	print "# Your rand seems to be bogus.\n";
    }
    print "#\n# If you are having random number troubles,\n";
    print "# see the hints within the test script for more\n";
    printf "# information on why this might fail. [ %.3f ]\n", $dev;
}


# Now, let's see whether rand accepts its argument
{
    my($max, $min);
    $max = $min = rand(100);
    for (1..$reps) {
	my $n = rand(100);
	$max = $n if $n > $max;
	$min = $n if $n < $min;
    }

    # This test checks to see that rand(100) really falls 
    # within the range 0 - 100, and that the numbers produced
    # have a reasonably-large range among them.
    #
    cmp_ok($min,        '>=',  0, "rand(100) >= 0");
    cmp_ok($max,        '<', 100, "rand(100) < 100");
    cmp_ok($max - $min, '>=', 65, "rand(100) in 65 range");


    # This test checks that rand without an argument
    # is equivalent to rand(1).
    #
    $_ = 12345;		# Just for fun.
    srand 12345;
    my $r = rand;
    srand 12345;
    is(rand(1),  $r,  'rand() without args is rand(1)');


    # This checks that rand without an argument is not
    # rand($_). (In case somebody got overzealous.)
    # 
    cmp_ok($r, '<', 1,   'rand() without args is under 1');
}

{ # [perl #115928] use a standard rand() implementation
    srand(1);
    is(int rand(1000), 41, "our own implementation behaves consistently");
    is(int rand(1000), 454, "and still consistently");
}

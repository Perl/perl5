#!./perl 

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

# NOTE!
#
# Think carefully before adding tests here.  In general this should be
# used only for about three categories of tests:
#
# (1) tests that absolutely require 'use utf8', and since that in general
#     shouldn't be needed as the utf8 is being obsoleted, this should
#     have rather few tests.  If you want to test Unicode and regexes,
#     you probably want to go to op/regexp or op/pat; if you want to test
#     split, go to op/split; pack, op/pack; appending or joining,
#     op/append or op/join, and so forth
#
# (2) tests that have to do with Unicode tokenizing (though it's likely
#     that all the other Unicode tests sprinkled around the t/**/*.t are
#     going to catch that)
#
# (3) complicated tests that simultaneously stress so many Unicode features
#     that deciding into which other test script the tests should go to
#     is hard -- maybe consider breaking up the complicated test
#
#

use Test;
plan tests => 15;

{
    # bug id 20001009.001

    my ($a, $b);

    { use bytes; $a = "\xc3\xa4" }
    { use utf8;  $b = "\xe4"     }

    my $test = 68;

    ok($a ne $b);

    { use utf8; ok($a ne $b) }
}


{
    # bug id 20000730.004

    my $smiley = "\x{263a}";

    for my $s ("\x{263a}",
	       $smiley,
		
	       "" . $smiley,
	       "" . "\x{263a}",

	       $smiley    . "",
	       "\x{263a}" . "",
	       ) {
	my $length_chars = length($s);
	my $length_bytes;
	{ use bytes; $length_bytes = length($s) }
	my @regex_chars = $s =~ m/(.)/g;
	my $regex_chars = @regex_chars;
	my @split_chars = split //, $s;
	my $split_chars = @split_chars;
	ok("$length_chars/$regex_chars/$split_chars/$length_bytes" eq
	   "1/1/1/3");
    }

    for my $s ("\x{263a}" . "\x{263a}",
	       $smiley    . $smiley,

	       "\x{263a}\x{263a}",
	       "$smiley$smiley",
	       
	       "\x{263a}" x 2,
	       $smiley    x 2,
	       ) {
	my $length_chars = length($s);
	my $length_bytes;
	{ use bytes; $length_bytes = length($s) }
	my @regex_chars = $s =~ m/(.)/g;
	my $regex_chars = @regex_chars;
	my @split_chars = split //, $s;
	my $split_chars = @split_chars;
	ok("$length_chars/$regex_chars/$split_chars/$length_bytes" eq
	   "2/2/2/6");
    }
}


{
    my $w = 0;
    local $SIG{__WARN__} = sub { print "#($_[0])\n"; $w++ };
    my $x = eval q/"\\/ . "\x{100}" . q/"/;;
   
    ok($w == 0 && $x eq "\x{100}");
}


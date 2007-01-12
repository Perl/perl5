#!./perl

# The tests are in a separate file 't/op/re_tests'.
# Each line in that file is a separate test.
# There are five columns, separated by tabs.
#
# Column 1 contains the pattern, optionally enclosed in C<''>.
# Modifiers can be put after the closing C<'>.
#
# Column 2 contains the string to be matched.
#
# Column 3 contains the expected result:
# 	y	expect a match
# 	n	expect no match
# 	c	expect an error
#	B	test exposes a known bug in Perl, should be skipped
#	b	test exposes a known bug in Perl, should be skipped if noamp
#
# Columns 4 and 5 are used only if column 3 contains C<y> or C<c>.
#
# Column 4 contains a string, usually C<$&>.
#
# Column 5 contains the expected result of double-quote
# interpolating that string after the match, or start of error message.
#
# Column 6, if present, contains a reason why the test is skipped.
# This is printed with "skipped", for harness to pick up.
#
# \n in the tests are interpolated, as are variables of the form ${\w+}.
#
# Blanks lines are treated as PASSING tests to keep the line numbers
# linked to the test number.
#
# If you want to add a regular expression test that can't be expressed
# in this format, don't add it here: put it in op/pat.t instead.
#
# Note that columns 2,3 and 5 are all enclosed in double quotes and then
# evalled; so something like a\"\x{100}$1 has length 3+length($1).

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

$iters = shift || 1;		# Poor man performance suite, 10000 is OK.

open(TESTS,'op/re_tests') || open(TESTS,'t/op/re_tests') || open(TESTS,':op:re_tests') ||
	die "Can't open re_tests";

while (<TESTS>) { }
$numtests = $.;
seek(TESTS,0,0);
$. = 0;

$bang = sprintf "\\%03o", ord "!"; # \41 would not be portable.
$ffff  = chr(0xff) x 2;
$nulnul = "\0" x 2;
$OP = $qr ? 'qr' : 'm';

$| = 1;
print "1..$numtests\n# $iters iterations\n";
TEST:
while (<TESTS>) {
    if (!/\S/ || /^\s*#/) {
        print "ok $. # (Blank line or comment)\n";
        if (/\S/) { print $_ };
        next;
    }
    chomp;
    s/\\n/\n/g;
    ($pat, $subject, $result, $repl, $expect, $reason) = split(/\t/,$_,6);
    $input = join(':',$pat,$subject,$result,$repl,$expect);
    infty_subst(\$pat);
    infty_subst(\$expect);
    $pat = "'$pat'" unless $pat =~ /^[:'\/]/;
    $pat =~ s/(\$\{\w+\})/$1/eeg;
    $pat =~ s/\\n/\n/g;
    $subject = eval qq("$subject");
    $expect  = eval qq("$expect");
    $expect = $repl = '-' if $skip_amp and $input =~ /\$[&\`\']/;
    $skip = ($skip_amp ? ($result =~ s/B//i) : ($result =~ s/B//));
    $reason = 'skipping $&' if $reason eq  '' && $skip_amp;
    $result =~ s/B//i unless $skip;

    for $study ('', 'study $subject') {
 	$c = $iters;
        if ($repl eq 'pos') {
            $code= <<EOFCODE;
                $study;
                pos(\$subject)=0;
                \$match = ( \$subject =~ m${pat}g );
                \$got = pos(\$subject);
EOFCODE
        }
        elsif ($qr_embed) {
            $code= <<EOFCODE;
                my \$RE = qr$pat;
                $study;
                \$match = (\$subject =~ /(?:)\$RE(?:)/) while \$c--;
                \$got = "$repl";
EOFCODE
        }
        else {
            $code= <<EOFCODE;
                $study;
                \$match = (\$subject =~ $OP$pat$addg) while \$c--;
                \$got = "$repl";
EOFCODE
        }
        eval $code;
	chomp( $err = $@ );
	if ($result eq 'c') {
	    if ($err !~ m!^\Q$expect!) { print "not ok $. (compile) $input => `$err'\n"; next TEST }
	    last;  # no need to study a syntax error
	}
	elsif ( $skip ) {
	    print "ok $. # skipped", length($reason) ? " $reason" : '', "\n";
	    next TEST;
	}
	elsif ($@) {
	    print "not ok $. $input => error `$err'\n$code\n$@\n"; next TEST;
	}
	elsif ($result eq 'n') {
	    if ($match) { print "not ok $. ($study) $input => false positive\n"; next TEST }
	}
	else {
	    if (!$match || $got ne $expect) {
	        eval { require Data::Dumper };
		if ($@) {
		    print "not ok $. ($study) $input => `$got', match=$match\n$code\n";
		}
		else { # better diagnostics
		    my $s = Data::Dumper->new([$subject],['subject'])->Useqq(1)->Dump;
		    my $g = Data::Dumper->new([$got],['got'])->Useqq(1)->Dump;
		    print "not ok $. ($study) $input => `$got', match=$match\n$s\n$g\n$code\n";
		}
		next TEST;
	    }
	}
    }
    print "ok $.\n";
}

close(TESTS);

sub infty_subst                             # Special-case substitution
{                                           #  of $reg_infty and friends
    my $tp = shift;
    $$tp =~ s/,\$reg_infty_m}/,$reg_infty_m}/o;
    $$tp =~ s/,\$reg_infty_p}/,$reg_infty_p}/o;
    $$tp =~ s/,\$reg_infty}/,$reg_infty}/o;
}

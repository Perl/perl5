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
#
# Columns 4 and 5 are used only if column 3 contains C<y> or C<c>.
#
# Column 4 contains a string, usually C<$&>.
#
# Column 5 contains the expected result of double-quote
# interpolating that string after the match, or start of error message.
#
# Columns 1, 2 and 5 are \n-interpolated.
#
# The variables $reg_infty, $reg_infty_m and $reg_infty_m in columns 1
# and 5 are replaced respectively with the configuration value reg_infty,
# reg_infty-1 and reg_infty+1, or if reg_infty is not defined in the
# configuration, default values.  No other variables are substituted.


$iters = shift || 1;		# Poor man performance suite, 10000 is OK.

chdir 't' if -d 't';
@INC = "../lib";
eval 'use Config';          #  Defaults assumed if this fails
$reg_infty = defined $Config{reg_infty} ? $Config{reg_infty} : 32767;
$reg_infty_m = $reg_infty - 1; $reg_infty_p = $reg_infty + 1;

open(TESTS,'op/re_tests') || die "Can't open re_tests";

while (<TESTS>) { }
$numtests = $.;
seek(TESTS,0,0);
$. = 0;

$| = 1;
print "1..$numtests\n# $iters iterations\n";
TEST:
while (<TESTS>) {
    ($pat, $subject, $result, $repl, $expect) = split(/[\t\n]/,$_);
    $input = join(':',$pat,$subject,$result,$repl,$expect);
    infty_subst(\$pat);
    infty_subst(\$expect);
    $pat = "'$pat'" unless $pat =~ /^[:']/;
    $pat =~ s/\\n/\n/g;
    $subject =~ s/\\n/\n/g;
    $expect =~ s/\\n/\n/g;
    $expect = $repl = '-' if $skip_amp and $input =~ /\$[&\`\']/;
    for $study ("", "study \$subject") {
 	$c = $iters;
 	eval "$study; \$match = (\$subject =~ m$pat) while \$c--; \$got = \"$repl\";";
	chomp( $err = $@ );
	if ($result eq 'c') {
	    if ($err !~ m!^\Q$expect!) { print "not ok $. (compile) $input => `$err'\n"; next TEST }
	    last;  # no need to study a syntax error
	}
	elsif ($@) {
	    print "not ok $. $input => error `$err'\n"; next TEST;
	}
	elsif ($result eq 'n') {
	    if ($match) { print "not ok $. ($study) $input => false positive\n"; next TEST }
	}
	else {
	    if (!$match || $got ne $expect) {
 		print "not ok $. ($study) $input => `$got', match=$match\n";
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

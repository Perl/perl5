#!./perl

open(TESTS,'op/re_tests') || open(TESTS,'t/op/re_tests')
    || die "Can't open re_tests";

while (<TESTS>) { }
$numtests = $.;
seek(TESTS,0,0);
$. = 0;

$| = 1;
print "1..$numtests\n";
TEST:
while (<TESTS>) {
    ($pat, $subject, $result, $repl, $expect) = split(/[\t\n]/,$_);
    $input = join(':',$pat,$subject,$result,$repl,$expect);
    $pat = "'$pat'" unless $pat =~ /^'/;
    for $study ("", "study \$match") {
	eval "$study; \$match = (\$subject =~ m$pat); \$got = \"$repl\";";
	if ($result eq 'c') {
	    if ($@ eq '') { print "not ok $.\n"; next TEST }
	    last;  # no need to study a syntax error
	}
	elsif ($result eq 'n') {
	    if ($match) { print "not ok $. $input => $got\n"; next TEST }
	}
	else {
	    if (!$match || $got ne $expect) {
		print "not ok $. $input => $got\n";
		next TEST;
	    }
	}
    }
    print "ok $.\n";
}

close(TESTS);

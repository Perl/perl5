#!./perl

BEGIN {
    chdir 't' if -d 't';
}

print "1..7\n";

# check "" interpretation

$x = "\n";
# 10 is ASCII/Iso Latin, 13 is Mac OS, 21 is EBCDIC.
if ($x eq chr(10)) { print "ok 1\n";}
elsif ($x eq chr(13)) { print "ok 1 # Mac OS\n"; }
elsif ($x eq chr(21)) { print "ok 1 # EBCDIC\n"; }
else {print "not ok 1\n";}

# check `` processing

$x = `$^X -le "print 'hi there'"`;
if ($x eq "hi there\n") {print "ok 2\n";} else {print "not ok 2\n";}

# check $#array

$x[0] = 'foo';
$x[1] = 'foo';
$tmp = $#x;
print "#3\t:$tmp: == :1:\n";
if ($#x == '1') {print "ok 3\n";} else {print "not ok 3\n";}

# check numeric literal

$x = 1;
if ($x == '1') {print "ok 4\n";} else {print "not ok 4\n";}

$x = '1E2';
if (($x | 1) == 101) {print "ok 5\n";} else {print "not ok 5\n";}

# check <> pseudoliteral

open(try, "/dev/null") || open(try,"nla0:") || (die "Can't open /dev/null.");

if (<try> eq '') {
    print "ok 6\n";
}
else {
    print "not ok 6\n";
    die "/dev/null IS NOT A CHARACTER SPECIAL FILE!!!!\n" unless -c '/dev/null';
}

open(try, "harness") || (die "Can't open harness.");
if (<try> ne '') {print "ok 7\n";} else {print "not ok 7\n";}

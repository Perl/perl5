# tr.t

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

print "1..27\n";

$_ = "abcdefghijklmnopqrstuvwxyz";

tr/a-z/A-Z/;

print "not " unless $_ eq "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
print "ok 1\n";

tr/A-Z/a-z/;

print "not " unless $_ eq "abcdefghijklmnopqrstuvwxyz";
print "ok 2\n";

tr/b-y/B-Y/;

print "not " unless $_ eq "aBCDEFGHIJKLMNOPQRSTUVWXYz";
print "ok 3\n";

# In EBCDIC 'I' is \xc9 and 'J' is \0xd1, 'i' is \x89 and 'j' is \x91.
# Yes, discontinuities.  Regardless, the \xca in the below should stay
# untouched (and not became \x8a).
{
    no utf8;
    $_ = "I\xcaJ";

    tr/I-J/i-j/;

    print "not " unless $_ eq "i\xcaj";
    print "ok 4\n";
}
#

# make sure that tr cancels IOK and NOK
($x = 12) =~ tr/1/3/;
(my $y = 12) =~ tr/1/3/;
($f = 1.5) =~ tr/1/3/;
(my $g = 1.5) =~ tr/1/3/;
print "not " unless $x + $y + $f + $g == 71;
print "ok 5\n";

# make sure tr is harmless if not updating  -  see [ID 20000511.005]
$_ = 'fred';
/([a-z]{2})/;
$1 =~ tr/A-Z//;
s/^(\s*)f/$1F/;
print "not " if $_ ne 'Fred';
print "ok 6\n";

# check tr handles UTF8 correctly
($x = 256.65.258) =~ tr/a/b/;
print "not " if $x ne 256.65.258 or length $x != 3;
print "ok 7\n";
$x =~ tr/A/B/;
if (ord("\t") == 9) { # ASCII
    print "not " if $x ne 256.66.258 or length $x != 3;
}
else {
    print "not " if $x ne 256.65.258 or length $x != 3;
}
print "ok 8\n";

{
if (ord("\t") == 9) { # ASCII
    use utf8;
}

# 9 - changing UTF8 characters in a UTF8 string, same length.
$l = chr(300); $r = chr(400);
$x = 200.300.400;
$x =~ tr/\x{12c}/\x{190}/;
printf "not (%vd) ", $x if $x ne 200.400.400 or length $x != 3;
print "ok 9\n";

# 10 - changing UTF8 characters in UTF8 string, more bytes.
$x = 200.300.400;
$x =~ tr/\x{12c}/\x{be8}/;
printf "not (%vd) ", $x if $x ne 200.3048.400 or length $x != 3;
print "ok 10\n";

# 11 - introducing UTF8 characters to non-UTF8 string.
$x = 100.125.60;
$x =~ tr/\x{64}/\x{190}/;
printf "not (%vd) ", $x if $x ne 400.125.60 or length $x != 3;
print "ok 11\n";

# 12 - removing UTF8 characters from UTF8 string
$x = 400.125.60;
$x =~ tr/\x{190}/\x{64}/;
printf "not (%vd) ", $x if $x ne 100.125.60 or length $x != 3;
print "ok 12\n";

# 13 - counting UTF8 chars in UTF8 string
$x = 400.125.60.400;
$y = $x =~ tr/\x{190}/\x{190}/;
print "not " if $y != 2;
print "ok 13\n";

# 14 - counting non-UTF8 chars in UTF8 string
$x = 60.400.125.60.400;
$y = $x =~ tr/\x{3c}/\x{3c}/;
print "not " if $y != 2;
print "ok 14\n";

# 15 - counting UTF8 chars in non-UTF8 string
$x = 200.125.60;
$y = $x =~ tr/\x{190}/\x{190}/;
print "not " if $y != 0;
print "ok 15\n";
}

# 16: test brokenness with tr/a-z-9//;
$_ = "abcdefghijklmnopqrstuvwxyz";
eval "tr/a-z-9/ /";
print (($@ =~ /^Ambiguous range in transliteration operator/) 
       ? '' : 'not ', "ok 16\n");

# 17-19: Make sure leading and trailing hyphens still work
$_ = "car-rot9";
tr/-a-m/./;
print (($_ eq '..r.rot9') ? '' : 'not ', "ok 17\n");

$_ = "car-rot9";
tr/a-m-/./;
print (($_ eq '..r.rot9') ? '' : 'not ', "ok 18\n");

$_ = "car-rot9";
tr/-a-m-/./;
print (($_ eq '..r.rot9') ? '' : 'not ', "ok 19\n");

$_ = "abcdefghijklmnop";
tr/ae-hn/./;
print (($_ eq '.bcd....ijklm.op') ? '' : 'not ', "ok 20\n");

$_ = "abcdefghijklmnop";
tr/a-cf-kn-p/./;
print (($_ eq '...de......lm...') ? '' : 'not ', "ok 21\n");

$_ = "abcdefghijklmnop";
tr/a-ceg-ikm-o/./;
print (($_ eq '...d.f...j.l...p') ? '' : 'not ', "ok 22\n");

# 23: Test reversed range check
# 20000705 MJD
eval "tr/m-d/ /";
print (($@ =~ /^Invalid \[\] range "m-d" in transliteration operator/) 
       ? '' : 'not ', "ok 23\n");

# 24: test cannot update if read-only
eval '$1 =~ tr/x/y/';
print (($@ =~ /^Modification of a read-only value attempted/) ? '' : 'not ',
       "ok 24\n");

# 25: test can count read-only
'abcdef' =~ /(bcd)/;
print (( eval '$1 =~ tr/abcd//' == 3) ? '' : 'not ', "ok 25\n");

# 26: test lhs OK if not updating
print ((eval '"123" =~ tr/12//' == 2) ? '' : 'not ', "ok 26\n");

# 27: test lhs bad if updating
eval '"123" =~ tr/1/1/';
print (($@ =~ m|^Can't modify constant item in transliteration \(tr///\)|)
       ? '' : 'not ', "ok 27\n");


# tr.t

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

print "1..70\n";

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
# EBCDIC variants of the above tests
($x = 256.193.258) =~ tr/a/b/;
print "not " if $x ne 256.193.258 or length $x != 3;
print "ok 9\n";
$x =~ tr/A/B/;
if (ord("\t") == 9) { # ASCII
    print "not " if $x ne 256.193.258 or length $x != 3;
}
else {
    print "not " if $x ne 256.194.258 or length $x != 3;
}
print "ok 10\n";

{
# 11 - changing UTF8 characters in a UTF8 string, same length.
my $l = chr(300); my $r = chr(400);
$x = 200.300.400;
$x =~ tr/\x{12c}/\x{190}/;
printf "not (%vd) ", $x if $x ne 200.400.400 or length $x != 3;
print "ok 11\n";

# 12 - changing UTF8 characters in UTF8 string, more bytes.
$x = 200.300.400;
$x =~ tr/\x{12c}/\x{be8}/;
printf "not (%vd) ", $x if $x ne 200.3048.400 or length $x != 3;
print "ok 12\n";

# 13 - introducing UTF8 characters to non-UTF8 string.
$x = 100.125.60;
$x =~ tr/\x{64}/\x{190}/;
printf "not (%vd) ", $x if $x ne 400.125.60 or length $x != 3;
print "ok 13\n";

# 14 - removing UTF8 characters from UTF8 string
$x = 400.125.60;
$x =~ tr/\x{190}/\x{64}/;
printf "not (%vd) ", $x if $x ne 100.125.60 or length $x != 3;
print "ok 14\n";

# 15 - counting UTF8 chars in UTF8 string
$x = 400.125.60.400;
$y = $x =~ tr/\x{190}/\x{190}/;
print "not " if $y != 2;
print "ok 15\n";

# 16 - counting non-UTF8 chars in UTF8 string
$x = 60.400.125.60.400;
$y = $x =~ tr/\x{3c}/\x{3c}/;
print "not " if $y != 2;
print "ok 16\n";

# 17 - counting UTF8 chars in non-UTF8 string
$x = 200.125.60;
$y = $x =~ tr/\x{190}/\x{190}/;
print "not " if $y != 0;
print "ok 17\n";
}

# 18: test brokenness with tr/a-z-9//;
$_ = "abcdefghijklmnopqrstuvwxyz";
eval "tr/a-z-9/ /";
print (($@ =~ /^Ambiguous range in transliteration operator/) 
       ? '' : 'not ', "ok 18\n");

# 19-21: Make sure leading and trailing hyphens still work
$_ = "car-rot9";
tr/-a-m/./;
print (($_ eq '..r.rot9') ? '' : 'not ', "ok 19\n");

$_ = "car-rot9";
tr/a-m-/./;
print (($_ eq '..r.rot9') ? '' : 'not ', "ok 20\n");

$_ = "car-rot9";
tr/-a-m-/./;
print (($_ eq '..r.rot9') ? '' : 'not ', "ok 21\n");

$_ = "abcdefghijklmnop";
tr/ae-hn/./;
print (($_ eq '.bcd....ijklm.op') ? '' : 'not ', "ok 22\n");

$_ = "abcdefghijklmnop";
tr/a-cf-kn-p/./;
print (($_ eq '...de......lm...') ? '' : 'not ', "ok 23\n");

$_ = "abcdefghijklmnop";
tr/a-ceg-ikm-o/./;
print (($_ eq '...d.f...j.l...p') ? '' : 'not ', "ok 24\n");

# 25: Test reversed range check
# 20000705 MJD
eval "tr/m-d/ /";
print (($@ =~ /^Invalid \[\] range "m-d" in transliteration operator/) 
       ? '' : 'not ', "ok 25\n");

# 26: test cannot update if read-only
eval '$1 =~ tr/x/y/';
print (($@ =~ /^Modification of a read-only value attempted/) ? '' : 'not ',
       "ok 26\n");

# 27: test can count read-only
'abcdef' =~ /(bcd)/;
print (( eval '$1 =~ tr/abcd//' == 3) ? '' : 'not ', "ok 27\n");

# 28: test lhs OK if not updating
print ((eval '"123" =~ tr/12//' == 2) ? '' : 'not ', "ok 28\n");

# 29: test lhs bad if updating
eval '"123" =~ tr/1/1/';
print (($@ =~ m|^Can't modify constant item in transliteration \(tr///\)|)
       ? '' : 'not ', "ok 29\n");

# v300 (0x12c) is UTF-8-encoded as 196 172 (0xc4 0xac)
# v400 (0x190) is UTF-8-encoded as 198 144 (0xc6 0x90)

# Transliterate a byte to a byte, all four ways.

($a = v300.196.172.300.196.172) =~ tr/\xc4/\xc5/;
print "not " unless $a eq v300.197.172.300.197.172;
print "ok 30\n";

($a = v300.196.172.300.196.172) =~ tr/\xc4/\x{c5}/;
print "not " unless $a eq v300.197.172.300.197.172;
print "ok 31\n";

($a = v300.196.172.300.196.172) =~ tr/\x{c4}/\xc5/;
print "not " unless $a eq v300.197.172.300.197.172;
print "ok 32\n";

($a = v300.196.172.300.196.172) =~ tr/\x{c4}/\x{c5}/;
print "not " unless $a eq v300.197.172.300.197.172;
print "ok 33\n";

# Transliterate a byte to a wide character.

($a = v300.196.172.300.196.172) =~ tr/\xc4/\x{12d}/;
print "not " unless $a eq v300.301.172.300.301.172;
print "ok 34\n";

# Transliterate a wide character to a byte.

($a = v300.196.172.300.196.172) =~ tr/\x{12c}/\xc3/;
print "not " unless $a eq v195.196.172.195.196.172;
print "ok 35\n";

# Transliterate a wide character to a wide character.

($a = v300.196.172.300.196.172) =~ tr/\x{12c}/\x{12d}/;
print "not " unless $a eq v301.196.172.301.196.172;
print "ok 36\n";

# Transliterate both ways.

($a = v300.196.172.300.196.172) =~ tr/\xc4\x{12c}/\x{12d}\xc3/;
print "not " unless $a eq v195.301.172.195.301.172;
print "ok 37\n";

# Transliterate all (four) ways.

($a = v300.196.172.300.196.172.400.198.144) =~
	tr/\xac\xc4\x{12c}\x{190}/\xad\x{12d}\xc5\x{191}/;
print "not " unless $a eq v197.301.173.197.301.173.401.198.144;
print "ok 38\n";

# Transliterate and count.

print "not "
    unless (($a = v300.196.172.300.196.172) =~ tr/\xc4/\xc5/)       == 2;
print "ok 39\n";

print "not "
    unless (($a = v300.196.172.300.196.172) =~ tr/\x{12c}/\x{12d}/) == 2;
print "ok 40\n";

# Transliterate with complement.

($a = v300.196.172.300.196.172) =~ tr/\xc4/\x{12d}/c;
print "not " unless $a eq v301.196.301.301.196.301;
print "ok 41\n";

($a = v300.196.172.300.196.172) =~ tr/\x{12c}/\xc5/c;
print "not " unless $a eq v300.197.197.300.197.197;
print "ok 42\n";

# Transliterate with deletion.

($a = v300.196.172.300.196.172) =~ tr/\xc4//d;
print "not " unless $a eq v300.172.300.172;
print "ok 43\n";

($a = v300.196.172.300.196.172) =~ tr/\x{12c}//d;
print "not " unless $a eq v196.172.196.172;
print "ok 44\n";

# Transliterate with squeeze.

($a = v196.196.172.300.300.196.172) =~ tr/\xc4/\xc5/s;
print "not " unless $a eq v197.172.300.300.197.172;
print "ok 45\n";

($a = v196.172.300.300.196.172.172) =~ tr/\x{12c}/\x{12d}/s;
print "not " unless $a eq v196.172.301.196.172.172;
print "ok 46\n";

# Tricky cases by Simon Cozens.

($a = v196.172.200) =~ tr/\x{12c}/a/;
print "not " unless sprintf("%vd", $a) eq '196.172.200';
print "ok 47\n";

($a = v196.172.200) =~ tr/\x{12c}/\x{12c}/;
print "not " unless sprintf("%vd", $a) eq '196.172.200';
print "ok 48\n";

($a = v196.172.200) =~ tr/\x{12c}//d;
print "not " unless sprintf("%vd", $a) eq '196.172.200';
print "ok 49\n";

# UTF8 range tests from Inaba Hiroto

($a = v300.196.172.302.197.172) =~ tr/\x{12c}-\x{130}/\xc0-\xc4/;
print "not " unless $a eq v192.196.172.194.197.172;
print "ok 50\n";

($a = v300.196.172.302.197.172) =~ tr/\xc4-\xc8/\x{12c}-\x{130}/;
print "not " unless $a eq v300.300.172.302.301.172;
print "ok 51\n";

# UTF8 range tests from Karsten Sperling (patch #9008 required)

($a = "\x{0100}") =~ tr/\x00-\x{100}/X/;
print "not " unless $a eq "X";
print "ok 52\n";

($a = "\x{0100}") =~ tr/\x{0000}-\x{00ff}/X/c;
print "not " unless $a eq "X";
print "ok 53\n";

($a = "\x{0100}") =~ tr/\x{0000}-\x{00ff}\x{0101}/X/c;
print "not " unless $a eq "X";
print "ok 54\n";
 
($a = v256) =~ tr/\x{0000}-\x{00ff}\x{0101}/X/c;
print "not " unless $a eq "X";
print "ok 55\n"; 

# UTF8 range tests from Inaba Hiroto

($a = "\x{200}") =~ tr/\x00-\x{100}/X/c;
print "not " unless $a eq "X";
print "ok 56\n";

($a = "\x{200}") =~ tr/\x00-\x{100}/X/cs;
print "not " unless $a eq "X";
print "ok 57\n";

# Tricky on EBCDIC: while [a-z] [A-Z] must not match the gap characters,
# (i-j, r-s, I-J, R-S), [\x89-\x91] [\xc9-\xd1] has to match them,
# from Karsten Sperling.

$c = ($a = "\x89\x8a\x8b\x8c\x8d\x8f\x90\x91") =~ tr/\x89-\x91/X/;
print "not " unless $c == 8 and $a eq "XXXXXXXX";
print "ok 58\n";
   
$c = ($a = "\xc9\xca\xcb\xcc\xcd\xcf\xd0\xd1") =~ tr/\xc9-\xd1/X/;
print "not " unless $c == 8 and $a eq "XXXXXXXX";
print "ok 59\n";
   
if (ord('i') == 0x89 & ord('J') == 0xd1) {

$c = ($a = "\x89\x8a\x8b\x8c\x8d\x8f\x90\x91") =~ tr/i-j/X/;
print "not " unless $c == 2 and $a eq "X\x8a\x8b\x8c\x8d\x8f\x90X";
print "ok 60\n";
   
$c = ($a = "\xc9\xca\xcb\xcc\xcd\xcf\xd0\xd1") =~ tr/I-J/X/;
print "not " unless $c == 2 and $a eq "X\xca\xcb\xcc\xcd\xcf\xd0X";
print "ok 61\n";

} else {
  for (60..61) { print "ok $_ # Skip: not EBCDIC\n" }
}

($a = "\x{100}") =~ tr/\x00-\xff/X/c;
print "not " unless ord($a) == ord("X");
print "ok 62\n";

($a = "\x{100}") =~ tr/\x00-\xff/X/cs;
print "not " unless ord($a) == ord("X");
print "ok 63\n";

($a = "\x{100}\x{100}") =~ tr/\x{101}-\x{200}//c;
print "not " unless $a eq "\x{100}\x{100}";
print "ok 64\n";

($a = "\x{100}\x{100}") =~ tr/\x{101}-\x{200}//cs;
print "not " unless $a eq "\x{100}";
print "ok 65\n";

$a = "\xfe\xff"; $a =~ tr/\xfe\xff/\x{1ff}\x{1fe}/;
print "not " unless $a eq "\x{1ff}\x{1fe}";
print "ok 66\n";

# From David Dyck
($a = "R0_001") =~ tr/R_//d;
print "not " if hex($a) != 1;
print "ok 67\n";

# From Inaba Hiroto
@a = (1,2); map { y/1/./ for $_ } @a;
print "not " if "@a" ne ". 2";
print "ok 68\n";

@a = (1,2); map { y/1/./ for $_.'' } @a;
print "not " if "@a" ne "1 2";
print "ok 69\n";

# Additional test for Inaba Hiroto patch (robin@kitsite.com)
($a = "\x{100}\x{102}\x{101}") =~ tr/\x00-\377/XYZ/c;
print "not " unless $a eq "XZY";
print "ok 70\n";



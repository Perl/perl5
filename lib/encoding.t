print "1..19\n";

use encoding "latin1"; # ignored (overwritten by the next line)
use encoding "greek";  # iso 8859-7 (no "latin" alias, surprise...)

# "greek" is "ISO 8859-7", and \xDF in ISO 8859-7 is
# \x{3AF} in Unicode (GREEK SMALL LETTER IOTA WITH TONOS),
# instead of \xDF in Unicode (LATIN SMALL LETTER SHARP S)

$a = "\xDF";
$b = "\x{100}";

print "not " unless ord($a) == 0x3af;
print "ok 1\n";

print "not " unless ord($b) == 0x100;
print "ok 2\n";

my $c;

$c = $a . $b;

print "not " unless ord($c) == 0x3af;
print "ok 3\n";

print "not " unless length($c) == 2;
print "ok 4\n";

print "not " unless ord(substr($c, 1, 1)) == 0x100;
print "ok 5\n";

print "not " unless ord(chr(0xdf)) == 0x3af; # spooky
print "ok 6\n";

print "not " unless ord(pack("C", 0xdf)) == 0x3af;
print "ok 7\n";

# we didn't break pack/unpack, I hope

print "not " unless unpack("C", pack("C", 0xdf)) == 0xdf;
print "ok 8\n";

# the first octet of UTF-8 encoded 0x3af 
print "not " unless unpack("C", chr(0xdf)) == 0xce;
print "ok 9\n";

print "not " unless unpack("U", pack("U", 0xdf)) == 0xdf;
print "ok 10\n";

print "not " unless unpack("U", chr(0xdf)) == 0x3af;
print "ok 11\n";

# charnames must still work
use charnames ':full';
print "not " unless ord("\N{LATIN SMALL LETTER SHARP S}") == 0xdf;
print "ok 12\n";

# combine

$c = "\xDF\N{LATIN SMALL LETTER SHARP S}" . chr(0xdf);

print "not " unless ord($c) == 0x3af;
print "ok 13\n";

print "not " unless ord(substr($c, 1, 1)) == 0xdf;
print "ok 14\n";

print "not " unless ord(substr($c, 2, 1)) == 0x3af;
print "ok 15\n";

# regex literals

print "not " unless "\xDF"    =~ /\x{3AF}/;
print "ok 16\n";

print "not " unless "\x{3AF}" =~ /\xDF/;
print "ok 17\n";

print "not " unless "\xDF"    =~ /\xDF/;
print "ok 18\n";

print "not " unless "\x{3AF}" =~ /\x{3AF}/;
print "ok 19\n";


print "1..9\n";

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

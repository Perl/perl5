print "1..3\n";

use encoding "latin1"; # ignored (overwritten by the next line)
use encoding "greek";  # iso 8859-7 (no "latin" alias, surprise...)

$a = "\xDF";
$b = "\x{100}";

my $c = $a . $b;

# "greek" is "ISO 8859-7", and \xDF in ISO 8859-7 is
# \x{3AF} in Unicode (GREEK SMALL LETTER IOTA WITH TONOS),
# instead of \xDF in Unicode (LATIN SMALL LETTER SHARP S)

print "not " unless ord($c) == 0x3af;
print "ok 1\n";

print "not " unless length($c) == 2;
print "ok 2\n";

print "not " unless ord(substr($c, 1, 1)) == 0x100;
print "ok 3\n";



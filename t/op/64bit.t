BEGIN {
	eval { pack "q", 0 };
	if ($@) {
		print "1..0\n# no 64-bit types\n";
		exit(0);
	}
}

# This could use a lot of more tests.
#
# Nota bene: bit operations are not 64-bit clean.  See the beginning
# of pp.c and the explanation next to IBW/UBW.

print "1..30\n";

my $q = 12345678901;
my $r = 23456789012;
my $x;


$x = unpack "q", pack "q", $q;
print "not " unless $x == $q;
print "ok 1\n";


$x = sprintf("%d", 12345678901);
print "not " unless $x eq "$q";
print "ok 2\n";


$x = sprintf("%d", $q);
print "not " unless $x == $q && $x eq $q;
print "ok 3\n";

$x = sprintf("%lld", $q);
print "not " unless $x == $q && $x eq $q;
print "ok 4\n";

$x = sprintf("%Ld", $q);
print "not " unless $x == $q && $x eq $q;
print "ok 5\n";

$x = sprintf("%qd", $q);
print "not " unless $x == $q && $x eq $q;
print "ok 6\n";


$x = sprintf("%x", $q);
print "not " unless hex($x) == 0x2dfdc1c35;
print "ok 7\n";

$x = sprintf("%llx", $q);
print "not " unless hex($x) == 0x2dfdc1c35;
print "ok 8\n";

$x = sprintf("%Lx", $q);
print "not " unless hex($x) == 0x2dfdc1c35;
print "ok 9\n";

$x = sprintf("%qx", $q);
print "not " unless hex($x) == 0x2dfdc1c35;
print "ok 10\n";


$x = sprintf("%o", $q);
print "not " unless oct("0$x") == 0133767016065;
print "ok 11\n";

$x = sprintf("%llo", $q);
print "not " unless oct("0$x") == 0133767016065;
print "ok 12\n";

$x = sprintf("%Lo", $q);
print "not " unless oct("0$x") == 0133767016065;
print "ok 13\n";

$x = sprintf("%qo", $q);
print "not " unless oct("0$x") == 0133767016065;
print "ok 14\n";


$x = sprintf("%b", $q);
print "not " unless oct("0b$x") == 0b1011011111110111000001110000110101;
print "ok 15\n";

$x = sprintf("%llb", $q);
print "not " unless oct("0b$x") == 0b1011011111110111000001110000110101;
print "ok 16\n";

$x = sprintf("%Lb", $q);
print "not " unless oct("0b$x") == 0b1011011111110111000001110000110101;
print "ok 17\n";

$x = sprintf("%qb", $q);
print "not " unless oct("0b$x") == 0b1011011111110111000001110000110101;
print "ok 18\n";


$x = sprintf("%u", 12345678901);
print "not " unless $x eq "$q";
print "ok 19\n";

$x = sprintf("%u", $q);
print "not " unless $x == $q && $x eq $q;
print "ok 20\n";

$x = sprintf("%llu", $q);
print "not " unless $x == $q && $x eq $q;
print "ok 21\n";

$x = sprintf("%Lu", $q);
print "not " unless $x == $q && $x eq $q;
print "ok 22\n";


$x = sprintf("%D", $q);
print "not " unless $x == $q && $x eq $q;
print "ok 23\n";

$x = sprintf("%U", $q);
print "not " unless $x == $q && $x eq $q;
print "ok 24\n";

$x = sprintf("%O", $q);
print "not " unless oct($x) == $q;
print "ok 25\n";


$x = $q + $r;
print "not " unless $x == 35802467913;
print "ok 26\n";

$x = $q - $r;
print "not " unless $x == -11111110111;
print "ok 27\n";

$x = $q * $r;
print "not " unless $x == 289589985190657035812;
print "ok 28\n";

$x /= $r;
print "not " unless $x == $q;
print "ok 29\n";

$x = 98765432109 % 12345678901;
print "not " unless $x == 901;
print "ok 30\n";

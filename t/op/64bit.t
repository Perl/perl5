BEGIN {
	eval { my $q = pack "q", 0 };
	if ($@) {
		print "1..0\n# no 64-bit types\n";
		exit(0);
	}
	chdir 't' if -d 't';
	unshift @INC, '../lib';
}

# This could use a lot of more tests.
#
# Nota bene: bit operations (&, |, ^, ~, <<, >>, vec) are not 64-bit clean.
# See the beginning of pp.c and the explanation next to IBW/UBW.

# so that using > 0xfffffff constants and 32+ bit
# shifts and vector sizes doesn't cause noise
no warning 'overflow';

print "1..36\n";

my $q = 12345678901;
my $r = 23456789012;
my $f = 0xffffffff;
my $x;
my $y;

$x = unpack "q", pack "q", $q;
print "not " unless $x == $q && $x > $f;
print "ok 1\n";


$x = sprintf("%d", 12345678901);
print "not " unless $x eq $q && $x > $f;
print "ok 2\n";


$x = sprintf("%d", $q);
print "not " unless $x == $q && $x eq $q && $x > $f;
print "ok 3\n";

$x = sprintf("%lld", $q);
print "not " unless $x == $q && $x eq $q && $x > $f;
print "ok 4\n";

$x = sprintf("%Ld", $q);
print "not " unless $x == $q && $x eq $q && $x > $f;
print "ok 5\n";

$x = sprintf("%qd", $q);
print "not " unless $x == $q && $x eq $q && $x > $f;
print "ok 6\n";


$x = sprintf("%x", $q);
print "not " unless hex($x) == 0x2dfdc1c35 && hex($x) > $f;
print "ok 7\n";

$x = sprintf("%llx", $q);
print "not " unless hex($x) == 0x2dfdc1c35 && hex($x) > $f;
print "ok 8\n";

$x = sprintf("%Lx", $q);
print "not " unless hex($x) == 0x2dfdc1c35 && hex($x) > $f;
print "ok 9\n";

$x = sprintf("%qx", $q);
print "not " unless hex($x) == 0x2dfdc1c35 && hex($x) > $f;
print "ok 10\n";


$x = sprintf("%o", $q);
print "not " unless oct("0$x") == 0133767016065 && oct($x) > $f;
print "ok 11\n";

$x = sprintf("%llo", $q);
print "not " unless oct("0$x") == 0133767016065 && oct($x) > $f;
print "ok 12\n";

$x = sprintf("%Lo", $q);
print "not " unless oct("0$x") == 0133767016065 && oct($x) > $f;
print "ok 13\n";

$x = sprintf("%qo", $q);
print "not " unless oct("0$x") == 0133767016065 && oct($x) > $f;
print "ok 14\n";


$x = sprintf("%b", $q);
print "not " unless oct("0b$x") == 0b1011011111110111000001110000110101 &&
                    oct("0b$x") > $f;
print "ok 15\n";

$x = sprintf("%llb", $q);
print "not " unless oct("0b$x") == 0b1011011111110111000001110000110101 &&
                    oct("0b$x") > $f;
print "ok 16\n";

$x = sprintf("%Lb", $q);
print "not " unless oct("0b$x") == 0b1011011111110111000001110000110101 &&
                                   oct("0b$x") > $f;
print "ok 17\n";

$x = sprintf("%qb", $q);
print "not " unless oct("0b$x") == 0b1011011111110111000001110000110101 &&
                    oct("0b$x") > $f;
print "ok 18\n";


$x = sprintf("%u", 12345678901);
print "not " unless $x eq $q && $x > $f;
print "ok 19\n";

$x = sprintf("%u", $q);
print "not " unless $x == $q && $x eq $q && $x > $f;
print "ok 20\n";

$x = sprintf("%llu", $q);
print "not " unless $x == $q && $x eq $q && $x > $f;
print "ok 21\n";

$x = sprintf("%Lu", $q);
print "not " unless $x == $q && $x eq $q && $x > $f;
print "ok 22\n";


$x = sprintf("%D", $q);
print "not " unless $x == $q && $x eq $q && $x > $f;
print "ok 23\n";

$x = sprintf("%U", $q);
print "not " unless $x == $q && $x eq $q && $x > $f;
print "ok 24\n";

$x = sprintf("%O", $q);
print "not " unless oct($x) == $q && oct($x) > $f;
print "ok 25\n";


$x = $q + $r;
print "not " unless $x == 35802467913 && $x > $f;
print "ok 26\n";

$x = $q - $r;
print "not " unless $x == -11111110111 && -$x > $f;
print "ok 27\n";

$x = $q * 1234567;
print "not " unless $x == 15241567763770867 && $x > $f;
print "ok 28\n";

$x /= 1234567;
print "not " unless $x == $q && $x > $f;
print "ok 29\n";

$x = 98765432109 % 12345678901;
print "not " unless $x == 901;
print "ok 30\n";

# The following six adapted from op/inc.

$a = 9223372036854775807;
$c = $a++;
print "not " unless $a == 9223372036854775808;
print "ok 31\n";

$a = 9223372036854775807;
$c = ++$a;
print "not " unless $a == 9223372036854775808;
print "ok 32\n";

$a = 9223372036854775807;
$c = $a + 1;
print "not " unless $a == 9223372036854775808;
print "ok 33\n";

$a = -9223372036854775808;
$c = $a--;
print "not " unless $a == -9223372036854775809;
print "ok 34\n";

$a = -9223372036854775808;
$c = --$a;
print "not " unless $a == -9223372036854775809;
print "ok 35\n";

$a = -9223372036854775808;
$c = $a - 1;
print "not " unless $a == -9223372036854775809;
print "ok 36\n";



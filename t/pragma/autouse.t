BEGIN {
	chdir 't' if -d 't';
	@INC = '../lib';
}

print "1..3\n";

use autouse 'Math::Complex' => qw(cplx);
use autouse 'Math::Trig' => qw(Math::Trig::deg2grad($;$));

print "ok 1\n";

print "not " unless sqrt(cplx(-1)) == cplx(0, 1);
print "ok 2\n";

print "not " unless Math::Trig::deg2grad(360, 1) == 400;
print "ok 3\n";


print "1..5\n";

use URI::URL;

# We used to have problems with URLs that used a base that was
# not absolute itself.

$u1 = url("/foo/bar", "http://www.acme.com/");
$u2 = url("../foo/", $u1);
$u3 = url("zoo/foo", $u2);

$a1 = $u1->abs->as_string;
$a2 = $u2->abs->as_string;
$a3 = $u3->abs->as_string;

print "$a1\n$a2\n$a3\n";

print "not " unless $a1 eq "http://www.acme.com/foo/bar";
print "ok 1\n";
print "not " unless $a2 eq "http://www.acme.com/foo/";
print "ok 2\n";
print "not " unless $a3 eq "http://www.acme.com/foo/zoo/foo";
print "ok 3\n";

# We used to have problems with URI::URL as the base class :-(
$u4 = url("foo", "URI::URL");
$a4 = $u4->abs;
print "$a4\n";
print "not " unless $u4 eq "foo" && $a4 eq "uri:/foo";
print "ok 4\n";

# Test new_abs for URI::URL objects
print "not " unless URI::URL->new_abs("foo", "http://foo/bar") eq "http://foo/foo";
print "ok 5\n";

print "1..6\n";

use URI::Escape;

print "not " unless uri_escape("|abcå") eq "%7Cabc%E5";
print "ok 1\n";

print "not " unless uri_escape("abc", "b-d") eq "a%62%63";
print "ok 2\n";

print "not " if defined(uri_escape(undef));
print "ok 3\n";

print "not " unless uri_unescape("%7Cabc%e5") eq "|abcå";
print "ok 4\n";

print "not " unless join(":", uri_unescape("%40A%42", "CDE", "F%47H")) eq
                    '@AB:CDE:FGH';
print "ok 5\n";



use URI::Escape qw(%escapes);

print "not" unless $escapes{"%"} eq "%25";
print "ok 6\n";

print "1..48\n";

use URI;

$foo = URI->new("Foo:opaque#frag");

print "not " unless ref($foo) eq "URI::_foreign";
print "ok 1\n";

print "not " unless $foo->as_string eq "Foo:opaque#frag";
print "ok 2\n";

print "not " unless "$foo" eq "Foo:opaque#frag";
print "ok 3\n";

# Try accessors
print "not " unless $foo->_scheme eq "Foo" && $foo->scheme eq "foo";
print "ok 4\n";

print "not " unless $foo->opaque eq "opaque";
print "ok 5\n";

print "not " unless $foo->fragment eq "frag";
print "ok 6\n";

print "not " unless $foo->canonical eq "foo:opaque#frag";
print "ok 7\n";

# Try modificators
$old = $foo->scheme("bar");

print "not " unless $old eq "foo" && $foo eq "bar:opaque#frag";
print "ok 8\n";

$old = $foo->scheme("");
print "not " unless $old eq "bar" && $foo eq "opaque#frag";
print "ok 9\n";

$old = $foo->scheme("foo");
$old = $foo->scheme(undef);

print "not " unless $old eq "foo" && $foo eq "opaque#frag";
print "ok 10\n";

$foo->scheme("foo");


$old = $foo->opaque("xxx");
print "not " unless $old eq "opaque" && $foo eq "foo:xxx#frag";
print "ok 11\n";

$old = $foo->opaque("");
print "not " unless $old eq "xxx" && $foo eq "foo:#frag";
print "ok 12\n";

$old = $foo->opaque(" #?/");
$old = $foo->opaque(undef);
print "not " unless $old eq "%20%23?/" && $foo eq "foo:#frag";
print "ok 13\n";

$foo->opaque("opaque");


$old = $foo->fragment("x");
print "not " unless $old eq "frag" && $foo eq "foo:opaque#x";
print "ok 14\n";

$old = $foo->fragment("");
print "not " unless $old eq "x" && $foo eq "foo:opaque#";
print "ok 15\n";

$old = $foo->fragment(undef);
print "not " unless $old eq "" && $foo eq "foo:opaque";
print "ok 16\n";


# Compare
print "not " unless $foo->eq("Foo:opaque") &&
                    $foo->eq(URI->new("FOO:opaque")) &&
	            $foo->eq("foo:opaque");
print "ok 17\n";

print "not " if $foo->eq("Bar:opaque") ||
                $foo->eq("foo:opaque#");
print "ok 18\n";


# Try hierarchal unknown URLs

$foo = URI->new("foo://host:80/path?query#frag");

print "not " unless "$foo" eq "foo://host:80/path?query#frag";
print "ok 19\n";

# Accessors
print "not " unless $foo->scheme eq "foo";
print "ok 20\n";

print "not " unless $foo->authority eq "host:80";
print "ok 21\n";

print "not " unless $foo->path eq "/path";
print "ok 22\n";

print "not " unless $foo->query eq "query";
print "ok 23\n";

print "not " unless $foo->fragment eq "frag";
print "ok 24\n";

# Modificators
$old = $foo->authority("xxx");
print "not " unless $old eq "host:80" && $foo eq "foo://xxx/path?query#frag";
print "ok 25\n";

$old = $foo->authority("");
print "not " unless $old eq "xxx" && $foo eq "foo:///path?query#frag";
print "ok 26\n";

$old = $foo->authority(undef);
print "not " unless $old eq "" && $foo eq "foo:/path?query#frag";
print "ok 27\n";

$old = $foo->authority("/? #;@&");
print "not " unless !defined($old) && $foo eq "foo://%2F%3F%20%23;@&/path?query#frag";
print "ok 28\n";

$old = $foo->authority("host:80");
print "not " unless $old eq "%2F%3F%20%23;@&" && $foo eq "foo://host:80/path?query#frag";
print "ok 29\n";


$old = $foo->path("/foo");
print "not " unless $old eq "/path" && $foo eq "foo://host:80/foo?query#frag";
print "ok 30\n";

$old = $foo->path("bar");
print "not " unless $old eq "/foo" && $foo eq "foo://host:80/bar?query#frag";
print "ok 31\n";

$old = $foo->path("");
print "not " unless $old eq "/bar" && $foo eq "foo://host:80?query#frag";
print "ok 32\n";

$old = $foo->path(undef);
print "not " unless $old eq "" && $foo eq "foo://host:80?query#frag";
print "ok 33\n";

$old = $foo->path("@;/?#");
print "not " unless $old eq "" && $foo eq "foo://host:80/@;/%3F%23?query#frag";
print "ok 34\n";

$old = $foo->path("path");
print "not " unless $old eq "/@;/%3F%23" && $foo eq "foo://host:80/path?query#frag";
print "ok 35\n";


$old = $foo->query("foo");
print "not " unless $old eq "query" && $foo eq "foo://host:80/path?foo#frag";
print "ok 36\n";

$old = $foo->query("");
print "not " unless $old eq "foo" && $foo eq "foo://host:80/path?#frag";
print "ok 37\n";

$old = $foo->query(undef);
print "not " unless $old eq "" && $foo eq "foo://host:80/path#frag";
print "ok 38\n";

$old = $foo->query("/?&=# ");
print "not " unless !defined($old) && $foo eq "foo://host:80/path?/?&=%23%20#frag";
print "ok 39\n";

$old = $foo->query("query");
print "not " unless $old eq "/?&=%23%20" && $foo eq "foo://host:80/path?query#frag";
print "ok 40\n";

# Some buildup trics
$foo = URI->new("");
$foo->path("path");
$foo->authority("auth");

print "not " unless $foo eq "//auth/path";
print "ok 41\n";

$foo = URI->new("", "http:");
$foo->query("query");
$foo->authority("auth");
print "not " unless $foo eq "//auth?query";
print "ok 42\n";

$foo->path("path");
print "not " unless $foo eq "//auth/path?query";
print "ok 43\n";

$foo = URI->new("");
$old = $foo->path("foo");
print "not " unless $old eq "" && $foo eq "foo";
print "ok 44\n";

$old = $foo->path("bar");
print "not " unless $old eq "foo" && $foo eq "bar";
print "ok 45\n";

$old = $foo->opaque("foo");
print "not " unless $old eq "bar" && $foo eq "foo";
print "ok 46\n";

$old = $foo->path("");
print "not " unless $old eq "foo" && $foo eq "";
print "ok 47\n";

$old = $foo->query("q");
print "not " unless !defined($old) && $foo eq "?q";
print "ok 48\n";


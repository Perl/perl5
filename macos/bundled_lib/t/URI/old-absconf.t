print "1..6\n";

use URI::URL qw(url);

# Test configuration via some global variables.

$URI::URL::ABS_REMOTE_LEADING_DOTS = 1;
$URI::URL::ABS_ALLOW_RELATIVE_SCHEME = 1;

$u1 = url("../../../../abc", "http://web/a/b");

print "not " unless $u1->abs->as_string eq "http://web/abc";
print "ok 1\n";

{
    local $URI::URL::ABS_REMOTE_LEADING_DOTS;
    print "not " unless $u1->abs->as_string eq "http://web/../../../abc";
    print "ok 2\n";
}


$u1 = url("http:../../../../abc", "http://web/a/b");
print "not " unless $u1->abs->as_string eq "http://web/abc";
print "ok 3\n";

{
   local $URI::URL::ABS_ALLOW_RELATIVE_SCHEME;
   print "not " unless $u1->abs->as_string eq "http:../../../../abc";
   print "ok 4\n";
   print "not " unless $u1->abs(undef,1)->as_string eq "http://web/abc";
   print "ok 5\n";
}

print "not " unless $u1->abs(undef,0)->as_string eq "http:../../../../abc";
print "ok 6\n";

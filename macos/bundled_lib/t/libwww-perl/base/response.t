
# Test extra HTTP::Response methods.  Basic operation is tested in the
# message.t test suite.


print "1..7\n";


use HTTP::Date;
use HTTP::Request;
use HTTP::Response;

my $time = time;

$req = HTTP::Request->new(GET => 'http://www.sn.no');
$req->date($time - 30);

$r = new HTTP::Response 200, "OK";
$r->client_date($time - 20);
$r->date($time - 25);
$r->last_modified($time - 5000000);
$r->request($req);

print $r->as_string;

$current_age = $r->current_age;

if ($current_age < 35  || $current_age > 40) {
    print "not ";
}
print "ok 1\n";

$freshness_lifetime = $r->freshness_lifetime;
if ($freshness_lifetime < 12 * 3600) {
    print "not ";
}
print "ok 2\n";

$is_fresh = $r->is_fresh;

print "not " unless $is_fresh;
print "ok 3\n";

print "current_age        = $current_age\n";
print "freshness_lifetime = $freshness_lifetime\n";
print "response is ";
print "not " unless $is_fresh;
print "fresh\n";


print "it will be fresh is ";
print $freshness_lifetime - $current_age;
print " more seconds\n";

# OK, now we add an Expires header
$r->expires($time);
print $r->as_string;

$freshness_lifetime = $r->freshness_lifetime;
print "freshness_lifetime = $freshness_lifetime\n";
print "not " unless $freshness_lifetime == 25;
print "ok 4\n";
$r->remove_header('expires');

# Now we try the 'Age' header and the Cache-Contol:

$r->header('Age', 300);
$r->push_header('Cache-Control', 'junk');
$r->push_header(Cache_Control => 'max-age = 10');

print $r->as_string;

$current_age = $r->current_age;
$freshness_lifetime = $r->freshness_lifetime;

print "current_age        = $current_age\n";
print "freshness_lifetime = $freshness_lifetime\n";

print "not " if $current_age < 300;
print "ok 5\n";

print "not " if $freshness_lifetime != 10;
print "ok 6\n";

print "not " unless $r->fresh_until;  # should return something
print "ok 7\n";

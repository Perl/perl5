print "1..35\n";

#use LWP::Debug '+';
use HTTP::Cookies;
use HTTP::Request;
use HTTP::Response;

#-------------------------------------------------------------------
# First we check that it works for the original example at
# http://www.netscape.com/newsref/std/cookie_spec.html

# Client requests a document, and receives in the response:
# 
#       Set-Cookie: CUSTOMER=WILE_E_COYOTE; path=/; expires=Wednesday, 09-Nov-99 23:12:40 GMT
# 
# When client requests a URL in path "/" on this server, it sends:
# 
#       Cookie: CUSTOMER=WILE_E_COYOTE
# 
# Client requests a document, and receives in the response:
# 
#       Set-Cookie: PART_NUMBER=ROCKET_LAUNCHER_0001; path=/
# 
# When client requests a URL in path "/" on this server, it sends:
# 
#       Cookie: CUSTOMER=WILE_E_COYOTE; PART_NUMBER=ROCKET_LAUNCHER_0001
# 
# Client receives:
# 
#       Set-Cookie: SHIPPING=FEDEX; path=/fo
# 
# When client requests a URL in path "/" on this server, it sends:
# 
#       Cookie: CUSTOMER=WILE_E_COYOTE; PART_NUMBER=ROCKET_LAUNCHER_0001
# 
# When client requests a URL in path "/foo" on this server, it sends:
# 
#       Cookie: CUSTOMER=WILE_E_COYOTE; PART_NUMBER=ROCKET_LAUNCHER_0001; SHIPPING=FEDEX
# 
# The last Cookie is buggy, because both specifications says that the
# most specific cookie must be sent first.  SHIPPING=FEDEX is the
# most specific and should thus be first.

my $year_plus_one = (localtime)[5] + 1900 + 1;

$c = HTTP::Cookies->new;

$req = HTTP::Request->new(GET => "http://www.acme.com/");

$res = HTTP::Response->new(200, "OK");
$res->request($req);
$res->header("Set-Cookie" => "CUSTOMER=WILE_E_COYOTE; path=/; expires=Wednesday, 09-Nov-$year_plus_one 23:12:40 GMT");
#print $res->as_string;
$c->extract_cookies($res);

$req = HTTP::Request->new(GET => "http://www.acme.com/");
$c->add_cookie_header($req);

print "not " unless $req->header("Cookie") eq "CUSTOMER=WILE_E_COYOTE" &&
                    $req->header("Cookie2") eq "\$Version=\"1\"";
print "ok 1\n";

$res->request($req);
$res->header("Set-Cookie" => "PART_NUMBER=ROCKET_LAUNCHER_0001; path=/");
$c->extract_cookies($res);

$req = HTTP::Request->new(GET => "http://www.acme.com/foo/bar");
$c->add_cookie_header($req);

$h = $req->header("Cookie");
print "not " unless $h =~ /PART_NUMBER=ROCKET_LAUNCHER_0001/ &&
                    $h =~ /CUSTOMER=WILE_E_COYOTE/;
print "ok 2\n";

$res->request($req);
$res->header("Set-Cookie", "SHIPPING=FEDEX; path=/foo");
$c->extract_cookies($res);

$req = HTTP::Request->new(GET => "http://www.acme.com/");
$c->add_cookie_header($req);

$h = $req->header("Cookie");
print "not " unless $h =~ /PART_NUMBER=ROCKET_LAUNCHER_0001/ &&
	            $h =~ /CUSTOMER=WILE_E_COYOTE/ &&
	            $h !~ /SHIPPING=FEDEX/;
print "ok 3\n";


$req = HTTP::Request->new(GET => "http://www.acme.com/foo/");
$c->add_cookie_header($req);

$h = $req->header("Cookie");
print "not " unless $h =~ /PART_NUMBER=ROCKET_LAUNCHER_0001/ &&
	            $h =~ /CUSTOMER=WILE_E_COYOTE/ &&
		    $h =~ /^SHIPPING=FEDEX;/;
print "ok 4\n";

print $c->as_string;


# Second Example transaction sequence:
# 
# Assume all mappings from above have been cleared.
# 
# Client receives:
# 
#       Set-Cookie: PART_NUMBER=ROCKET_LAUNCHER_0001; path=/
# 
# When client requests a URL in path "/" on this server, it sends:
# 
#       Cookie: PART_NUMBER=ROCKET_LAUNCHER_0001
# 
# Client receives:
# 
#       Set-Cookie: PART_NUMBER=RIDING_ROCKET_0023; path=/ammo
# 
# When client requests a URL in path "/ammo" on this server, it sends:
# 
#       Cookie: PART_NUMBER=RIDING_ROCKET_0023; PART_NUMBER=ROCKET_LAUNCHER_0001
# 
#       NOTE: There are two name/value pairs named "PART_NUMBER" due to
#       the inheritance of the "/" mapping in addition to the "/ammo" mapping. 

$c = HTTP::Cookies->new;  # clear it

$req = HTTP::Request->new(GET => "http://www.acme.com/");
$res = HTTP::Response->new(200, "OK");
$res->request($req);
$res->header("Set-Cookie", "PART_NUMBER=ROCKET_LAUNCHER_0001; path=/");

$c->extract_cookies($res);

$req = HTTP::Request->new(GET => "http://www.acme.com/");
$c->add_cookie_header($req);

print "not " unless $req->header("Cookie") eq "PART_NUMBER=ROCKET_LAUNCHER_0001";
print "ok 5\n";

$res->request($req);
$res->header("Set-Cookie", "PART_NUMBER=RIDING_ROCKET_0023; path=/ammo");
$c->extract_cookies($res);

$req = HTTP::Request->new(GET => "http://www.acme.com/ammo");
$c->add_cookie_header($req);

print "not " unless $req->header("Cookie") =~
       /^PART_NUMBER=RIDING_ROCKET_0023;\s*PART_NUMBER=ROCKET_LAUNCHER_0001/;
print "ok 6\n";

print $c->as_string;
undef($c);


#-------------------------------------------------------------------
# When there are no "Set-Cookie" header, then even responses
# without any request URLs connected should be allowed.

$c = HTTP::Cookies->new;
$c->extract_cookies(HTTP::Response->new("200", "OK"));
print "not " if count_cookies($c) != 0;
print "ok 7\n";


#-------------------------------------------------------------------
# Then we test with the examples from draft-ietf-http-state-man-mec-03.txt
#
# 5.  EXAMPLES

$c = HTTP::Cookies->new;

# 
# 5.1  Example 1
# 
# Most detail of request and response headers has been omitted.  Assume
# the user agent has no stored cookies.
# 
#   1.  User Agent -> Server
# 
#       POST /acme/login HTTP/1.1
#       [form data]
# 
#       User identifies self via a form.
# 
#   2.  Server -> User Agent
# 
#       HTTP/1.1 200 OK
#       Set-Cookie2: Customer="WILE_E_COYOTE"; Version="1"; Path="/acme"
# 
#       Cookie reflects user's identity.

$cookie = interact($c, 'http://www.acme.com/acme/login',
                       'Customer="WILE_E_COYOTE"; Version="1"; Path="/acme"');
print "not " if $cookie;
print "ok 8\n";

# 
#   3.  User Agent -> Server
# 
#       POST /acme/pickitem HTTP/1.1
#       Cookie: $Version="1"; Customer="WILE_E_COYOTE"; $Path="/acme"
#       [form data]
# 
#       User selects an item for ``shopping basket.''
# 
#   4.  Server -> User Agent
# 
#       HTTP/1.1 200 OK
#       Set-Cookie2: Part_Number="Rocket_Launcher_0001"; Version="1";
#               Path="/acme"
# 
#       Shopping basket contains an item.

$cookie = interact($c, 'http://www.acme.com/acme/pickitem',
		       'Part_Number="Rocket_Launcher_0001"; Version="1"; Path="/acme"');
print "not " unless $cookie =~ m(^\$Version="?1"?; Customer="?WILE_E_COYOTE"?; \$Path="/acme"$);
print "ok 9\n";

# 
#   5.  User Agent -> Server
# 
#       POST /acme/shipping HTTP/1.1
#       Cookie: $Version="1";
#               Customer="WILE_E_COYOTE"; $Path="/acme";
#               Part_Number="Rocket_Launcher_0001"; $Path="/acme"
#       [form data]
# 
#       User selects shipping method from form.
# 
#   6.  Server -> User Agent
# 
#       HTTP/1.1 200 OK
#       Set-Cookie2: Shipping="FedEx"; Version="1"; Path="/acme"
# 
#       New cookie reflects shipping method.

$cookie = interact($c, "http://www.acme.com/acme/shipping",
		   'Shipping="FedEx"; Version="1"; Path="/acme"');

print "not " unless $cookie =~ /^\$Version="?1"?;/ &&
     $cookie =~ /Part_Number="?Rocket_Launcher_0001"?;\s*\$Path="\/acme"/ &&
     $cookie =~ /Customer="?WILE_E_COYOTE"?;\s*\$Path="\/acme"/;
print "ok 10\n";

# 
#   7.  User Agent -> Server
# 
#       POST /acme/process HTTP/1.1
#       Cookie: $Version="1";
#               Customer="WILE_E_COYOTE"; $Path="/acme";
#               Part_Number="Rocket_Launcher_0001"; $Path="/acme";
#               Shipping="FedEx"; $Path="/acme"
#       [form data]
# 
#       User chooses to process order.
# 
#   8.  Server -> User Agent
# 
#       HTTP/1.1 200 OK
# 
#       Transaction is complete.

$cookie = interact($c, "http://www.acme.com/acme/process");
print "FINAL COOKIE: $cookie\n";
print "not " unless $cookie =~ /Shipping="?FedEx"?;\s*\$Path="\/acme"/ &&
                    $cookie =~ /WILE_E_COYOTE/;
print "ok 11\n";

# 
# The user agent makes a series of requests on the origin server, after
# each of which it receives a new cookie.  All the cookies have the same
# Path attribute and (default) domain.  Because the request URLs all have
# /acme as a prefix, and that matches the Path attribute, each request
# contains all the cookies received so far.

print $c->as_string;


# 5.2  Example 2
# 
# This example illustrates the effect of the Path attribute.  All detail
# of request and response headers has been omitted.  Assume the user agent
# has no stored cookies.

$c = HTTP::Cookies->new;

# Imagine the user agent has received, in response to earlier requests,
# the response headers
# 
# Set-Cookie2: Part_Number="Rocket_Launcher_0001"; Version="1";
#         Path="/acme"
# 
# and
# 
# Set-Cookie2: Part_Number="Riding_Rocket_0023"; Version="1";
#         Path="/acme/ammo"

interact($c, "http://www.acme.com/acme/ammo/specific",
             'Part_Number="Rocket_Launcher_0001"; Version="1"; Path="/acme"',
             'Part_Number="Riding_Rocket_0023"; Version="1"; Path="/acme/ammo"');

# A subsequent request by the user agent to the (same) server for URLs of
# the form /acme/ammo/...  would include the following request header:
# 
# Cookie: $Version="1";
#         Part_Number="Riding_Rocket_0023"; $Path="/acme/ammo";
#         Part_Number="Rocket_Launcher_0001"; $Path="/acme"
# 
# Note that the NAME=VALUE pair for the cookie with the more specific Path
# attribute, /acme/ammo, comes before the one with the less specific Path
# attribute, /acme.  Further note that the same cookie name appears more
# than once.

$cookie = interact($c, "http://www.acme.com/acme/ammo/...");
print "not " unless $cookie =~ /Riding_Rocket_0023.*Rocket_Launcher_0001/;
print "ok 12\n";

# A subsequent request by the user agent to the (same) server for a URL of
# the form /acme/parts/ would include the following request header:
# 
# Cookie: $Version="1"; Part_Number="Rocket_Launcher_0001"; $Path="/acme"
# 
# Here, the second cookie's Path attribute /acme/ammo is not a prefix of
# the request URL, /acme/parts/, so the cookie does not get forwarded to
# the server.

$cookie = interact($c, "http://www.acme.com/acme/parts/");
print "not " unless $cookie =~ /Rocket_Launcher_0001/ &&
		    $cookie !~ /Riding_Rocket_0023/;
print "ok 13\n";

print $c->as_string;

#-----------------------------------------------------------------------

# Test rejection of Set-Cookie2 responses based on domain, path or port

$c = HTTP::Cookies->new;

# illegal domain (no embedded dots)
$cookie = interact($c, "http://www.acme.com", 'foo=bar; domain=".com"');
print "not " if count_cookies($c) > 0;
print "ok 14\n";

# legal domain
$cookie = interact($c, "http://www.acme.com", 'foo=bar; domain="acme.com"');
print "not " if count_cookies($c) != 1;
print "ok 15\n";

# illegal domain (host prefix "www.a" contains a dot)
$cookie = interact($c, "http://www.a.acme.com", 'foo=bar; domain="acme.com"');
print "not " if count_cookies($c) != 1;
print "ok 16\n";

# legal domain
$cookie = interact($c, "http://www.a.acme.com", 'foo=bar; domain=".a.acme.com"');
print "not " if count_cookies($c) != 2;
print "ok 17\n";

# can't use a IP-address as domain
$cookie = interact($c, "http://125.125.125.125", 'foo=bar; domain="125.125.125"');
print "not " if count_cookies($c) != 2;
print "ok 18\n";

# illegal path (must be prefix of request path)
$cookie = interact($c, "http://www.sol.no", 'foo=bar; domain=".sol.no"; path="/foo"');
print "not " if count_cookies($c) != 2;
print "ok 19\n";

# legal path
$cookie = interact($c, "http://www.sol.no/foo/bar", 'foo=bar; domain=".sol.no"; path="/foo"');
print "not " if count_cookies($c) != 3;
print "ok 20\n";

# illegal port (request-port not in list)
$cookie = interact($c, "http://www.sol.no", 'foo=bar; domain=".sol.no"; port="90,100"');
print "not " if count_cookies($c) != 3;
print "ok 21\n";

# legal port
$cookie = interact($c, "http://www.sol.no", 'foo=bar; domain=".sol.no"; port="90,100, 80,8080"; max-age=100; Comment = "Just kidding! (\"|\\\\) "');
print "not " if count_cookies($c) != 4;
print "ok 22\n";

# port attribute without any value (current port)
$cookie = interact($c, "http://www.sol.no", 'foo9=bar; domain=".sol.no"; port; max-age=100;');
print "not " if count_cookies($c) != 5;
print "ok 23\n";

# encoded path
$cookie = interact($c, "http://www.sol.no/foo/", 'foo8=bar; path="/%66oo"');
print "not " if count_cookies($c) != 6;
print "ok 24\n";

my $file = "lwp-cookies-$$.txt";
$c->save($file);
$old = $c->as_string;
undef($c);

$c = HTTP::Cookies->new;
$c->load($file);
unlink($file) || warn "Can't unlink $file: $!";

print "not " unless $old eq $c->as_string;
print "ok 25\n";

undef($c);

#
# Try some URL encodings of the PATHs
#
$c = HTTP::Cookies->new;
interact($c, "http://www.acme.com/foo%2f%25/%40%40%0Anew%E5/%E5", 'foo  =   bar; version    =   1');
print $c->as_string;

$cookie = interact($c, "http://www.acme.com/foo%2f%25/@@%0anewå/æøå", "bar=baz; path=\"/foo/\"; version=1");
print "not " unless $cookie =~ /foo=bar/ && $cookie =~ /^\$version=\"?1\"?/i;
print "ok 26\n";

$cookie = interact($c, "http://www.acme.com/foo/%25/@@%0anewå/æøå");
print "not " if $cookie;
print "ok 27\n";

undef($c);

#
# Try to use the Netscape cookie file format for saving
#
$file = "cookies-$$.txt";
$c = HTTP::Cookies::Netscape->new(file => $file);
interact($c, "http://www.acme.com/", "foo1=bar; max-age=100");
interact($c, "http://www.acme.com/", "foo2=bar; port=\"80\"; max-age=100; Discard; Version=1");
interact($c, "http://www.acme.com/", "foo3=bar; secure; Version=1");
$c->save;
undef($c);

$c = HTTP::Cookies::Netscape->new(file => $file);
print "not " unless count_cookies($c) == 1;     # 2 of them discarded on save
print "ok 28\n";

print "not " unless $c->as_string =~ /foo1=bar/;
print "ok 29\n";
undef($c);
unlink($file);


#
# Some additional Netscape cookies test
#
$c = HTTP::Cookies->new;
$req = HTTP::Request->new(POST => "http://foo.bar.acme.com/foo");

# Netscape allows a host part that contains dots
$res = HTTP::Response->new(200, "OK");
$res->header(set_cookie => 'Customer=WILE_E_COYOTE; domain=.acme.com');
$res->request($req);
$c->extract_cookies($res);

# and that the domain is the same as the host without adding a leading
# dot to the domain.  Should not quote even if strange chars are used
# in the cookie value.
$res = HTTP::Response->new(200, "OK");
$res->header(set_cookie => 'PART_NUMBER=3,4; domain=foo.bar.acme.com');
$res->request($req);
$c->extract_cookies($res);

print $c->as_string;

require URI;
$req = HTTP::Request->new(POST => URI->new("http://foo.bar.acme.com/foo"));
$c->add_cookie_header($req);
#print $req->as_string;
print "not " unless $req->header("Cookie") =~ /PART_NUMBER=3,4/ &&
	            $req->header("Cookie") =~ /Customer=WILE_E_COYOTE/;
print "ok 30\n";



# Test handling of local intranet hostnames without a dot
$c->clear;
print "---\n";
#require LWP::Debug;
#LWP::Debug::level('+');

interact($c, "http://example/", "foo1=bar; PORT; Discard;");
$_=interact($c, "http://example/", 'foo2=bar; domain=".local"');
print "not " unless /foo1=bar/;
print "ok 31\n";

$_=interact($c, "http://example/", 'foo3=bar');
$_=interact($c, "http://example/");
print "Cookie: $_\n";
print "not " unless /foo2=bar/ && count_cookies($c) == 3;
print "ok 32\n";
print $c->as_string;

# Test for empty path
# Broken web-server ORION/1.3.38 returns to the client response like
#
#	Set-Cookie: JSESSIONID=ABCDERANDOM123; Path=
#
# e.g. with Path set to nothing.
# In this case routine extract_cookies() must set cookie to / (root)
print "---\n";
print "Test for empty path...\n";
$c = HTTP::Cookies->new;  # clear it

$req = HTTP::Request->new(GET => "http://www.ants.com/");

$res = HTTP::Response->new(200, "OK");
$res->request($req);
$res->header("Set-Cookie" => "JSESSIONID=ABCDERANDOM123; Path=");
print $res->as_string;
$c->extract_cookies($res);
#print $c->as_string;

$req = HTTP::Request->new(GET => "http://www.ants.com/");
$c->add_cookie_header($req);
#print $req->as_string;

print "not " unless $req->header("Cookie") eq "JSESSIONID=ABCDERANDOM123" &&
                    $req->header("Cookie2") eq "\$Version=\"1\"";
print "ok 33\n";


# missing path in the request URI
$req = HTTP::Request->new(GET => URI->new("http://www.ants.com:8080"));
$c->add_cookie_header($req);
#print $req->as_string;

print "not " unless $req->header("Cookie") eq "JSESSIONID=ABCDERANDOM123" &&
                    $req->header("Cookie2") eq "\$Version=\"1\"";
print "ok 34\n";

# test mixing of Set-Cookie and Set-Cookie2 headers.
# Example from http://www.trip.com/trs/trip/flighttracker/flight_tracker_home.xsl
# which gives up these headers:
#
# HTTP/1.1 200 OK
# Connection: close
# Date: Fri, 20 Jul 2001 19:54:58 GMT
# Server: Apache/1.3.19 (Unix) ApacheJServ/1.1.2
# Content-Type: text/html
# Content-Type: text/html; charset=iso-8859-1
# Link: </trip/stylesheet.css>; rel="stylesheet"; type="text/css"
# Servlet-Engine: Tomcat Web Server/3.2.1 (JSP 1.1; Servlet 2.2; Java 1.3.0; SunOS 5.8 sparc; java.vendor=Sun Microsystems Inc.)
# Set-Cookie: trip.appServer=1111-0000-x-024;Domain=.trip.com;Path=/
# Set-Cookie: JSESSIONID=fkumjm7nt1.JS24;Path=/trs
# Set-Cookie2: JSESSIONID=fkumjm7nt1.JS24;Version=1;Discard;Path="/trs"
# Title: TRIP.com Travel - FlightTRACKER
# X-Meta-Description: Trip.com privacy policy
# X-Meta-Keywords: privacy policy

$req = HTTP::Request->new('GET', 'http://www.trip.com/trs/trip/flighttracker/flight_tracker_home.xsl');
$res = HTTP::Response->new(200, "OK");
$res->request($req);
$res->push_header("Set-Cookie"  => qq(trip.appServer=1111-0000-x-024;Domain=.trip.com;Path=/));
$res->push_header("Set-Cookie"  => qq(JSESSIONID=fkumjm7nt1.JS24;Path=/trs));
$res->push_header("Set-Cookie2" => qq(JSESSIONID=fkumjm7nt1.JS24;Version=1;Discard;Path="/trs"));
#print $res->as_string;

$c = HTTP::Cookies->new;  # clear it
$c->extract_cookies($res);
print $c->as_string;
print "not " unless $c->as_string eq <<'EOT'; print "ok 35\n";
Set-Cookie3: trip.appServer="1111-0000-x-024"; path="/"; domain=".trip.com"; path_spec; discard; version=0
Set-Cookie3: JSESSIONID="fkumjm7nt1.JS24"; path="/trs"; domain="www.trip.com"; path_spec; discard; version=1
EOT

#-------------------------------------------------------------------

sub interact
{
    my $c = shift;
    my $url = shift;
    my $req = HTTP::Request->new(POST => $url);
    $c->add_cookie_header($req);
    my $cookie = $req->header("Cookie");
    my $res = HTTP::Response->new(200, "OK");
    $res->request($req);
    for (@_) { $res->push_header("Set-Cookie2" => $_) }
    $c->extract_cookies($res);
    return $cookie;
}

sub count_cookies
{
    my $c = shift;
    my $no = 0;
    $c->scan(sub { $no++ });
    $no;
}

print "1..4\n";

use HTTP::Response;
use HTTP::Headers::Auth;

$res = HTTP::Response->new(401);
$res->push_header(WWW_Authenticate => qq(Foo realm="WallyWorld", foo=bar, Bar realm="WallyWorld2"));
$res->push_header(WWW_Authenticate => qq(Basic Realm="WallyWorld", foo=bar, bar=baz));

print $res->as_string;

%auth = $res->www_authenticate;

print "not " unless keys(%auth) == 3;
print "ok 1\n";

print "not " unless $auth{basic}{realm} eq "WallyWorld" &&
                    $auth{bar}{realm} eq "WallyWorld2";
print "ok 2\n";

$a = $res->www_authenticate;
print "not " unless $a eq 'Foo realm="WallyWorld", foo=bar, Bar realm="WallyWorld2", Basic Realm="WallyWorld", foo=bar, bar=baz';
print "ok 3\n";

$res->www_authenticate("Basic realm=foo1");
print $res->as_string;

$res->www_authenticate(Basic => {realm => foo2});
print $res->as_string;

$res->www_authenticate(Basic => [realm => foo3, foo=>33],
                       Digest => {nonce=>"bar", foo=>'foo'});
print $res->as_string;

$_ = $res->as_string;

print "not " unless /WWW-Authenticate: Basic realm="foo3", foo=33/ &&
                    (/WWW-Authenticate: Digest nonce=bar, foo=foo/ ||
                     /WWW-Authenticate: Digest foo=foo, nonce=bar/);
print "ok 4\n";


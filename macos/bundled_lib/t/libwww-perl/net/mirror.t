#
# Test mirroring a file
#

require "net/config.pl";
require LWP::Protocol::http;
require LWP::UserAgent;
require HTTP::Status;

print "1..2\n";

my $ua = new LWP::UserAgent;    # create a useragent to test

my $url = "http://$net::httpserver/";
my $copy = "lwp-test-$$"; # downloaded copy

my $response = $ua->mirror($url, $copy);

if ($response->code == &HTTP::Status::RC_OK) {
    print "ok 1\n";
} else {
    print "not ok 1\n";
}

# OK, so now do it again, should get Not-Modified
$response = $ua->mirror($url, $copy);
if ($response->code == &HTTP::Status::RC_NOT_MODIFIED) {
    print "ok 2\n";
} else {
    print "nok ok 2\n";
}
unlink($copy);

$net::httpserver = $net::httpserver;  # avoid -w warning

#!/usr/local/bin/perl -w
#
# Check GET via HTTP.
#

print "1..2\n";

require "net/config.pl";
require LWP::Protocol::http;
require LWP::UserAgent;

my $ua = new LWP::UserAgent;    # create a useragent to test

$netloc = $net::httpserver;
$script = $net::cgidir . "/test";

$url = new URI::URL("http://$netloc$script?query");

my $request = new HTTP::Request('GET', $url);

print "GET $url\n\n";

my $response = $ua->request($request, undef, undef);

my $str = $response->as_string;

print "$str\n";

if ($response->is_success and $str =~ /^REQUEST_METHOD=GET$/m) {
    print "ok 1\n";
} else {
    print "not ok 1\n";
}

if ($str =~ /^QUERY_STRING=query$/m) {
    print "ok 2\n";
} else {
    print "not ok 2\n";
}

# avoid -w warning
$dummy = $net::httpserver;
$dummy = $net::cgidir;

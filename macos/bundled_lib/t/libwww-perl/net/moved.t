#!/usr/local/bin/perl -w
#

print "1..1\n";

require "net/config.pl";
require LWP::Debug;
require LWP::UserAgent;

$url = "http://$net::httpserver$net::cgidir/moved";

#LWP::Debug::level('+trace');

my $ua = new LWP::UserAgent;    # create a useragent to test
$ua->timeout(30);               # timeout in seconds

my $request = new HTTP::Request('GET', $url);

print $request->as_string;

my $response = $ua->request($request, undef, undef);

print $response->as_string, "\n";

if ($response->is_success) {
    print "ok 1\n";
} else {
    print "not ok 1\n";
}


# avoid -w warning
$dummy = $net::httpserver;
$dummy = $net::cgidir;

#!/usr/local/bin/perl -w
#
# Test retrieving a file with a 'ftp://' URL,
# via a HTTP proxy.
#

print "1..1\n";

require "net/config.pl";
unless (defined $net::ftp_proxy) {
    print "not ok 1\n";
    exit 0;
}

require LWP::Debug;
require LWP::UserAgent;

#LWP::Debug::level('+');

my $ua = new LWP::UserAgent;    # create a useragent to test

$ua->proxy('ftp', $net::ftp_proxy);

my $url = new URI::URL('ftp://ftp.uninett.no/');

my $request = new HTTP::Request('GET', $url);

my $response = $ua->request($request, undef, undef);

my $str = $response->as_string;

if ($response->is_success) {
    print "ok 1\n";
} else {
    print "not ok 1\n";
}

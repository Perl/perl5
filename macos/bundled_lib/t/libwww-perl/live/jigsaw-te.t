#!perl -w

my $zlib_ok;
for (("", "live/", "t/live/")) {
    if (-f $_ . "ZLIB_OK") {
	$zlib_ok++;
	last;
    }
}

unless ($zlib_ok) {
    print "1..0\n";
    print "Apparently no working ZLIB installed\n";
    exit;
}


print "1..4\n";

use strict;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new(keep_alive => 1);


my $content;
my $testno = 1;

for my $te (undef, "", "deflate", "gzip", "trailers, deflate;q=0.4, identity;q=0.1") {
    my $req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/TE/foo.txt");
    if (defined $te) {
	$req->header(TE => $te);
	$req->header(Connection => "TE");
    }
    print $req->as_string;

    my $res = $ua->request($req);
    if (defined $content) {
	print "not " unless $content eq $res->content;
	print "ok $testno\n\n";
	$testno++;
    }
    else {
	$content = $res->content;
    }
    $res->content("");
    print $res->as_string;
}

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



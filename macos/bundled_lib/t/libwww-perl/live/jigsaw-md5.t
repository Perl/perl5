print "1..2\n";

use strict;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new(keep_alive => 1);

my $req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/h-content-md5.html");
$req->header("TE", "deflate");

my $res = $ua->request($req);

use Digest::MD5 qw(md5_base64);
print "not " unless $res->header("Content-MD5") eq md5_base64($res->content) . "==";
print "ok 1\n";

print $res->as_string;

my $etag = $res->header("etag");
$req->header("If-None-Match" => $etag);

$res = $ua->request($req);
print $res->as_string;

print "not " unless $res->code eq "304" && $res->header("Client-Response-Num") == 2;
print "ok 2\n";

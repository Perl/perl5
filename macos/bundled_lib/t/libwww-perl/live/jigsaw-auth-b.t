print "1..3\n";

use strict;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new(keep_alive => 1);

my $req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/Basic/");

my $res = $ua->request($req);

#print $res->as_string;

print "not " unless $res->code eq "401";
print "ok 1\n";

$req->authorization_basic('guest', 'guest');
$res = $ua->request($req);

#print $res->as_string;
print "not " unless $res->code eq "200" && $res->content =~ /Your browser made it!/;
print "ok 2\n";

{
   package MyUA;
   use vars qw(@ISA);
   @ISA = qw(LWP::UserAgent);

   my @try = (['foo', 'bar'], ['', ''], ['guest', ''], ['guest', 'guest']);

   sub get_basic_credentials {
	my($self,$realm, $uri, $proxy) = @_;
	print "$realm/$uri/$proxy\n";
	my $p = shift @try;
	print join("/", @$p), "\n";
	return @$p;
   }

}

$ua = MyUA->new(keep_alive => 1);

$req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/Basic/");
$res = $ua->request($req);

#print $res->as_string;

print "not " unless $res->content =~ /Your browser made it!/ &&
	            $res->header("Client-Response-Num") == 5;
print "ok 3\n";


print "1..3\n";

use strict;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new(keep_alive => 1,
			     cookie_jar => {},
			    );

# Google is confused if we end up sendit it the "Connection: TE"
# header and will close the connection.  This avoids it.
push(@LWP::Protocol::http::EXTRA_SOCK_OPTS, SendTE => 0);
my @dummy = @LWP::Protocol::http::EXTRA_SOCK_OPTS;  # avoid 'only once' warning

my $req = HTTP::Request->new(GET => "http://www.google.com");
my $res = $ua->request($req);

$res = $ua->request($req);
#print $res->as_string;

print $res->content_type, "\n";
print scalar($res->header("Content-type")), "\n";

use HTML::Form;

my @f = HTML::Form->parse($res->content, $res->base->as_string);
print "not " if @f != 1;
print "ok 1\n";

#use Data::Dump qw(dump); print dump(@f), "\n";

my $f = $f[0];

$f->value("q", "LWP");

$req = $f->click("btnI");
print $req->as_string;

$res = $ua->simple_request($req);

print $res->as_string;

print "not " unless $res->code == 302 && $res->header("Location") eq "http://www.linpro.no/lwp/";
print "ok 2\n";

# check that keep alive worked
print "not " unless $res->header("Client-Request-Num") == 3;
print "ok 3\n";

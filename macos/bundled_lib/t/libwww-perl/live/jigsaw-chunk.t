print "1..5\n";

use strict;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new(keep_alive => 1);

my $req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/ChunkedScript");
my $res = $ua->request($req);

print "not " unless $res->is_success && $res->content_type eq "text/plain";
print "ok 1\n";

print "not " unless $res->header("Client-Transfer-Encoding") eq "chunked";
print "ok 2\n";

for (${$res->content_ref}) {
    s/\015?\012/\n/g;
    /Below this line, is 1000 repeated lines of 0-9/ || die;
    s/^.*?-----+\n//s;

    my @lines = split(/^/);
    print "not " if @lines != 1000;
    print "ok 3\n";

    # check that all lines are the same
    my $first = shift(@lines);
    my $no_they_are_not;
    for (@lines) {
	$no_they_are_not++ if $_ ne $first;
    }
    print "not " if $no_they_are_not;
    print "ok 4\n";

    print "not " unless $first =~ /^\d+$/;
    print "ok 5\n";
}

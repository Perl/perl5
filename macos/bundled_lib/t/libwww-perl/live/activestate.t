print "1..2\n";

use strict;
use Net::HTTP;


my $s = Net::HTTP->new(Host => "ftp.activestate.com",
		       KeepAlive => 1,
		       Timeout => 15,
		       PeerHTTPVersion => "1.1",
		       MaxLineLength => 512) || die "$@";

for (1..2) {
    $s->write_request(TRACE => "/libwww-perl",
		      'User-Agent' => 'Mozilla/5.0',
		      'Accept-Language' => 'no,en',
		      Accept => '*/*');

    my($code, $mess, %h) = $s->read_response_headers;
    print "$code $mess\n";
    my $err;
    $err++ unless $code eq "200";
    $err++ unless $h{'Content-Type'} eq "message/http";

    my $buf;
    while (1) {
        my $tmp;
	my $n = $s->read_entity_body($tmp, 20);
	last unless $n;
	$buf .= $tmp;
    }
    $buf =~ s/\r//g;

    $err++ unless $buf eq "TRACE /libwww-perl HTTP/1.1
Accept: */*
Accept-Language: no,en
Host: ftp.activestate.com:80
User-Agent: Mozilla/5.0

";

    print "not " if $err;
    print "ok $_\n";
}


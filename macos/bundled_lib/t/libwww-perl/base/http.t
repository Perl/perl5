#!./perl -w

print "1..12\n";

use strict;
#use Data::Dump ();

my $CRLF = "\015\012";
my $LF   = "\012";

{
    package HTTP;
    use vars qw(@ISA);
    require Net::HTTP::Methods;
    @ISA=qw(Net::HTTP::Methods);

    my %servers = (
      a => { "/" => "HTTP/1.0 200 OK${CRLF}Content-Type: text/plain${CRLF}Content-Length: 6${CRLF}${CRLF}Hello\n",
	     "/bad1" => "HTTP/1.0 200 OK${LF}Server: foo${LF}HTTP/1.0 200 OK${LF}Content-type: text/foo${LF}${LF}abc\n",
	     "/09" => "Hello${CRLF}World!${CRLF}",
	     "/chunked" => "HTTP/1.1 200 OK${CRLF}Transfer-Encoding: chunked${CRLF}${CRLF}0002; foo=3; bar${CRLF}He${CRLF}1${CRLF}l${CRLF}2${CRLF}lo${CRLF}0000${CRLF}Content-MD5: xxx${CRLF}${CRLF}",
	     "/head" => "HTTP/1.1 200 OK${CRLF}Content-Length: 16${CRLF}Content-Type: text/plain${CRLF}${CRLF}",
	   },
    );

    sub http_connect {
	my($self, $cnf) = @_;
	my $server = $servers{$cnf->{PeerAddr}} || return undef;
	${*$self}{server} = $server;
	${*$self}{read_chunk_size} = $cnf->{ReadChunkSize};
	return $self;
    }

    sub peerport {
	return 80;
    }

    sub print {
	my $self = shift;
	#Data::Dump::dump("PRINT", @_);
	my $in = shift;
	my($method, $uri) = split(' ', $in);

	my $out;
	if ($method eq "TRACE") {
	    my $len = length($in);
	    $out = "HTTP/1.0 200 OK${CRLF}Content-Length: $len${CRLF}" .
                   "Content-Type: message/http${CRLF}${CRLF}" .
                   $in;
	}
        else {
	    $out = ${*$self}{server}{$uri};
	    $out = "HTTP/1.0 404 Not found${CRLF}${CRLF}" unless defined $out;
	}

	${*$self}{out} .= $out;
	return 1;
    }

    sub sysread {
	my $self = shift;
	#Data::Dump::dump("SYSREAD", @_);
	my $length = $_[1];
	my $offset = $_[2] || 0;

	if (my $read_chunk_size = ${*$self}{read_chunk_size}) {
	    $length = $read_chunk_size if $read_chunk_size < $length;
	}

	my $data = substr(${*$self}{out}, 0, $length, "");
	return 0 unless length($data);

	$_[0] = "" unless defined $_[0];
	substr($_[0], $offset) = $data;
	return length($data);
    }

    # ----------------

    sub request {
	my($self, $method, $uri, $headers, $opt) = @_;
	$headers ||= [];
	$opt ||= {};

	my($code, $message, @h);
	my $buf = "";
	eval {
	    $self->write_request($method, $uri, @$headers) || die "Can't write request";
	    ($code, $message, @h) = $self->read_response_headers(%$opt);

	    my $tmp;
	    my $n;
	    while ($n = $self->read_entity_body($tmp, 32)) {
		#Data::Dump::dump($tmp, $n);
		$buf .= $tmp;
	    }

	    push(@h, $self->get_trailers);

	};

	my %res = ( code => $code,
		    message => $message,
		    headers => \@h,
		    content => $buf,
		  );

	if ($@) {
	    $res{error} = $@;
	}

	return \%res;
    }
}

# Start testing
my $h;
my $res;

$h = HTTP->new(Host => "a", KeepAlive => 1) || die;
$res = $h->request(GET => "/");

#Data::Dump::dump($res);

print "not " unless $res->{code} eq "200" && $res->{content} eq "Hello\n";
print "ok 1\n";

$res = $h->request(GET => "/404");
print "not " unless $res->{code} eq "404";
print "ok 2\n";

$res = $h->request(TRACE => "/foo");
print "not " unless $res->{code} eq "200" &&
                    $res->{content} eq "TRACE /foo HTTP/1.1${CRLF}Keep-Alive: 300${CRLF}Connection: Keep-Alive${CRLF}Host: a:80${CRLF}${CRLF}";
print "ok 3\n";

# try to turn off keep alive
$h->keep_alive(0);
$res = $h->request(TRACE => "/foo");
print "not " unless $res->{code} eq "200" &&
                    $res->{content} eq "TRACE /foo HTTP/1.1${CRLF}Connection: close${CRLF}Host: a:80${CRLF}${CRLF}";
print "ok 4\n";

# try a bad one
$res = $h->request(GET => "/bad1", [], {laxed => 1});
print "not " unless $res->{code} eq "200" && $res->{message} eq "OK" &&
                    "@{$res->{headers}}" eq "Server foo Content-type text/foo" &&
                    $res->{content} eq "abc\n";
print "ok 5\n";

$res = $h->request(GET => "/bad1");
print "not " unless $res->{error} =~ /Bad header/ && !$res->{code};
print "ok 6\n";
$h = undef;  # it is in a bad state now

$h = HTTP->new(Host => "a") || die;  # reconnect
$res = $h->request(GET => "/09", [], {laxed => 1});
print "not " unless $res->{code} eq "200" && $res->{message} eq "Assumed OK" &&
                    $res->{content} eq "Hello${CRLF}World!${CRLF}" &&
                    $h->peer_http_version eq "0.9";
print "ok 7\n";

$res = $h->request(GET => "/09");
print "not " unless $res->{error} =~ /^Bad response status line: 'Hello'/;
print "ok 8\n";
$h = undef;  # it's in a bad state again

$h = HTTP->new(Host => "a", KeepAlive => 1, ReadChunkSize => 1) || die;  # reconnect
$res = $h->request(GET => "/chunked");
print "not " unless $res->{code} eq "200" && $res->{content} eq "Hello" &&
                    "@{$res->{headers}}" eq "Transfer-Encoding chunked Content-MD5 xxx";
print "ok 9\n";

# once more
$res = $h->request(GET => "/chunked");
print "not " unless $res->{code} eq "200" && $res->{content} eq "Hello" &&
                    "@{$res->{headers}}" eq "Transfer-Encoding chunked Content-MD5 xxx";
print "ok 10\n";

# test head
$res = $h->request(HEAD => "/head");
print "not " unless $res->{code} eq "200" && $res->{content} eq "" &&
                    "@{$res->{headers}}"  eq "Content-Length 16 Content-Type text/plain";
print "ok 11\n";

$res = $h->request(GET => "/");
print "not " unless $res->{code} eq "200" && $res->{content} eq "Hello\n";
print "ok 12\n";
#use Data::Dump; Data::Dump::dump($res);


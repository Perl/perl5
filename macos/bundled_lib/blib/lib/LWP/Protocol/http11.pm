# $Id: http11.pm,v 1.3 2001/04/10 07:12:37 gisle Exp $
#
# You can tell LWP to use this module for 'http' requests by running
# code like this before you make requests:
#
#    require LWP::Protocol::http11;
#    LWP::Protocol::implementor('http', 'LWP::Protocol::http11');

package LWP::Protocol::http11;

use strict;

require LWP::Debug;
require HTTP::Response;
require HTTP::Status;
require Net::HTTP;

use vars qw(@ISA @EXTRA_SOCK_OPTS);

require LWP::Protocol;
@ISA = qw(LWP::Protocol);

{
    package LWP::Protocol::MyHTTP;
    use vars qw(@ISA);
    @ISA = qw(Net::HTTP);

    sub xread {
	my $self = shift;
	if (my $timeout = ${*$self}{io_socket_timeout}) {
	    my $iosel = (${*$self}{myhttp_io_sel} ||=
			 do {
			     require IO::Select;
			     IO::Select->new($self);
			 });
	    die "read timeout" unless $iosel->can_read($timeout);
	}
	sysread($self, $_[0], $_[1], $_[2] || 0);
    }
}

sub _new_socket
{
    my($self, $host, $port, $timeout) = @_;

    local($^W) = 0;  # IO::Socket::INET can be noisy
    my $sock = LWP::Protocol::MyHTTP->new(PeerAddr => $host,
					  PeerPort => $port,
					  Proto    => 'tcp',
					  Timeout  => $timeout,
					  $self->_extra_sock_opts($host, $port),
					 );
    unless ($sock) {
	# IO::Socket::INET leaves additional error messages in $@
	$@ =~ s/^.*?: //;
	die "Can't connect to $host:$port ($@)";
    }
    $sock;
}

sub _extra_sock_opts  # to be overridden by subclass
{
    return @EXTRA_SOCK_OPTS;
}

sub _check_sock
{
    #my($self, $req, $sock) = @_;
}

sub _get_sock_info
{
    my($self, $res, $sock) = @_;
    if (defined(my $peerhost = $sock->peerhost)) {
	$res->header("Client-Peer" => "$peerhost:" . $sock->peerport);
    }
}

sub _fixup_header
{
    my($self, $h, $url, $proxy) = @_;

    # Extract 'Host' header
    my $hhost = $url->authority;
    $hhost =~ s/^([^\@]*)\@//;  # get rid of potential "user:pass@"
    $h->header('Host' => $hhost) unless defined $h->header('Host');

    # add authorization header if we need them.  HTTP URLs do
    # not really support specification of user and password, but
    # we allow it.
    if (defined($1) && not $h->header('Authorization')) {
	require URI::Escape;
	$h->authorization_basic(map URI::Escape::uri_unescape($_),
				split(":", $1, 2));
    }

    if ($proxy) {
	# Check the proxy URI's userinfo() for proxy credentials
	# export http_proxy="http://proxyuser:proxypass@proxyhost:port"
	my $p_auth = $proxy->userinfo();
	if(defined $p_auth) {
	    require URI::Escape;
	    $h->proxy_authorization_basic(map URI::Escape::uri_unescape($_),
					  split(":", $p_auth, 2))
	}
    }
}


sub request
{
    my($self, $request, $proxy, $arg, $size, $timeout) = @_;
    LWP::Debug::trace('()');

    $size ||= 4096;

    # check method
    my $method = $request->method;
    unless ($method =~ /^[A-Za-z0-9_!\#\$%&\'*+\-.^\`|~]+$/) {  # HTTP token
	return new HTTP::Response &HTTP::Status::RC_BAD_REQUEST,
				  'Library does not allow method ' .
				  "$method for 'http:' URLs";
    }

    my $url = $request->url;
    my($host, $port, $fullpath);

    # Check if we're proxy'ing
    if (defined $proxy) {
	# $proxy is an URL to an HTTP server which will proxy this request
	$host = $proxy->host;
	$port = $proxy->port;
	$fullpath = $method eq "CONNECT" ?
                       ($url->host . ":" . $url->port) :
                       $url->as_string;
    }
    else {
	$host = $url->host;
	$port = $url->port;
	$fullpath = $url->path_query;
	$fullpath = "/" unless length $fullpath;
    }

    # connect to remote site
    my $socket = $self->_new_socket($host, $port, $timeout);
    $self->_check_sock($request, $socket);

    my @h;
    $request->scan(sub { push(@h, @_); });

    # XXX need to support sub-ref content and watch out for write timeouts
    $socket->write_request($method, $fullpath, @h, $request->content);

    my($version, $code, $mess, @h) = $socket->read_response_headers;

    my $response = HTTP::Response->new($code, $mess);
    $response->protocol("HTTP/$version");
    while (@h) {
	my($k, $v) = splice(@h, 0, 2);
	$response->push_header($k, $v);
    }

    $response->request($request);
    $self->_get_sock_info($response, $socket);

    if ($method eq "CONNECT") {
	$response->{client_socket} = $socket;  # so it can be picked up
	return $response;
    }

    $response->remove_header('Transfer-Encoding');

    $response = $self->collect($arg, $response, sub {
	my $buf;
	my $n = $socket->read_entity_body($buf, $size);
	die $! unless defined $n;
        return \$buf;
    } );

    @h = $socket->get_trailers;
    while (@h) {
	my($k, $v) = splice(@h, 0, 2);
	$response->push_header($k, $v);
    }

    $response;
}

1;

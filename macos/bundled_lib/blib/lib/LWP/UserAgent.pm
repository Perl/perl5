# $Id: UserAgent.pm,v 2.1 2001/12/11 21:11:29 gisle Exp $

package LWP::UserAgent;
use strict;

=head1 NAME

LWP::UserAgent - A WWW UserAgent class

=head1 SYNOPSIS

 require LWP::UserAgent;
 my $ua = LWP::UserAgent->new(env_proxy => 1,
                              keep_alive => 1,
                              timeout => 30,
                             );

 $response = $ua->get('http://search.cpan.org/');

 # or:

 $request = HTTP::Request->new('GET', 'http://search.cpan.org/');
  # and then one of these:
 $response = $ua->request($request); # or
 $response = $ua->request($request, '/tmp/sss'); # or
 $response = $ua->request($request, \&callback, 4096);

 sub callback { my($data, $response, $protocol) = @_; .... }

=head1 DESCRIPTION

The C<LWP::UserAgent> is a class implementing a World-Wide Web
user agent in Perl. It brings together the HTTP::Request,
HTTP::Response and the LWP::Protocol classes that form the rest of the
core of libwww-perl library. For simple uses this class can be used
directly to dispatch WWW requests, alternatively it can be subclassed
for application-specific behaviour.

In normal use the application creates a C<LWP::UserAgent> object, and then
configures it with values for timeouts, proxies, name, etc. It then
creates an instance of C<HTTP::Request> for the request that
needs to be performed. This request is then passed to one of the UserAgent's
request() methods, which dispatches it using the relevant protocol,
and returns a C<HTTP::Response> object.

There are convenience methods for sending the most common request
types; get(), head() and post().

The basic approach of the library is to use HTTP style communication
for all protocol schemes, i.e. you even receive an C<HTTP::Response>
object for gopher or ftp requests.  In order to achieve even more
similarity to HTTP style communications, gopher menus and file
directories are converted to HTML documents.

The send_request(), simple_request() and request() methods can process
the content of the response in one of three ways: in core, into a
file, or into repeated calls to a subroutine.  You choose which one by
the kind of value passed as the second argument.

The in core variant simply stores the content in a scalar 'content'
attribute of the response object and is suitable for small HTML
replies that might need further parsing.  This variant is used if the
second argument is missing (or is undef).

The filename variant requires a scalar containing a filename as the
second argument to the request method and is suitable for large WWW
objects which need to be written directly to the file without
requiring large amounts of memory. In this case the response object
returned from the request method will have an empty content attribute.
If the request fails, then the content might not be empty, and the
file will be untouched.

The subroutine variant requires a reference to callback routine as the
second argument to the request method and it can also take an optional
chuck size as the third argument.  This variant can be used to
construct "pipe-lined" processing, where processing of received
chuncks can begin before the complete data has arrived.  The callback
function is called with 3 arguments: the data received this time, a
reference to the response object and a reference to the protocol
object.  The response object returned from the request method will
have empty content.  If the request fails, then the the callback
routine is not called, and the response->content might not be empty.

The request can be aborted by calling die() in the callback
routine.  The die message will be available as the "X-Died" special
response header field.

The library also allows you to use a subroutine reference as
content in the request object.  This subroutine should return the
content (possibly in pieces) when called.  It should return an empty
string when there is no more content.

=head1 METHODS

The following methods are available:

=over 4

=cut


use vars qw(@ISA $VERSION);

require LWP::MemberMixin;
@ISA = qw(LWP::MemberMixin);
$VERSION = sprintf("%d.%03d", q$Revision: 2.1 $ =~ /(\d+)\.(\d+)/);

use HTTP::Request ();
use HTTP::Response ();
use HTTP::Date ();

use LWP ();
use LWP::Debug ();
use LWP::Protocol ();

use Carp ();

if ($ENV{PERL_LWP_USE_HTTP_10}) {
    require LWP::Protocol::http10;
    LWP::Protocol::implementor('http', 'LWP::Protocol::http10');
    eval {
        require LWP::Protocol::https10;
        LWP::Protocol::implementor('https', 'LWP::Protocol::https10');
    };
}

=item $ua = LWP::UserAgent->new( %options );

This class method constructs a new C<LWP::UserAgent> object and
returns a reference to it.

Key/value pair arguments may be provided to set up the initial state
of the user agent.  The following options correspond to attribute
methods described below:

   KEY                     DEFAULT
   -----------             --------------------
   agent                   "libwww-perl/#.##"
   from                    undef
   timeout                 180
   use_eval                1
   parse_head              1
   max_size                undef
   cookie_jar              undef
   conn_cache              undef
   protocols_allowed       undef
   protocols_forbidden     undef
   requests_redirectable   ['GET', 'HEAD']

The followings option are also accepted: If the C<env_proxy> option is
passed in an has a TRUE value, then proxy settings are read from
environment variables.  If the C<keep_alive> option is passed in, then
a C<LWP::ConnCache> is set up (see conn_cache() method below).  The
keep_alive value is a number and is passed on as the total_capacity
for the connection cache.  The C<keep_alive> option also has the
effect of loading and enabling the new experimental HTTP/1.1 protocol
module.

=cut

sub new
{
    my($class, %cnf) = @_;
    LWP::Debug::trace('()');

    my $agent = delete $cnf{agent};
    $agent = $class->_agent unless defined $agent;

    my $from  = delete $cnf{from};
    my $timeout = delete $cnf{timeout};
    $timeout = 3*60 unless defined $timeout;
    my $use_eval = delete $cnf{use_eval};
    $use_eval = 1 unless defined $use_eval;
    my $parse_head = delete $cnf{parse_head};
    $parse_head = 1 unless defined $parse_head;
    my $max_size = delete $cnf{max_size};
    my $env_proxy = delete $cnf{env_proxy};

    my $cookie_jar = delete $cnf{cookie_jar};
    my $conn_cache = delete $cnf{conn_cache};
    my $keep_alive = delete $cnf{keep_alive};
    
    Carp::croak("Can't mix conn_cache and keep_alive")
	  if $conn_cache && $keep_alive;


    my $protocols_allowed   = delete $cnf{protocols_allowed};
    my $protocols_forbidden = delete $cnf{protocols_forbidden};
    
    my $requests_redirectable = delete $cnf{requests_redirectable};
    $requests_redirectable = ['GET', 'HEAD']
      unless defined $requests_redirectable;

    # Actually ""s are just as good as 0's, but for concision we'll just say:
    Carp::croak("protocols_allowed has to be an arrayref or 0, not \"$protocols_allowed\"!")
      if $protocols_allowed and ref($protocols_allowed) ne 'ARRAY';
    Carp::croak("protocols_forbidden has to be an arrayref or 0, not \"$protocols_forbidden\"!")
      if $protocols_forbidden and ref($protocols_forbidden) ne 'ARRAY';
    Carp::croak("requests_redirectable has to be an arrayref or 0, not \"$requests_redirectable\"!")
      if $requests_redirectable and ref($requests_redirectable) ne 'ARRAY';


    if (%cnf && $^W) {
	Carp::carp("Unrecognized LWP::UserAgent options: @{[sort keys %cnf]}");
    }

    my $self = bless {
		      from        => $from,
		      timeout     => $timeout,
		      use_eval    => $use_eval,
		      parse_head  => $parse_head,
		      max_size    => $max_size,
		      proxy       => undef,
		      no_proxy    => [],
                      protocols_allowed => $protocols_allowed,
                      protocols_forbidden => $protocols_forbidden,
                      requests_redirectable => $requests_redirectable,
		     }, $class;

    $self->agent($agent) if $agent;
    $self->cookie_jar($cookie_jar) if $cookie_jar;
    $self->env_proxy if $env_proxy;

    $self->protocols_allowed(  $protocols_allowed  ) if $protocols_allowed;
    $self->protocols_forbidden($protocols_forbidden) if $protocols_forbidden;

    if ($keep_alive) {
	$conn_cache ||= { total_capacity => $keep_alive };
    }
    $self->conn_cache($conn_cache) if $conn_cache;

    return $self;
}


# private method.  check sanity of given $request
sub _request_sanity_check {
    my($self, $request) = @_;
    # some sanity checking
    if (defined $request) {
	if (ref $request) {
	    Carp::croak("You need a request object, not a " . ref($request) . " object")
	      if ref($request) eq 'ARRAY' or ref($request) eq 'HASH' or
		 !$request->can('method') or !$request->can('uri');
	}
	else {
	    Carp::croak("You need a request object, not '$request'");
	}
    }
    else {
        Carp::croak("No request object passed in");
    }
}


=item $ua->send_request($request, $arg [, $size])

This method dispatches a single WWW request on behalf of a user, and
returns the response received.  The request is sent off unmodified,
without passing it through C<prepare_request()>.

The C<$request> should be a reference to a C<HTTP::Request> object
with values defined for at least the method() and uri() attributes.

If C<$arg> is a scalar it is taken as a filename where the content of
the response is stored.

If C<$arg> is a reference to a subroutine, then this routine is called
as chunks of the content is received.  An optional C<$size> argument
is taken as a hint for an appropriate chunk size.

If C<$arg> is omitted, then the content is stored in the response
object itself.

=cut

sub send_request
{
    my($self, $request, $arg, $size) = @_;
    $self->_request_sanity_check($request);

    my($method, $url) = ($request->method, $request->uri);

    local($SIG{__DIE__});  # protect agains user defined die handlers

    # Check that we have a METHOD and a URL first
    return _new_response($request, &HTTP::Status::RC_BAD_REQUEST, "Method missing")
	unless $method;
    return _new_response($request, &HTTP::Status::RC_BAD_REQUEST, "URL missing")
	unless $url;
    return _new_response($request, &HTTP::Status::RC_BAD_REQUEST, "URL must be absolute")
	unless $url->scheme;

    LWP::Debug::trace("$method $url");

    # Locate protocol to use
    my $scheme = '';
    my $proxy = $self->_need_proxy($url);
    if (defined $proxy) {
	$scheme = $proxy->scheme;
    } else {
	$scheme = $url->scheme;
    }

    my $protocol;

    {
      # Honor object-specific restrictions by forcing protocol objects
      #  into class LWP::Protocol::nogo.
      my $x;
      if($x       = $self->protocols_allowed) {
        if(grep $_ eq $scheme, @$x) {
          LWP::Debug::trace("$scheme URLs are among $self\'s allowed protocols (@$x)");
        } else {
          LWP::Debug::trace("$scheme URLs aren't among $self\'s allowed protocols (@$x)");
          require LWP::Protocol::nogo;
          $protocol = LWP::Protocol::nogo->new;
        }
      } elsif ($x = $self->protocols_forbidden) {
        if(grep $_ eq $scheme, @$x) {
          LWP::Debug::trace("$scheme URLs are among $self\'s forbidden protocols (@$x)");
          require LWP::Protocol::nogo;
          $protocol = LWP::Protocol::nogo->new;
        } else {
          LWP::Debug::trace("$scheme URLs aren't among $self\'s forbidden protocols (@$x)");
        }
      }
      # else fall thru and create the protocol object normally
    }

    unless($protocol) {
      $protocol = eval { LWP::Protocol::create($scheme, $self) };
      if ($@) {
	$@ =~ s/ at .* line \d+.*//s;  # remove file/line number
	return _new_response($request, &HTTP::Status::RC_NOT_IMPLEMENTED, $@);
      }
    }

    # Extract fields that will be used below
    my ($timeout, $cookie_jar, $use_eval, $parse_head, $max_size) =
      @{$self}{qw(timeout cookie_jar use_eval parse_head max_size)};

    my $response;
    if ($use_eval) {
	# we eval, and turn dies into responses below
	eval {
	    $response = $protocol->request($request, $proxy,
					   $arg, $size, $timeout);
	};
	if ($@) {
	    $@ =~ s/ at .* line \d+.*//s;  # remove file/line number
	    $response =
	      HTTP::Response->new(&HTTP::Status::RC_INTERNAL_SERVER_ERROR,
				  $@);
	}
    } else {
	$response = $protocol->request($request, $proxy,
				       $arg, $size, $timeout);
	# XXX: Should we die unless $response->is_success ???
    }

    $response->request($request);  # record request for reference
    $cookie_jar->extract_cookies($response) if $cookie_jar;
    $response->header("Client-Date" => HTTP::Date::time2str(time));
    return $response;
}


=item $ua->prepare_request($request)

This method modifies given C<HTTP::Request> object by setting up
various headers based on the attributes of the $ua.  The headers
affected are; C<User-Agent>, C<From>, C<Range> and C<Cookie>.

The return value is the $request object passed in.

=cut

sub prepare_request
{
    my($self, $request) = @_;
    $self->_request_sanity_check($request);

    # Extract fields that will be used below
    my ($agent, $from, $cookie_jar, $max_size) =
      @{$self}{qw(agent from cookie_jar max_size)};

    # Set User-Agent and From headers if they are defined
    $request->init_header('User-Agent' => $agent) if $agent;
    $request->init_header('From' => $from) if $from;
    if (defined $max_size) {
	my $last = $max_size - 1;
	$last = 0 if $last < 0;  # there is no way to actually request no content
	$request->init_header('Range' => "bytes=0-$last");
    }
    $cookie_jar->add_cookie_header($request) if $cookie_jar;

    return($request);
}


=item $ua->simple_request($request, [$arg [, $size]])

This method dispatches a single WWW request on behalf of a user, and
returns the response received.  If differs from C<send_request()> by
automatically calling the C<prepare_request()> method before the
request is sent.

The arguments are the same as for C<send_request()>.

=cut

sub simple_request
{
    my($self, $request, $arg, $size) = @_;
    $self->_request_sanity_check($request);
    my $new_request = $self->prepare_request($request);
    return($self->send_request($new_request, $arg, $size));
}


=item $ua->request($request, $arg [, $size])

Process a request, including redirects and security.  This method may
actually send several different simple requests.

The arguments are the same as for C<send_request()> and
C<simple_request()>.

=cut

sub request
{
    my($self, $request, $arg, $size, $previous) = @_;

    LWP::Debug::trace('()');

    my $response = $self->simple_request($request, $arg, $size);

    my $code = $response->code;
    $response->previous($previous) if defined $previous;

    LWP::Debug::debug('Simple response: ' .
		      (HTTP::Status::status_message($code) ||
		       "Unknown code $code"));

    if ($code == &HTTP::Status::RC_MOVED_PERMANENTLY or
	$code == &HTTP::Status::RC_MOVED_TEMPORARILY) {

	# Make a copy of the request and initialize it with the new URI
	my $referral = $request->clone;

	# And then we update the URL based on the Location:-header.
	my($referral_uri) = $response->header('Location');
	{
	    # Some servers erroneously return a relative URL for redirects,
	    # so make it absolute if it not already is.
	    local $URI::ABS_ALLOW_RELATIVE_SCHEME = 1;
	    my $base = $response->base;
	    $referral_uri = $HTTP::URI_CLASS->new($referral_uri, $base)
		            ->abs($base);
	}

	$referral->url($referral_uri);
	$referral->remove_header('Host', 'Cookie');

	return $response unless $self->redirect_ok($referral);

	# Check for loop in the redirects
	my $count = 0;
	my $r = $response;
	while ($r) {
	    if (++$count > 13 ||
                $r->request->url->as_string eq $referral_uri->as_string) {
		$response->header("Client-Warning" =>
				  "Redirect loop detected");
		return $response;
	    }
	    $r = $r->previous;
	}

	return $self->request($referral, $arg, $size, $response);

    } elsif ($code == &HTTP::Status::RC_UNAUTHORIZED ||
	     $code == &HTTP::Status::RC_PROXY_AUTHENTICATION_REQUIRED
	    )
    {
	my $proxy = ($code == &HTTP::Status::RC_PROXY_AUTHENTICATION_REQUIRED);
	my $ch_header = $proxy ?  "Proxy-Authenticate" : "WWW-Authenticate";
	my @challenge = $response->header($ch_header);
	unless (@challenge) {
	    $response->header("Client-Warning" => 
			      "Missing Authenticate header");
	    return $response;
	}

	require HTTP::Headers::Util;
	CHALLENGE: for my $challenge (@challenge) {
	    $challenge =~ tr/,/;/;  # "," is used to separate auth-params!!
	    ($challenge) = HTTP::Headers::Util::split_header_words($challenge);
	    my $scheme = lc(shift(@$challenge));
	    shift(@$challenge); # no value
	    $challenge = { @$challenge };  # make rest into a hash
	    for (keys %$challenge) {       # make sure all keys are lower case
		$challenge->{lc $_} = delete $challenge->{$_};
	    }

	    unless ($scheme =~ /^([a-z]+(?:-[a-z]+)*)$/) {
		$response->header("Client-Warning" => 
				  "Bad authentication scheme '$scheme'");
		return $response;
	    }
	    $scheme = $1;  # untainted now
	    my $class = "LWP::Authen::\u$scheme";
	    $class =~ s/-/_/g;

	    no strict 'refs';
	    unless (%{"$class\::"}) {
		# try to load it
		eval "require $class";
		if ($@) {
		    if ($@ =~ /^Can\'t locate/) {
			$response->header("Client-Warning" =>
					  "Unsupported authentication scheme '$scheme'");
		    } else {
			$response->header("Client-Warning" => $@);
		    }
		    next CHALLENGE;
		}
	    }
	    return $class->authenticate($self, $proxy, $challenge, $response,
					$request, $arg, $size);
	}
	return $response;
    }
    return $response;
}

#---------------------------------------------------------------------------
# Now the shortcuts...

=item $ua->get($url, Header => Value,...);

This is a shortcut for C<$ua-E<gt>request(HTTP::Request::Common::GET(
$url, Header =E<gt> Value,... ))>.  See
L<HTTP::Request::Common|HTTP::Request::Common>.

=item $ua->post($url, \%formref, Header => Value,...);

This is a shortcut for C<$ua-E<gt>request( HTTP::Request::Common::POST(
$url, \%formref, Header =E<gt> Value,... ))>.  Note that the form
reference is optional, and can be either a hashref (C<\%formdata> or C<{
'key1' => 'val2', 'key2' => 'val2', ...
}>) or an arrayref (C<\@formdata> or
C<['key1' => 'val2', 'key2' => 'val2', ...]>).  See
L<HTTP::Request::Common|HTTP::Request::Common>.

=item $ua->head($url, Header => Value,...);

This is a shortcut for C<$ua-E<gt>request( HTTP::Request::Common::HEAD(
$url, Header =E<gt> Value,... ))>.  See
L<HTTP::Request::Common|HTTP::Request::Common>.

=item $ua->put($url, Header => Value,...);

This is a shortcut for C<$ua-E<gt>request( HTTP::Request::Common::PUT(
$url, Header =E<gt> Value,... ))>.  See
L<HTTP::Request::Common|HTTP::Request::Common>.

=cut

sub get {
  require HTTP::Request::Common;
  return shift->request( HTTP::Request::Common::GET( @_ ) );
}

sub post {
  require HTTP::Request::Common;
  return shift->request( HTTP::Request::Common::POST( @_ ) );
}

sub head {
  require HTTP::Request::Common;
  return shift->request( HTTP::Request::Common::HEAD( @_ ) );
}

sub put {
  require HTTP::Request::Common;
  return shift->request( HTTP::Request::Common::PUT( @_ ) );
}


#---------------------------------------------------------------------------
# This whole allow/forbid thing is based on man 1 at's way of doing things.

=item $ua->protocols_allowed( );  # to read

=item $ua->protocols_allowed( \@protocols ); # to set

This reads (or sets) this user-agent's list of procotols that
C<$ua-E<gt>request> and C<$ua-E<gt>simple_request> will exclusively
allow.

For example: C<$ua-E<gt>protocols_allowed( [ 'http', 'https'] );>
means that this user agent will I<allow only> those protocols,
and attempts to use this user-agent to access URLs with any other
schemes (like "ftp://...") will result in a 500 error.

To delete the list, call: 
C<$ua-E<gt>protocols_allowed(undef)>

By default, an object has neither a protocols_allowed list, nor
a protocols_forbidden list.

Note that having a protocols_allowed
list causes any protocols_forbidden list to be ignored.

=item $ua->protocols_forbidden( );  # to read

=item $ua->protocols_forbidden( \@protocols ); # to set

This reads (or sets) this user-agent's list of procotols that
C<$ua-E<gt>request> and C<$ua-E<gt>simple_request> will I<not> allow.

For example: C<$ua-E<gt>protocols_forbidden( [ 'file', 'mailto'] );>
means that this user-agent will I<not> allow those protocols, and
attempts to use this user-agent to access URLs with those schemes
will result in a 500 error.

To delete the list, call: 
C<$ua-E<gt>protocols_forbidden(undef)>

=item $ua->is_protocol_supported($scheme)

You can use this method to test whether this user-agent object supports the
specified C<scheme>.  (The C<scheme> might be a string (like 'http' or
'ftp') or it might be an URI object reference.)

Whether a scheme is supported, is determined by $ua's protocols_allowed or
protocols_forbidden lists (if any), and by the capabilities
of LWP.  I.e., this will return TRUE only if LWP supports this protocol
I<and> it's permitted for this particular object.

=cut

sub is_protocol_supported
{
    my($self, $scheme) = @_;
    if (ref $scheme) {
	# assume we got a reference to an URI object
	$scheme = $scheme->scheme;
    } else {
	Carp::croak("Illegal scheme '$scheme' passed to is_protocol_supported")
	    if $scheme =~ /\W/;
	$scheme = lc $scheme;
    }

    my $x;
    if(ref($self) and $x       = $self->protocols_allowed) {
      return 0 unless grep $_ eq $scheme, @$x;
    } elsif (ref($self) and $x = $self->protocols_forbidden) {
      return 0 if grep $_ eq $scheme, @$x;
    }

    local($SIG{__DIE__});  # protect agains user defined die handlers
    $x = LWP::Protocol::implementor($scheme);
    return 1 if $x and $x ne 'LWP::Protocol::nogo';
    return 0;
}

#---------------------------------------------------------------------------

=item $ua->requests_redirectable( );  # to read

=item $ua->requests_redirectable( \@requests );  # to set

This reads or sets the object's list of request names that 
C<$ua-E<gt>redirect_ok(...)> will allow redirection for.  By
default, this is C<['GET', 'HEAD']>, as per RFC 2068.  To
change to include 'POST', consider:

   push @{ $ua->requests_redirectable }, 'POST';

=cut

sub protocols_allowed      { shift->_elem('protocols_allowed'    , @_) }
sub protocols_forbidden    { shift->_elem('protocols_forbidden'  , @_) }
sub requests_redirectable  { shift->_elem('requests_redirectable', @_) }

#---------------------------------------------------------------------------

=item $ua->redirect_ok($prospective_request)

This method is called by request() before it tries to follow a
redirection to the request in $prospective_request.  This
should return a true value if this redirection is
permissible.

The default implementation will return FALSE unless the method
is in the object's C<requests_redirectable> list,
FALSE if the proposed redirection is to a "file://..."
URL, and TRUE otherwise.

Subclasses might want to override this.

(This method's behavior in previous versions was simply to return
TRUE for anything except POST requests).

=cut

sub redirect_ok
{
    # RFC 2068, section 10.3.2 and 10.3.3 say:
    #  If the 30[12] status code is received in response to a request other
    #  than GET or HEAD, the user agent MUST NOT automatically redirect the
    #  request unless it can be confirmed by the user, since this might
    #  change the conditions under which the request was issued.

    # Note that this routine used to be just:
    #  return 0 if $_[1]->method eq "POST";  return 1;

    my($self, $request) = @_;
    my $method = $request->method;
    return 0 unless grep $_ eq $method,
      @{ $self->requests_redirectable || [] };
    
    if($request->url->scheme eq 'file') {
      LWP::Debug::trace("Can't redirect to a file:// URL!");
      return 0;
    }
    
    # Otherwise it's apparently okay...
    return 1;
}


=item $ua->credentials($netloc, $realm, $uname, $pass)

Set the user name and password to be used for a realm.  It is often more
useful to specialize the get_basic_credentials() method instead.

=cut

sub credentials
{
    my($self, $netloc, $realm, $uid, $pass) = @_;
    @{ $self->{'basic_authentication'}{$netloc}{$realm} } = ($uid, $pass);
}


=item $ua->get_basic_credentials($realm, $uri, [$proxy])

This is called by request() to retrieve credentials for a Realm
protected by Basic Authentication or Digest Authentication.

Should return username and password in a list.  Return undef to abort
the authentication resolution atempts.

This implementation simply checks a set of pre-stored member
variables. Subclasses can override this method to e.g. ask the user
for a username/password.  An example of this can be found in
C<lwp-request> program distributed with this library.

=cut

sub get_basic_credentials
{
    my($self, $realm, $uri, $proxy) = @_;
    return if $proxy;

    my $host_port = $uri->host_port;
    if (exists $self->{'basic_authentication'}{$host_port}{$realm}) {
	return @{ $self->{'basic_authentication'}{$host_port}{$realm} };
    }

    return (undef, undef);
}


=item $ua->agent([$product_id])

Get/set the product token that is used to identify the user agent on
the network.  The agent value is sent as the "User-Agent" header in
the requests.  The default is the string returned by the _agent()
method (see below).

If the $product_id ends with space then the C<_agent> string is
appended to it.

The user agent string should be one or more simple product identifiers
with an optional version number separated by the "/" character.
Examples are:

  $ua->agent('Checkbot/0.4 ' . $ua->_agent);
  $ua->agent('Checkbot/0.4 ');    # same as above
  $ua->agent('Mozilla/5.0');
  $ua->agent("");                 # don't identify

=item $ua->_agent

Returns the default agent identifier.  This is a string of the form
"libwww-perl/#.##", where "#.##" is substitued with the version numer
of this library.

=cut

sub agent {
    my $self = shift;
    my $old = $self->{agent};
    if (@_) {
	my $agent = shift;
	$agent .= $self->_agent if $agent && $agent =~ /\s+$/;
	$self->{agent} = $agent;
    }
    $old;
}

sub _agent     { "libwww-perl/$LWP::VERSION" }


=item $ua->from([$email_address])

Get/set the Internet e-mail address for the human user who controls
the requesting user agent.  The address should be machine-usable, as
defined in RFC 822.  The from value is send as the "From" header in
the requests.  Example:

  $ua->from('gaas@cpan.org');

The default is to not send a "From" header.

=item $ua->timeout([$secs])

Get/set the timeout value in seconds. The default timeout() value is
180 seconds, i.e. 3 minutes.

=item $ua->cookie_jar([$cookie_jar_obj])

Get/set the cookie jar object to use.  The only requirement is that
the cookie jar object must implement the extract_cookies($request) and
add_cookie_header($response) methods.  These methods will then be
invoked by the user agent as requests are sent and responses are
received.  Normally this will be a C<HTTP::Cookies> object or some
subclass.

The default is to have no cookie_jar, i.e. never automatically add
"Cookie" headers to the requests.

Shortcut: If a reference to a plain hash is passed in as the
$cookie_jar_object, then it is replaced with an instance of
C<HTTP::Cookies> that is initalized based on the hash.  This form also
automatically loads the C<HTTP::Cookies> module.  It means that:

  $ua->cookie_jar({ file => "$ENV{HOME}/.cookies.txt" });

is really just a shortcut for:

  require HTTP::Cookies;
  $ua->cookie_jar(HTTP::Cookies->new(file => "$ENV{HOME}/.cookies.txt"));

=item $ua->conn_cache([$cache_obj])

Get/set the I<LWP::ConnCache> object to use.

=item $ua->parse_head([$boolean])

Get/set a value indicating wether we should initialize response
headers from the E<lt>head> section of HTML documents. The default is
TRUE.  Do not turn this off, unless you know what you are doing.

=item $ua->max_size([$bytes])

Get/set the size limit for response content.  The default is C<undef>,
which means that there is no limit.  If the returned response content
is only partial, because the size limit was exceeded, then a
"Client-Aborted" header will be added to the response.

=cut

sub timeout    { shift->_elem('timeout',   @_); }
sub from       { shift->_elem('from',      @_); }
sub parse_head { shift->_elem('parse_head',@_); }
sub max_size   { shift->_elem('max_size',  @_); }

sub cookie_jar {
    my $self = shift;
    my $old = $self->{cookie_jar};
    if (@_) {
	my $jar = shift;
	if (ref($jar) eq "HASH") {
	    require HTTP::Cookies;
	    $jar = HTTP::Cookies->new(%$jar);
	}
	$self->{cookie_jar} = $jar;
    }
    $old;
}

sub conn_cache {
    my $self = shift;
    my $old = $self->{conn_cache};
    if (@_) {
	my $cache = shift;
	if (ref($cache) eq "HASH") {
	    require LWP::ConnCache;
	    $cache = LWP::ConnCache->new(%$cache);
	}
	$self->{conn_cache} = $cache;
    }
    $old;
}

# depreciated
sub use_eval   { shift->_elem('use_eval',  @_); }
sub use_alarm
{
    Carp::carp("LWP::UserAgent->use_alarm(BOOL) is a no-op")
	if @_ > 1 && $^W;
    "";
}


=item $ua->clone;

Returns a copy of the LWP::UserAgent object

=cut


sub clone
{
    my $self = shift;
    my $copy = bless { %$self }, ref $self;  # copy most fields

    # elements that are references must be handled in a special way
    $copy->{'proxy'} = { %{$self->{'proxy'}} };
    $copy->{'no_proxy'} = [ @{$self->{'no_proxy'}} ];  # copy array

    # remove reference to objects for now
    delete $copy->{cookie_jar};
    delete $copy->{conn_cache};

    $copy;
}




=item $ua->mirror($url, $file)

Get and store a document identified by a URL, using If-Modified-Since,
and checking of the Content-Length.  Returns a reference to the
response object.

=cut

sub mirror
{
    my($self, $url, $file) = @_;

    LWP::Debug::trace('()');
    my $request = HTTP::Request->new('GET', $url);

    if (-e $file) {
	my($mtime) = (stat($file))[9];
	if($mtime) {
	    $request->header('If-Modified-Since' =>
			     HTTP::Date::time2str($mtime));
	}
    }
    my $tmpfile = "$file-$$";

    my $response = $self->request($request, $tmpfile);
    if ($response->is_success) {

	my $file_length = (stat($tmpfile))[7];
	my($content_length) = $response->header('Content-length');

	if (defined $content_length and $file_length < $content_length) {
	    unlink($tmpfile);
	    die "Transfer truncated: " .
		"only $file_length out of $content_length bytes received\n";
	} elsif (defined $content_length and $file_length > $content_length) {
	    unlink($tmpfile);
	    die "Content-length mismatch: " .
		"expected $content_length bytes, got $file_length\n";
	} else {
	    # OK
	    if (-e $file) {
		# Some dosish systems fail to rename if the target exists
		chmod 0777, $file;
		unlink $file;
	    }
	    rename($tmpfile, $file) or
		die "Cannot rename '$tmpfile' to '$file': $!\n";

	    if (my $lm = $response->last_modified) {
		# make sure the file has the same last modification time
		utime $lm, $lm, $file;
	    }
	}
    } else {
	unlink($tmpfile);
    }
    return $response;
}

=item $ua->proxy(...)

Set/retrieve proxy URL for a scheme:

 $ua->proxy(['http', 'ftp'], 'http://proxy.sn.no:8001/');
 $ua->proxy('gopher', 'http://proxy.sn.no:8001/');

The first form specifies that the URL is to be used for proxying of
access methods listed in the list in the first method argument,
i.e. 'http' and 'ftp'.

The second form shows a shorthand form for specifying
proxy URL for a single access scheme.

=cut

sub proxy
{
    my $self = shift;
    my $key  = shift;

    LWP::Debug::trace("$key @_");

    return map $self->proxy($_, @_), @$key if ref $key;

    my $old = $self->{'proxy'}{$key};
    $self->{'proxy'}{$key} = shift if @_;
    return $old;
}

=item $ua->env_proxy()

Load proxy settings from *_proxy environment variables.  You might
specify proxies like this (sh-syntax):

  gopher_proxy=http://proxy.my.place/
  wais_proxy=http://proxy.my.place/
  no_proxy="localhost,my.domain"
  export gopher_proxy wais_proxy no_proxy

Csh or tcsh users should use the C<setenv> command to define these
environment variables.

On systems with case-insensitive environment variables there exists a
name clash between the CGI environment variables and the C<HTTP_PROXY>
environment variable normally picked up by env_proxy().  Because of
this C<HTTP_PROXY> is not honored for CGI scripts.  The
C<CGI_HTTP_PROXY> environment variable can be used instead.

=cut

sub env_proxy {
    my ($self) = @_;
    my($k,$v);
    while(($k, $v) = each %ENV) {
	if ($ENV{REQUEST_METHOD}) {
	    # Need to be careful when called in the CGI environment, as
	    # the HTTP_PROXY variable is under control of that other guy.
	    next if $k =~ /^HTTP_/;
	    $k = "HTTP_PROXY" if $k eq "CGI_HTTP_PROXY";
	}
	$k = lc($k);
	next unless $k =~ /^(.*)_proxy$/;
	$k = $1;
	if ($k eq 'no') {
	    $self->no_proxy(split(/\s*,\s*/, $v));
	}
	else {
	    $self->proxy($k, $v);
	}
    }
}

=item $ua->no_proxy($domain,...)

Do not proxy requests to the given domains.  Calling no_proxy without
any domains clears the list of domains. Eg:

 $ua->no_proxy('localhost', 'no', ...);

=cut

sub no_proxy {
    my($self, @no) = @_;
    if (@no) {
	push(@{ $self->{'no_proxy'} }, @no);
    }
    else {
	$self->{'no_proxy'} = [];
    }
}


# Private method which returns the URL of the Proxy configured for this
# URL, or undefined if none is configured.
sub _need_proxy
{
    my($self, $url) = @_;
    $url = $HTTP::URI_CLASS->new($url) unless ref $url;

    my $scheme = $url->scheme || return;
    if (my $proxy = $self->{'proxy'}{$scheme}) {
	if (@{ $self->{'no_proxy'} }) {
	    if (my $host = eval { $url->host }) {
		for my $domain (@{ $self->{'no_proxy'} }) {
		    if ($host =~ /\Q$domain\E$/) {
			LWP::Debug::trace("no_proxy configured");
			return;
		    }
		}
	    }
	}
	LWP::Debug::debug("Proxied to $proxy");
	return $HTTP::URI_CLASS->new($proxy);
    }
    LWP::Debug::debug('Not proxied');
    undef;
}

sub _new_response {
    my($request, $code, $message) = @_;
    my $response = HTTP::Response->new($code, $message);
    $response->request($request);
    $response->header("Client-Date" => HTTP::Date::time2str(time));
    return $response;
}

1;

=back

=head1 SEE ALSO

See L<LWP> for a complete overview of libwww-perl5.  See F<lwp-request> and
F<lwp-mirror> for examples of usage.

=head1 COPYRIGHT

Copyright 1995-2001 Gisle Aas.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut



#
# $Id: LWP.pm,v 1.100 2001/04/09 20:44:05 gisle Exp $

package LWP;

$VERSION = "5.53";
sub Version { $VERSION; }

require 5.004;
require LWP::UserAgent;  # this should load everything you need

1;

__END__

=head1 NAME

LWP - Library for WWW access in Perl

=head1 SYNOPSIS

  use LWP;
  print "This is libwww-perl-$LWP::VERSION\n";


=head1 DESCRIPTION

Libwww-perl is a collection of Perl modules which provides a simple
and consistent application programming interface (API) to the World-Wide Web.  The
main focus of the library is to provide classes and functions that
allow you to write WWW clients, thus libwww-perl is a WWW
client library. The library also contain modules that are of more
general use.

Most modules in this library are object oriented.  The user
agent, requests sent and responses received from the WWW server are
all represented by objects.  This makes a simple and powerful
interface to these services.  The interface should be easy to extend
and customize for your needs.

The main features of the library are:

=over 3

=item *

Contains various reusable components (modules) that can be
used separately or together.

=item *

Provides an object oriented model of HTTP-style communication.  Within
this framework we currently support access to http, https, gopher, ftp, news,
file, and mailto resources.

=item *

Provides a full object oriented interface or
a very simple procedural interface.

=item *

Supports the basic and digest authorization schemes.

=item *

Supports transparent redirect handling.

=item *

Supports access through proxy servers.

=item *

Provides parser for F<robots.txt> files and a framework for constructing robots.

=item *

Cooperates with Tk.  A simple Tk-based GUI browser
called 'tkweb' is distributed with the Tk extension for perl.

=item *

Implements HTTP content negotiation algorithm that can
be used both in protocol modules and in server scripts (like CGI
scripts).

=item *

Supports HTTP cookies.

=item *

A simple command line client application called C<lwp-request>.

=back


=head1 HTTP STYLE COMMUNICATION


The libwww-perl library is based on HTTP style communication. This
section tries to describe what that means.

Let us start with this quote from the HTTP specification document
<URL:http://www.w3.org/pub/WWW/Protocols/>:

=over 3

=item

The HTTP protocol is based on a request/response paradigm. A client
establishes a connection with a server and sends a request to the
server in the form of a request method, URI, and protocol version,
followed by a MIME-like message containing request modifiers, client
information, and possible body content. The server responds with a
status line, including the message's protocol version and a success or
error code, followed by a MIME-like message containing server
information, entity meta-information, and possible body content.

=back

What this means to libwww-perl is that communication always take place
through these steps: First a I<request> object is created and
configured. This object is then passed to a server and we get a
I<response> object in return that we can examine. A request is always
independent of any previous requests, i.e. the service is stateless.
The same simple model is used for any kind of service we want to
access.

For example, if we want to fetch a document from a remote file server,
then we send it a request that contains a name for that document and
the response will contain the document itself.  If we access a search
engine, then the content of the request will contain the query
parameters and the response will contain the query result.  If we want
to send a mail message to somebody then we send a request object which
contains our message to the mail server and the response object will
contain an acknowledgment that tells us that the message has been
accepted and will be forwarded to the recipient(s).

It is as simple as that!


=head2 The Request Object

The libwww-perl request object has the class name C<HTTP::Request>.
The fact that the class name uses C<HTTP::> as a
prefix only implies that we use the HTTP model of communication.  It
does not limit the kind of services we can try to pass this I<request>
to.  For instance, we will send C<HTTP::Request>s both to ftp and
gopher servers, as well as to the local file system.

The main attributes of the request objects are:

=over 3

=item *

The B<method> is a short string that tells what kind of
request this is.  The most used methods are B<GET>, B<PUT>,
B<POST> and B<HEAD>.

=item *

The B<url> is a string denoting the protocol, server and
the name of the "document" we want to access.  The B<url> might
also encode various other parameters.

=item *

The B<headers> contain additional information about the
request and can also used to describe the content.  The headers
are a set of keyword/value pairs.

=item *

The B<content> is an arbitrary amount of data.

=back

=head2 The Response Object

The libwww-perl response object has the class name C<HTTP::Response>.
The main attributes of objects of this class are:

=over 3

=item *

The B<code> is a numerical value that indicates the overall
outcome of the request.

=item *

The B<message> is a short, human readable string that
corresponds to the I<code>.

=item *

The B<headers> contain additional information about the
response and describe the content.

=item *

The B<content> is an arbitrary amount of data.

=back

Since we don't want to handle all possible I<code> values directly in
our programs, a libwww-perl response object has methods that can be
used to query what kind of response this is.  The most commonly used
response classification methods are:

=over 3

=item is_success()

The request was was successfully received, understood or accepted.

=item is_error()

The request failed.  The server or the resource might not be
available, access to the resource might be denied or other things might
have failed for some reason.

=back

=head2 The User Agent

Let us assume that we have created a I<request> object. What do we
actually do with it in order to receive a I<response>?

The answer is that you pass it to a I<user agent> object and this
object takes care of all the things that need to be done
(like low-level communication and error handling) and returns
a I<response> object. The user agent represents your
application on the network and provides you with an interface that
can accept I<requests> and return I<responses>.

The user agent is an interface layer between
your application code and the network.  Through this interface you are
able to access the various servers on the network.

The libwww-perl class name for the user agent is
C<LWP::UserAgent>.  Every libwww-perl application that wants to
communicate should create at least one object of this class. The main
method provided by this object is request(). This method takes an
C<HTTP::Request> object as argument and (eventually) returns a
C<HTTP::Response> object.

The user agent has many other attributes that let you
configure how it will interact with the network and with your
application.

=over 3

=item *

The B<timeout> specifies how much time we give remote servers to
respond before the library disconnects and creates an
internal I<timeout> response.

=item *

The B<agent> specifies the name that your application should use when it
presents itself on the network.

=item *

The B<from> attribute can be set to the e-mail address of the person
responsible for running the application.  If this is set, then the
address will be sent to the servers with every request.

=item *

The B<parse_head> specifies whether we should initialize response
headers from the E<lt>head> section of HTML documents.

=item *

The B<proxy> and B<no_proxy> attributes specify if and when to go through
a proxy server. <URL:http://www.w3.org/pub/WWW/Proxies/>

=item *

The B<credentials> provide a way to set up user names and
passwords needed to access certain services.

=back

Many applications want even more control over how they interact
with the network and they get this by sub-classing
C<LWP::UserAgent>.  The library includes a
sub-class, C<LWP::RobotUA>, for robot applications.

=head2 An Example

This example shows how the user agent, a request and a response are
represented in actual perl code:

  # Create a user agent object
  use LWP::UserAgent;
  $ua = new LWP::UserAgent;
  $ua->agent("AgentName/0.1 " . $ua->agent);

  # Create a request
  my $req = new HTTP::Request POST => 'http://www.perl.com/cgi-bin/BugGlimpse';
  $req->content_type('application/x-www-form-urlencoded');
  $req->content('match=www&errors=0');

  # Pass request to the user agent and get a response back
  my $res = $ua->request($req);

  # Check the outcome of the response
  if ($res->is_success) {
      print $res->content;
  } else {
      print "Bad luck this time\n";
  }

The $ua is created once when the application starts up.  New request
objects should normally created for each request sent.


=head1 NETWORK SUPPORT

This section discusses the various protocol schemes and
the HTTP style methods that headers may be used for each.

For all requests, a "User-Agent" header is added and initialized from
the $ua->agent attribute before the request is handed to the network
layer.  In the same way, a "From" header is initialized from the
$ua->from attribute.

For all responses, the library adds a header called "Client-Date".
This header holds the time when the response was received by
your application.  The format and semantics of the header are the
same as the server created "Date" header.  You may also encounter other
"Client-XXX" headers.  They are all generated by the library
internally and are not received from the servers.

=head2 HTTP Requests

HTTP requests are just handed off to an HTTP server and it
decides what happens.  Few servers implement methods beside the usual
"GET", "HEAD", "POST" and "PUT", but CGI-scripts may implement
any method they like.

If the server is not available then the library will generate an
internal error response.

The library automatically adds a "Host" and a "Content-Length" header
to the HTTP request before it is sent over the network.

For GET request you might want to add the "If-Modified-Since" header
to make the request conditional.

For POST request you should add the "Content-Type" header.  When you
try to emulate HTML E<lt>FORM> handling you should usually let the value
of the "Content-Type" header be "application/x-www-form-urlencoded".
See L<lwpcook> for examples of this.

The libwww-perl HTTP implementation currently support the HTTP/1.0
protocol.  HTTP/0.9 servers are also handled correctly.

The library allows you to access proxy server through HTTP.  This
means that you can set up the library to forward all types of request
through the HTTP protocol module.  See L<LWP::UserAgent> for
documentation of this.


=head2 HTTPS Requests

HTTPS requests are HTTP requests over an encrypted network connection
using the SSL protocol developed by Netscape.  Everything about HTTP
requests above also apply to HTTPS requests.  In addition the library
will add the headers "Client-SSL-Cipher", "Client-SSL-Cert-Subject" and
"Client-SSL-Cert-Issuer" to the response.  These headers denote the
encryption method used and the name of the server owner.

The request can contain the header "If-SSL-Cert-Subject" in order to
make the request conditional on the content of the server certificate.
If the certificate subject does not match, no request is sent to the
server and an internally generated error response is returned.  The
value of the "If-SSL-Cert-Subject" header is interpreted as a Perl
regular expression.


=head2 FTP Requests

The library currently supports GET, HEAD and PUT requests.  GET
retrieves a file or a directory listing from an FTP server.  PUT
stores a file on a ftp server.

You can specify a ftp account for servers that want this in addition
to user name and password.  This is specified by including an "Account"
header in the request.

User name/password can be specified using basic authorization or be
encoded in the URL.  Failed logins return an UNAUTHORIZED response with
"WWW-Authenticate: Basic" and can be treated like basic authorization
for HTTP.

The library supports ftp ASCII transfer mode by specifying the "type=a"
parameter in the URL.

Directory listings are by default returned unprocessed (as returned
from the ftp server) with the content media type reported to be
"text/ftp-dir-listing". The C<File::Listing> module provides methods
for parsing of these directory listing.

The ftp module is also able to convert directory listings to HTML and
this can be requested via the standard HTTP content negotiation
mechanisms (add an "Accept: text/html" header in the request if you
want this).

For normal file retrievals, the "Content-Type" is guessed based on the
file name suffix. See L<LWP::MediaTypes>.

The "If-Modified-Since" request header works for servers that implement
the MDTM command.  It will probably not work for directory listings though.

Example:

  $req = HTTP::Request->new(GET => 'ftp://me:passwd@ftp.some.where.com/');
  $req->header(Accept => "text/html, */*;q=0.1");

=head2 News Requests

Access to the USENET News system is implemented through the NNTP
protocol.  The name of the news server is obtained from the
NNTP_SERVER environment variable and defaults to "news".  It is not
possible to specify the hostname of the NNTP server in news: URLs.

The library supports GET and HEAD to retrieve news articles through the
NNTP protocol.  You can also post articles to newsgroups by using
(surprise!) the POST method.

GET on newsgroups is not implemented yet.

Examples:

  $req = HTTP::Request->new(GET => 'news:abc1234@a.sn.no');

  $req = HTTP::Request->new(POST => 'news:comp.lang.perl.test');
  $req->header(Subject => 'This is a test',
               From    => 'me@some.where.org');
  $req->content(<<EOT);
  This is the content of the message that we are sending to
  the world.
  EOT


=head2 Gopher Request

The library supports the GET and HEAD methods for gopher requests.  All
request header values are ignored.  HEAD cheats and returns a
response without even talking to server.

Gopher menus are always converted to HTML.

The response "Content-Type" is generated from the document type
encoded (as the first letter) in the request URL path itself.

Example:

  $req = HTTP::Request->new(GET => 'gopher://gopher.sn.no/');



=head2 File Request

The library supports GET and HEAD methods for file requests.  The
"If-Modified-Since" header is supported.  All other headers are
ignored.  The I<host> component of the file URL must be empty or set
to "localhost".  Any other I<host> value will be treated as an error.

Directories are always converted to an HTML document.  For normal
files, the "Content-Type" and "Content-Encoding" in the response are
guessed based on the file suffix.

Example:

  $req = HTTP::Request->new(GET => 'file:/etc/passwd');


=head2 Mailto Request

You can send (aka "POST") mail messages using the library.  All
headers specified for the request are passed on to the mail system.
The "To" header is initialized from the mail address in the URL.

Example:

  $req = HTTP::Request->new(POST => 'mailto:libwww@perl.org');
  $req->header(Subject => "subscribe");
  $req->content("Please subscribe me to the libwww-perl mailing list!\n");


=head1 OVERVIEW OF CLASSES AND PACKAGES

This table should give you a quick overview of the classes provided by the
library. Indentation shows class inheritance.

 LWP::MemberMixin   -- Access to member variables of Perl5 classes
   LWP::UserAgent   -- WWW user agent class
     LWP::RobotUA   -- When developing a robot applications
   LWP::Protocol          -- Interface to various protocol schemes
     LWP::Protocol::http  -- http:// access
     LWP::Protocol::file  -- file:// access
     LWP::Protocol::ftp   -- ftp:// access
     ...

 LWP::Authen::Basic -- Handle 401 and 407 responses
 LWP::Authen::Digest

 HTTP::Headers      -- MIME/RFC822 style header (used by HTTP::Message)
 HTTP::Message      -- HTTP style message
   HTTP::Request    -- HTTP request
   HTTP::Response   -- HTTP response
 HTTP::Daemon       -- A HTTP server class

 WWW::RobotRules    -- Parse robots.txt files
   WWW::RobotRules::AnyDBM_File -- Persistent RobotRules

The following modules provide various functions and definitions.

 LWP                -- This file.  Library version number and documentation.
 LWP::MediaTypes    -- MIME types configuration (text/html etc.)
 LWP::Debug         -- Debug logging module
 LWP::Simple        -- Simplified procedural interface for common functions
 HTTP::Status       -- HTTP status code (200 OK etc)
 HTTP::Date         -- Date parsing module for HTTP date formats
 HTTP::Negotiate    -- HTTP content negotiation calculation
 File::Listing      -- Parse directory listings


=head1 MORE DOCUMENTATION

All modules contain detailed information on the interfaces they
provide.  The I<lwpcook> manpage is the libwww-perl cookbook that contain
examples of typical usage of the library.  You might want to take a
look at how the scripts C<lwp-request>, C<lwp-rget> and C<lwp-mirror>
are implemented.

=head1 BUGS

The library can not handle multiple simultaneous requests yet.  Also,
check out what's left in the TODO file.

=head1 ACKNOWLEDGEMENTS

This package owes a lot in motivation, design, and code, to the
libwww-perl library for Perl 4, maintained by Roy Fielding
E<lt>fielding@ics.uci.edu>.

That package used work from Alberto Accomazzi, James Casey, Brooks
Cutter, Martijn Koster, Oscar Nierstrasz, Mel Melchner, Gertjan van
Oosten, Jared Rhine, Jack Shirazi, Gene Spafford, Marc VanHeyningen,
Steven E. Brenner, Marion Hakanson, Waldemar Kebsch, Tony Sanders, and
Larry Wall; see the libwww-perl-0.40 library for details.

The primary architect for this Perl 5 library is Martijn Koster and
Gisle Aas, with lots of help from Graham Barr, Tim Bunce, Andreas
Koenig, Jared Rhine, and Jack Shirazi.


=head1 COPYRIGHT

  Copyright 1995-2001, Gisle Aas
  Copyright 1995, Martijn Koster

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AVAILABILITY

The latest version of this library is likely to be available from CPAN
as well as:

 http://www.linpro.no/lwp/

The best place to discuss this code is on the <libwww@perl.org>
mailing list.

=cut

package Net::HTTP;

# $Id: HTTP.pm,v 1.39 2001/12/03 22:04:54 gisle Exp $

use strict;
use vars qw($VERSION @ISA);

$VERSION = "0.04";
eval { require IO::Socket::INET } || require IO::Socket;
require Net::HTTP::Methods;

@ISA=qw(IO::Socket::INET Net::HTTP::Methods);

sub configure {
    my($self, $cnf) = @_;
    $self->http_configure($cnf);
}

sub http_connect {
    my($self, $cnf) = @_;
    $self->SUPER::configure($cnf);
}

1;

__END__

=head1 NAME

Net::HTTP - Low-level HTTP client connection

=head1 NOTE

This module is experimental.  Details of its interface is likely to
change in the future.

=head1 SYNOPSIS

 use Net::HTTP;
 my $s = Net::HTTP->new(Host => "www.perl.com) || die $@;
 $s->write_request(GET => "/", 'User-Agent' => "Mozilla/5.0");
 my($code, $mess, %h) = $s->read_response_headers;

 while (1) {
    my $buf;
    my $n = $s->read_entity_body($buf, 1024);
    last unless $n;
    print $buf;
 }

=head1 DESCRIPTION

The C<Net::HTTP> class is a low-level HTTP client.  An instance of the
C<Net::HTTP> class represents a connection to an HTTP server.  The
HTTP protocol is described in RFC 2616.

C<Net::HTTP> is a sub-class of C<IO::Socket::INET>.  You can mix the
methods described below with reading and writing from the socket
directly.  This is not necessary a good idea, unless you know what you
are doing.

The following methods are provided (in addition to those of
C<IO::Socket::INET>):

=over

=item $s = Net::HTTP->new( %options )

The C<Net::HTTP> constructor takes the same options as
C<IO::Socket::INET> as well as these:

  Host:            Initial host attribute value
  KeepAlive:       Initial keep_alive attribute value
  SendTE:          Initial send_te attribute_value
  HTTPVersion:     Initial http_version attribute value
  PeerHTTPVersion: Initial peer_http_version attribute value
  MaxLineLength:   Initial max_line_length attribute value
  MaxHeaderLines:  Initial max_header_lines attribute value

=item $s->host

Get/set the default value of the C<Host> header to send.  The $host
should not be set to an empty string (or C<undef>).

=item $s->keep_alive

Get/set the I<keep-alive> value.  If this value is TRUE then the
request will be sent with headers indicating that the server should try
to keep the connection open so that multiple requests can be sent.

The actual headers set will depend on the value of the C<http_version>
and C<peer_http_version> attributes.

=item $s->send_te

Get/set the a value indicating if the request will be sent with a "TE"
header to indicate the transfer encodings that the server can chose to
use.  If the C<Compress::Zlib> module is installed then this will
annouce that this client accept both the I<deflate> and I<gzip>
encodings.

=item $s->http_version

Get/set the HTTP version number that this client should announce.
This value can only be set to "1.0" or "1.1".  The default is "1.1".

=item $s->peer_http_version

Get/set the protocol version number of our peer.  This value will
initially be "1.0", but will be updated by a successful
read_response_headers() method call.

=item $s->max_line_length

Get/set a limit on the length of response line and response header
lines.  The default is 4096.  A value of 0 means no limit.

=item $s->max_header_length

Get/set a limit on the number of headers lines that a response can
have.  The default is 128.  A value of 0 means no limit.

=item $s->format_request($method, $uri, %headers, [$content])

Format a request message and return it as a string.  If the headers do
not include a C<Host> header, then a header is inserted with the value
of the C<host> attribute.  Headers like C<Connection> and
C<Keep-Alive> might also be added depending on the status of the
C<keep_alive> attribute.

If $content is given (and it is non-empty), then a C<Content-Length>
header is automatically added unless it was already present.

=item $s->write_request($method, $uri, %headers, [$content])

Format and send a request message.  Arguments are the same as for
format_request().  Returns true if successful.

=item $s->write_chunk($data)

Will write a new chunk of request entity body data.  This method
should only be used if the C<Transfer-Encoding> header with a value of
C<chunked> was sent in the request.  Note, writing zero-length data is
a no-op.  Use the write_chunk_eof() method to signal end of entity
body data.

Returns true if successful.

=item $s->format_chunk($data)

Returns the string to be written for the given chunk of data.

=item $s->write_chunk_eof(%trailers)

Will write eof marker for chunked data and optional trailers.  Note
that trailers should not really be used unless is was signaled
with a C<Trailer> header.

Returns true if successful.

=item $s->format_chunk_eof(%trailers)

Returns the string to be written for signaling EOF.

=item ($code, $mess, %headers) = $s->read_response_headers( %opts )

Read response headers from server.  The $code is the 3 digit HTTP
status code (see L<HTTP::Status>) and $mess is the textual message
that came with it.  Headers are then returned as key/value pairs.
Since key letter casing is not normalized and the same key can occur
multiple times, assigning these values directly to a hash might be
risky.

As a side effect this method updates the 'peer_http_version'
attribute.

The method will raise exceptions (die) if the server does not speak
proper HTTP.

Options might be passed in as key/value pairs.  There are currently
only two options supported; C<laxed> and C<junk_out>.

The C<laxed> option will make C<read_response_headers> more forgiving
towards servers that have not learned how to speak HTTP properly.  The
<laxed> option is a boolean flag, and is enabled by passing in a TRUE
value.  The C<junk_out> option can be used to capture bad header lines
when C<laxed> is enabled.  The value should be an array reference.
Bad header lines will be pushed onto the array.

=item $n = $s->read_entity_body($buf, $size);

Reads chunks of the entity body content.  Basically the same interface
as for read() and sysread(), but buffer offset is not supported yet.
This method should only be called after a successful
read_response_headers() call.

The return value will be C<undef> on errors, 0 on EOF, -1 if no data
could be returned this time, and otherwise the number of bytes added
to $buf.

This method might raise exceptions (die) if the server does not speak
proper HTTP.

=item %headers = $s->get_trailers

After read_entity_body() has returned 0 to indicate end of the entity
body, you might call this method to pick up any trailers.

=item $s->_rbuf

Get/set the read buffer content.  The read_response_headers() and
read_entity_body() methods use an internal buffer which they will look
for data before they actually sysread more from the socket itself.  If
they read too much, the remaining data will be left in this buffer.

=item $s->_rbuf_length

Returns the number of bytes in the read buffer.

=back

=head1 SUBCLASSING

The read_response_headers() and read_entity_body() will invoke the
sysread() method when they need more data.  Subclasses might want to
override this method to contol how reading takes place.

The object itself is a glob.  Subclasses should avoid using hash key
names prefixed with C<http_> and C<io_>.

=head1 SEE ALSO

L<LWP>, L<IO::Socket::INET>, L<Net::HTTP::NB>

=head1 COPYRIGHT

Copyright 2001 Gisle Aas.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

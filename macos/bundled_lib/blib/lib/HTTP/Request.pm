#
# $Id: Request.pm,v 1.30 2001/11/15 06:42:40 gisle Exp $

package HTTP::Request;

=head1 NAME

HTTP::Request - Class encapsulating HTTP Requests

=head1 SYNOPSIS

 require HTTP::Request;
 $request = HTTP::Request->new(GET => 'http://www.oslo.net/');

=head1 DESCRIPTION

C<HTTP::Request> is a class encapsulating HTTP style requests,
consisting of a request line, some headers, and some (potentially empty)
content. Note that the LWP library also uses this HTTP style requests
for non-HTTP protocols.

Instances of this class are usually passed to the C<request()> method
of an C<LWP::UserAgent> object:

 $ua = LWP::UserAgent->new;
 $request = HTTP::Request->new(GET => 'http://www.oslo.net/');
 $response = $ua->request($request);

C<HTTP::Request> is a subclass of C<HTTP::Message> and therefore
inherits its methods.  The inherited methods most often used are header(),
push_header(), remove_header(), and content(). See L<HTTP::Message> for details.

The following additional methods are available:

=over 4

=cut

require HTTP::Message;
@ISA = qw(HTTP::Message);
$VERSION = sprintf("%d.%02d", q$Revision: 1.30 $ =~ /(\d+)\.(\d+)/);

use strict;

=item $r = HTTP::Request->new($method, $uri)

=item $r = HTTP::Request->new($method, $uri, $header)

=item $r = HTTP::Request->new($method, $uri, $header, $content)

Constructs a new C<HTTP::Request> object describing a request on the
object C<$uri> using method C<$method>.  The C<$uri> argument can be
either a string, or a reference to a C<URI> object.  The optional $header
argument should be a reference to an C<HTTP::Headers> object.
The optional $content argument should be a string.

=cut

sub new
{
    my($class, $method, $uri, $header, $content) = @_;
    my $self = $class->SUPER::new($header, $content);
    $self->method($method);
    $self->uri($uri);
    $self;
}


sub clone
{
    my $self = shift;
    my $clone = bless $self->SUPER::clone, ref($self);
    $clone->method($self->method);
    $clone->uri($self->uri);
    $clone;
}


=item $r->method([$val])

=item $r->uri([$val])

These methods provide public access to the attributes containing
respectively the method of the request and the URI object of the
request.

If an argument is given the attribute is given that as its new
value. If no argument is given the value is not touched. In either
case the previous value is returned.

The method() method argument should be a string.

The uri() method accept both a reference to a URI object and a
string as its argument.  If a string is given, then it should be
parseable as an absolute URI.

=cut

sub method  { shift->_elem('_method', @_); }

sub uri
{
    my $self = shift;
    my $old = $self->{'_uri'};
    if (@_) {
	my $uri = shift;
	if (!defined $uri) {
	    # that's ok
	} elsif (ref $uri) {
	    Carp::croak("A URI can't be a " . ref($uri) . " reference")
		if ref($uri) eq 'HASH' or ref($uri) eq 'ARRAY';
	    Carp::croak("Can't use a " . ref($uri) . " object as a URI")
		unless $uri->can('scheme');
	    $uri = $uri->clone;
	    unless ($HTTP::URI_CLASS eq "URI") {
		# Argh!! Hate this... old LWP legacy!
		eval { local $SIG{__DIE__}; $uri = $uri->abs; };
		die $@ if $@ && $@ !~ /Missing base argument/;
	    }
	} else {
	    $uri = $HTTP::URI_CLASS->new($uri);
	}
	$self->{'_uri'} = $uri;
    }
    $old;
}

*url = \&uri;  # this is the same for now

=item $r->as_string()

Method returning a textual representation of the request.
Mainly useful for debugging purposes. It takes no arguments.

=cut

sub as_string
{
    my $self = shift;
    my @result;
    #push(@result, "---- $self -----");
    my $req_line = $self->method || "[NO METHOD]";
    my $uri = $self->uri;
    $uri = (defined $uri) ? $uri->as_string : "[NO URI]";
    $req_line .= " $uri";
    my $proto = $self->protocol;
    $req_line .= " $proto" if $proto;

    push(@result, $req_line);
    push(@result, $self->headers_as_string);
    my $content = $self->content;
    if (defined $content) {
	push(@result, $content);
    }
    #push(@result, ("-" x 40));
    join("\n", @result, "");
}

1;

=back

=head1 SEE ALSO

L<HTTP::Headers>, L<HTTP::Message>, L<HTTP::Request::Common>

=head1 COPYRIGHT

Copyright 1995-2001 Gisle Aas.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

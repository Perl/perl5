package URI;  # $Date: 2001/04/23 22:45:48 $

use strict;
use vars qw($VERSION);
$VERSION = "1.12";

use vars qw($ABS_REMOTE_LEADING_DOTS $ABS_ALLOW_RELATIVE_SCHEME);

my %implements;  # mapping from scheme to implementor class

# Some "official" character classes

use vars qw($reserved $mark $unreserved $uric $scheme_re);
$reserved   = q(;/?:@&=+$,);
$mark       = q(-_.!~*'());                                    #'; emacs
$unreserved = "A-Za-z0-9\Q$mark\E";
$uric       = quotemeta($reserved) . $unreserved . "%";

$scheme_re  = '[a-zA-Z][a-zA-Z0-9.+\-]*';

use Carp ();
use URI::Escape ();

use overload ('""'     => sub { ${$_[0]} },
	      '=='     => sub { overload::StrVal($_[0]) eq
                                overload::StrVal($_[1])
                              },
              fallback => 1,
             );

sub new
{
    my($class, $uri, $scheme) = @_;

    $uri = defined ($uri) ? "$uri" : "";   # stringify
    # Get rid of potential wrapping
    $uri =~ s/^<(?:URL:)?(.*)>$/$1/;  # 
    $uri =~ s/^"(.*)"$/$1/;
    $uri =~ s/^\s+//;
    $uri =~ s/\s+$//;

    my $impclass;
    if ($uri =~ m/^($scheme_re):/so) {
	$scheme = $1;
    } else {
	if (($impclass = ref($scheme))) {
	    $scheme = $scheme->scheme;
	} elsif ($scheme && $scheme =~ m/^($scheme_re)(?::|$)/o) {
	    $scheme = $1;
        }
    }
    $impclass ||= implementor($scheme) ||
	do {
	    require URI::_foreign;
	    $impclass = 'URI::_foreign';
	};

    return $impclass->_init($uri, $scheme);
}


sub new_abs
{
    my($class, $uri, $base) = @_;
    $uri = $class->new($uri, $base);
    $uri->abs($base);
}


sub _init
{
    my $class = shift;
    my($str, $scheme) = @_;
    $str =~ s/([^$uric\#])/$URI::Escape::escapes{$1}/go;
    $str = "$scheme:$str" unless $str =~ /^$scheme_re:/o ||
                                 $class->_no_scheme_ok;
    my $self = bless \$str, $class;
    $self;
}


sub implementor
{
    my($scheme, $impclass) = @_;
    if (!$scheme || $scheme !~ /\A$scheme_re\z/o) {
	require URI::_generic;
	return "URI::_generic";
    }

    $scheme = lc($scheme);

    if ($impclass) {
	# Set the implementor class for a given scheme
        my $old = $implements{$scheme};
        $impclass->_init_implementor($scheme);
        $implements{$scheme} = $impclass;
        return $old;
    }

    my $ic = $implements{$scheme};
    return $ic if $ic;

    # scheme not yet known, look for internal or
    # preloaded (with 'use') implementation
    $ic = "URI::$scheme";  # default location

    # turn scheme into a valid perl identifier by a simple tranformation...
    $ic =~ s/\+/_P/g;
    $ic =~ s/\./_O/g;
    $ic =~ s/\-/_/g;

    no strict 'refs';
    # check we actually have one for the scheme:
    unless (@{"${ic}::ISA"}) {
        # Try to load it
        eval "require $ic";
        die $@ if $@ && $@ !~ /Can\'t locate.*in \@INC/;
        return unless @{"${ic}::ISA"};
    }

    $ic->_init_implementor($scheme);
    $implements{$scheme} = $ic;
    $ic;
}


sub _init_implementor
{
    my($class, $scheme) = @_;
    # Remember that one implementor class may actually
    # serve to implement several URI schemes.
}


sub clone
{
    my $self = shift;
    my $other = $$self;
    bless \$other, ref $self;
}


sub _no_scheme_ok { 0 }

sub _scheme
{
    my $self = shift;

    unless (@_) {
	return unless $$self =~ /^($scheme_re):/o;
	return $1;
    }

    my $old;
    my $new = shift;
    if (defined($new) && length($new)) {
	Carp::croak("Bad scheme '$new'") unless $new =~ /^$scheme_re$/o;
	$old = $1 if $$self =~ s/^($scheme_re)://o;
	my $newself = URI->new("$new:$$self");
	$$self = $$newself; 
	bless $self, ref($newself);
    } else {
	if ($self->_no_scheme_ok) {
	    $old = $1 if $$self =~ s/^($scheme_re)://o;
	    Carp::carp("Oops, opaque part now look like scheme")
		if $^W && $$self =~ m/^$scheme_re:/o
	} else {
	    $old = $1 if $$self =~ m/^($scheme_re):/o;
	}
    }

    return $old;
}

sub scheme
{
    my $scheme = shift->_scheme(@_);
    return unless defined $scheme;
    lc($scheme);
}


sub opaque
{
    my $self = shift;

    unless (@_) {
	$$self =~ /^(?:$scheme_re:)?([^\#]*)/o or die;
	return $1;
    }

    $$self =~ /^($scheme_re:)?    # optional scheme
	        ([^\#]*)          # opaque
                (\#.*)?           # optional fragment
              $/sx or die;

    my $old_scheme = $1;
    my $old_opaque = $2;
    my $old_frag   = $3;

    my $new_opaque = shift;
    $new_opaque = "" unless defined $new_opaque;
    $new_opaque =~ s/([^$uric])/$URI::Escape::escapes{$1}/go;

    $$self = defined($old_scheme) ? $old_scheme : "";
    $$self .= $new_opaque;
    $$self .= $old_frag if defined $old_frag;

    $old_opaque;
}

*path = \&opaque;  # alias


sub fragment
{
    my $self = shift;
    unless (@_) {
	return unless $$self =~ /\#(.*)/s;
	return $1;
    }

    my $old;
    $old = $1 if $$self =~ s/\#(.*)//s;

    my $new_frag = shift;
    if (defined $new_frag) {
	$new_frag =~ s/([^$uric])/$URI::Escape::escapes{$1}/go;
	$$self .= "#$new_frag";
    }
    $old;
}


sub as_string
{
    my $self = shift;
    $$self;
}


sub canonical
{
    my $self = shift;

    # Make sure scheme is lowercased
    my $scheme = $self->_scheme || "";
    my $uc_scheme = $scheme =~ /[A-Z]/;
    my $lc_esc    = $$self =~ /%(?:[a-f][a-fA-F0-9]|[A-F0-9][a-f])/;
    if ($uc_scheme || $lc_esc) {
	my $other = $self->clone;
	$other->_scheme(lc $scheme) if $uc_scheme;
	$$other =~ s/(%(?:[a-f][a-fA-F0-9]|[A-F0-9][a-f]))/uc($1)/ge
	    if $lc_esc;
	return $other;
    }
    $self;
}

# Compare two URIs, subclasses will provide a more correct implementation
sub eq {
    my($self, $other) = @_;
    $self  = URI->new($self, $other) unless ref $self;
    $other = URI->new($other, $self) unless ref $other;
    ref($self) eq ref($other) &&                # same class
	$self->canonical->as_string eq $other->canonical->as_string;
}

# generic-URI transformation methods
sub abs { $_[0]; }
sub rel { $_[0]; }

1;

__END__

=head1 NAME

URI - Uniform Resource Identifiers (absolute and relative)

=head1 SYNOPSIS

 $u1 = URI->new("http://www.perl.com");
 $u2 = URI->new("foo", "http");
 $u3 = $u2->abs($u1);
 $u4 = $u3->clone;
 $u5 = URI->new("HTTP://WWW.perl.com:80")->canonical;

 $str = $u->as_string;
 $str = "$u";

 $scheme = $u->scheme;
 $opaque = $u->opaque;
 $path   = $u->path;
 $frag   = $u->fragment;

 $u->scheme("ftp");
 $u->host("ftp.perl.com");
 $u->path("cpan/");

=head1 DESCRIPTION

This module implements the C<URI> class.  Objects of this class
represent "Uniform Resource Identifier references" as specified in RFC
2396.

A Uniform Resource Identifier is a compact string of characters for
identifying an abstract or physical resource.  A Uniform Resource
Identifier can be further classified either a Uniform Resource Locator
(URL) or a Uniform Resource Name (URN).  The distinction between URL
and URN does not matter to the C<URI> class interface. A
"URI-reference" is a URI that may have additional information attached
in the form of a fragment identifier.

An absolute URI reference consists of three parts.  A I<scheme>, a
I<scheme specific part> and a I<fragment> identifier.  A subset of URI
references share a common syntax for hierarchical namespaces.  For
these the scheme specific part is further broken down into
I<authority>, I<path> and I<query> components.  These URI can also
take the form of relative URI references, where the scheme (and
usually also the authority) component is missing, but implied by the
context of the URI reference.  The three forms of URI reference
syntax are summarized as follows:

  <scheme>:<scheme-specific-part>#<fragment>
  <scheme>://<authority><path>?<query>#<fragment>
  <path>?<query>#<fragment>

The components that a URI reference can be divided into depend on the
I<scheme>.  The C<URI> class provides methods to get and set the
individual components.  The methods available for a specific
C<URI> object depend on the scheme.

=head1 CONSTRUCTORS

The following methods construct new C<URI> objects:

=over 4

=item $uri = URI->new( $str, [$scheme] )

This class method constructs a new URI object.  The string
representation of a URI is given as argument together with an optional
scheme specification.  Common URI wrappers like "" and <>, as well as
leading and trailing white space, are automatically removed from
the $str argument before it is processed further.

The constructor determines the scheme, maps this to an appropriate
URI subclass, constructs a new object of that class and returns it.

The $scheme argument is only used when $str is a
relative URI.  It can either be a simple string that
denotes the scheme, a string containing an absolute URI reference or
an absolute C<URI> object.  If no $scheme is specified for a relative
URI $str, then $str is simply treated as a generic URI (no scheme
specific methods available).

The set of characters available for building URI references is
restricted (see L<URI::Escape>).  Characters outside this set are
automatically escaped by the URI constructor.

=item $uri = URI->new_abs( $str, $base_uri )

This constructs a new absolute URI object.  The $str argument can
denote a relative or absolute URI.  If relative, then it will be
absolutized using $base_uri as base. The $base_uri must be an absolute
URI.

=item $uri = URI::file->new( $filename, [$os] )

This constructs a new I<file> URI from a file name.  See L<URI::file>.

=item $uri = URI::file->new_abs( $filename, [$os] )

This constructs a new absolute I<file> URI from a file name.  See
L<URI::file>.

=item $uri = URI::file->cwd

This returns the current working directory as a I<file> URI.  See
L<URI::file>.

=item $uri->clone

This method returns a copy of the $uri.

=back

=head1 COMMON METHODS

The methods described in this section are available for all C<URI>
objects.

Methods that give access to components of a URI will always return the
old value of the component.  The value returned will be C<undef> if the
component was not present.  There is generally a difference between a
component that is empty (represented as C<"">) and a component that is
missing (represented as C<undef>).  If an accessor method is given an
argument it will update the corresponding component in addition to
returning the old value of the component.  Passing an undefined
argument will remove the component (if possible).  The description of
the various accessor methods will tell if the component is passed as
an escaped or an unescaped string.  Components that can be futher
divided into sub-parts are usually passed escaped, as unescaping might
change its semantics.

The common methods available for all URI are:

=over 4

=item $uri->scheme( [$new_scheme] )

This method sets and returns the scheme part of the $uri.  If the $uri is
relative, then $uri->scheme returns C<undef>.  If called with an
argument, it will update the scheme of $uri, possibly changing the
class of $uri, and return the old scheme value.  The method croaks
if the new scheme name is illegal; scheme names must begin with a
letter and must consist of only US-ASCII letters, numbers, and a few
special marks: ".", "+", "-".  This restriction effectively means
that scheme have to be passed unescaped.  Passing an undefined
argument to the scheme method will make the URI relative (if possible).

Letter case does not matter for scheme names.  The string
returned by $uri->scheme is always lowercase.  If you want the scheme
just as it was written in the URI in its original case,
you can use the $uri->_scheme method instead.

=item $uri->opaque( [$new_opaque] )

This method sets and returns the scheme specific part of the $uri 
(everything between the scheme and the fragment)
as an escaped string.

=item $uri->path( [$new_path] )

This method sets and returns the same value as $uri->opaque unless the URI
supports the generic syntax for hierarchical namespaces.
In that case the generic method is overridden to set and return
the part of the URI between the I<host name> and the I<fragment>.

=item $uri->fragment( [$new_frag] )

This method returns the fragment identifier of a URI reference
as an escaped string.

=item $uri->as_string

This method returns a URI object to a plain string.  URI objects are
also converted to plain strings automatically by overloading.  This
means that $uri objects can be used as plain strings in most Perl
constructs.

=item $uri->canonical

This method will return a normalized version of the URI.  The rules
for normalization are scheme dependent.  It usually involves
lowercasing of the scheme and the Internet host name components,
removing the explicit port specification if it matches the default port,
uppercasing all escape sequences, and unescaping octets that can be
better represented as plain characters.

For efficiency reasons, if the $uri already was in normalized form,
then a reference to it is returned instead of a copy.

=item $uri->eq( $other_uri )

=item URI::eq( $first_uri, $other_uri )

This method tests whether two URI references are equal.  URI references
that normalize to the same string are considered equal.  The method
can also be used as a plain function which can also test two string
arguments.

If you need to test whether two C<URI> object references denote the
same object, use the '==' operator.

=item $uri->abs( $base_uri )

This method returns an absolute URI reference.  If $uri already is
absolute, then a reference to it is simply returned.  If the $uri
is relative, then a new absolute URI is constructed by combining the
$uri and the $base_uri, and returned.

=item $uri->rel( $base_uri )

This method returns a relative URI reference if it is possible to
make one that denotes the same resource relative to $base_uri.
If not, then $uri is simply returned.

=back

=head1 GENERIC METHODS

The following methods are available to schemes that use the
common/generic syntax for hierarchical namespaces.  The description of
schemes below will tell which one these are.  Unknown schemes are
assumed to support the generic syntax, and therefore the following
methods:

=over 4

=item $uri->authority( [$new_authority] )

This method sets and returns the escaped authority component
of the $uri.

=item $uri->path( [$new_path] )

This method sets and returns the escaped path component of
the $uri (the part between the host name and the query or fragment).
The path will never be undefined, but it can be the empty string.

=item $uri->path_query( [$new_path_query] )

This method sets and returns the escaped path and query
components as a single entity.  The path and the query are
separated by a "?" character, but the query can itself contain "?".

=item $uri->path_segments( [$segment,...] )

This method sets and returns the path.  In scalar context it returns
the same value as $uri->path.  In list context it will return the
unescaped path segments that make up the path.  Path segments that
have parameters are returned as an anonymous array.  The first element
is the unescaped path segment proper.  Subsequent elements are escaped
parameter strings.  Such an anonymous array uses overloading so it can
be treated as a string too, but this string does not include the
parameters.

=item $uri->query( [$new_query] )

This method sets and returns the escaped query component of
the $uri.

=item $uri->query_form( [$key => $value,...] )

This method sets and returns query components that use the
I<application/x-www-form-urlencoded> format.  Key/value pairs are
separated by "&" and the key is separated from the value with a "="
character.

=item $uri->query_keywords( [$keywords,...] )

This method sets and returns query components that use the
keywords separated by "+" format.

=back

=head1 SERVER METHODS

Schemes where the I<authority> component denotes a Internet host will
have the following methods available in addition to the generic
methods.

=over 4

=item $uri->userinfo( [$new_userinfo] )

This method sets and returns the escaped userinfo part of the
authority componenent.

For some schemes this will be a user name and a password separated by
a colon.  This practice is not recommended. Embedding passwords in
clear text (such as URI) has proven to be a security risk in almost
every case where it has been used.

=item $uri->host( [$new_host] )

This method sets and returns the unescaped hostname.

If the $new_host string ends with a colon and a number, then this
number will also set the port.

=item $uri->port( [ $new_port] )

This method sets and returns the port.  The port is simple integer
that should be greater than 0.

If no explicit port is specified in the URI, then the default port of
the URI scheme is returned. If you don't want the default port
substituted, then you can use the $uri->_port method instead.

=item $uri->host_port( [ $new_host_port ] )

This method sets and returns the host and port as a single
unit.  The returned value will include a port, even if it matches the
default port.  The host part and the port part is separated with a
colon; ":".

=item $uri->default_port

This method returns the default port of the URI scheme that $uri
belongs to.  For I<http> this will be the number 80, for I<ftp> this
will be the number 21, etc.  The default port for a scheme can not be
changed.

=back

=head1 SCHEME SPECIFIC SUPPORT

The following URI schemes are specifically supported.  For C<URI>
objects not belonging to one of these you can only use the common and
generic methods.

=over 4

=item B<data>:

The I<data> URI scheme is specified in RFC 2397.  It allows inclusion
of small data items as "immediate" data, as if it had been included
externally.

C<URI> objects belonging to the data scheme support the common methods
and two new methods to access their scheme specific components;
$uri->media_type and $uri->data.  See L<URI::data> for details.

=item B<file>:

An old specification of the I<file> URI scheme is found in RFC 1738.
A new RFC 2396 based specification in not available yet, but file URI
references are in common use.

C<URI> objects belonging to the file scheme support the common and
generic methods.  In addition they provide two methods to map file URI
back to local file names; $uri->file and $uri->dir.  See L<URI::file>
for details.

=item B<ftp>:

An old specification of the I<ftp> URI scheme is found in RFC 1738.  A
new RFC 2396 based specification in not available yet, but ftp URI
references are in common use.

C<URI> objects belonging to the ftp scheme support the common,
generic and server methods.  In addition they provide two methods to
access the userinfo sub-components: $uri->user and $uri->password.

=item B<gopher>:

The I<gopher> URI scheme is specified in
<draft-murali-url-gopher-1996-12-04> and will hopefully be available
as a RFC 2396 based specification.

C<URI> objects belonging to the gopher scheme support the common,
generic and server methods. In addition they support some methods to
access gopher specific path components: $uri->gopher_type,
$uri->selector, $uri->search, $uri->string.

=item B<http>:

The I<http> URI scheme is specified in
<draft-ietf-http-v11-spec-rev-06> (which will become an RFC soon).
The scheme is used to reference resources hosted by HTTP servers.

C<URI> objects belonging to the http scheme support the common,
generic and server methods.

=item B<https>:

The I<https> URI scheme is a Netscape invention which is commonly
implemented.  The scheme is used to reference HTTP servers through SSL
connections.  It's syntax is the same as http, but the default
port is different.

=item B<ldap>:

The I<ldap> URI scheme is specified in RFC 2255.  LDAP is the
Lightweight Directory Access Protocol.  A ldap URI describes an LDAP
search operation to perform to retrieve information from an LDAP
directory.

C<URI> objects belonging to the ldap scheme support the common,
generic and server methods as well as specific ldap methods; $uri->dn,
$uri->attributes, $uri->scope, $uri->filter, $uri->extensions.  See
L<URI::ldap> for details.

=item B<mailto>:

The I<mailto> URI scheme is specified in RFC 2368.  The scheme was
originally used to designate the Internet mailing address of an
individual or service.  It has (in RFC 2368) been extended to allow
setting of other mail header fields and the message body.

C<URI> objects belonging to the mailto scheme support the common
methods and the generic query methods.  In addition they support the
following mailto specific methods: $uri->to, $uri->headers.

=item B<news>:

The I<news>, I<nntp> and I<snews> URI schemes are specified in
<draft-gilman-news-url-01> and will hopefully be available as a RFC
2396 based specification soon.

C<URI> objects belonging to the news scheme support the common,
generic and server methods.  In addition they provide some methods to
access the path: $uri->group and $uri->message.

=item B<nntp>:

See I<news> scheme.

=item B<pop>:

The I<pop> URI scheme is specified in RFC 2384. The scheme is used to
reference a POP3 mailbox.

C<URI> objects belonging to the pop scheme support the common, generic
and server methods.  In addition they provide two methods to access the
userinfo components: $uri->user and $uri->auth

=item B<rlogin>:

An old speficication of the I<rlogin> URI scheme is found in RFC
1738. C<URI> objects belonging to the rlogin scheme support the
common, generic and server methods.

=item B<rsync>:

Information about rsync is available from http://rsync.samba.org.
C<URI> objects belonging to the rsync scheme support the common,
generic and server methods.  In addition they provide methods to
access the userinfo sub-components: $uri->user and $uri->password.

=item B<snews>:

See I<news> scheme.  It's syntax is the same as news, but the default
port is different.

=item B<telnet>:

An old speficication of the I<telnet> URI scheme is found in RFC
1738. C<URI> objects belonging to the telnet scheme support the
common, generic and server methods.

=back


=head1 CONFIGURATION VARIABLES

The following configuration variables influence how the class and it's
methods behave:

=over 4

=item $URI::ABS_ALLOW_RELATIVE_SCHEME

Some older parsers used to allow the scheme name to be present in the
relative URL if it was the same as the base URL scheme.  RFC 2396 says
that this should be avoided, but you can enable this old behaviour by
setting the $URI::ABS_ALLOW_RELATIVE_SCHEME variable to a TRUE value.
The difference is demonstrated by the following examples:

  URI->new("http:foo")->abs("http://host/a/b")
      ==>  "http:foo"

  local $URI::ABS_ALLOW_RELATIVE_SCHEME = 1;
  URI->new("http:foo")->abs("http://host/a/b")
      ==>  "http:/host/a/foo"


=item $URI::ABS_REMOTE_LEADING_DOTS

You can also have the abs() method ignore excess ".."
segments in the relative URI by setting $URI::ABS_REMOTE_LEADING_DOTS
to a TRUE value.  The difference is demonstrated by the following
examples:

  URI->new("../../../foo")->abs("http://host/a/b")
      ==> "http://host/../../foo"

  local $URI::URL::ABS_REMOTE_LEADING_DOTS = 1;
  URI->new("../../../foo")->abs("http://host/a/b")
      ==> "http://host/foo"

=back

=head1 BUGS

Using regexp variables like $1 directly as argument to the URI methods
do not work too well with current perl implementations.  I would argue
that this is actually a bug in perl.  The workaround is to quote
them. E.g.:

   /(...)/ || die;
   $u->query("$1");

=head1 SEE ALSO

L<URI::file>, L<URI::WithBase>, L<URI::Escape>, L<URI::Heuristic>

RFC 2396: "Uniform Resource Identifiers (URI): Generic Syntax",
Berners-Lee, Fielding, Masinter, August 1998.

=head1 COPYRIGHT

Copyright 1995-2001 Gisle Aas.

Copyright 1995 Martijn Koster.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS / ACKNOWLEDGMENTS

This module is based on the C<URI::URL> module, which in turn was
(distantly) based on the C<wwwurl.pl> code in the libwww-perl for
perl4 developed by Roy Fielding, as part of the Arcadia project at the
University of California, Irvine, with contributions from Brooks
Cutter.

C<URI::URL> was developed by Gisle Aas, Tim Bunce, Roy Fielding and
Martijn Koster with input from other people on the libwww-perl mailing
list.

C<URI> and related subclasses was developed by Gisle Aas.

=cut

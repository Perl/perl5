# Copyright (c) 1998 Graham Barr <gbarr@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package URI::ldap;

use strict;

use vars qw(@ISA $VERSION);
$VERSION = "1.10";

require URI::_server;
@ISA=qw(URI::_server);

use URI::Escape qw(uri_unescape);


sub default_port { 389 }

sub _ldap_elem {
  my $self  = shift;
  my $elem  = shift;
  my $query = $self->query;
  my @bits  = (split(/\?/,defined($query) ? $query : ""),("")x4);
  my $old   = $bits[$elem];

  if (@_) {
    my $new = shift;
    $new =~ s/\?/%3F/g;
    $bits[$elem] = $new;
    $query = join("?",@bits);
    $query =~ s/\?+$//;
    $query = undef unless length($query);
    $self->query($query);
  }

  $old;
}

sub dn {
  my $old = shift->path(@_);
  $old =~ s:^/::;
  uri_unescape($old);
}

sub attributes {
  my $self = shift;
  my $old = _ldap_elem($self,0, @_ ? join(",", map { my $tmp = $_; $tmp =~ s/,/%2C/g; $tmp } @_) : ());
  return $old unless wantarray;
  map { uri_unescape($_) } split(/,/,$old);
}

sub _scope {
  my $self = shift;
  my $old = _ldap_elem($self,1, @_);
  return unless defined wantarray && defined $old;
  uri_unescape($old);
}

sub scope {
  my $old = &_scope;
  $old = "base" unless length $old;
  $old;
}

sub _filter {
  my $self = shift;
  my $old = _ldap_elem($self,2, @_);
  return unless defined wantarray && defined $old;
  uri_unescape($old); # || "(objectClass=*)";
}

sub filter {
  my $old = &_filter;
  $old = "(objectClass=*)" unless length $old;
  $old;
}

sub extensions {
  my $self = shift;
  my @ext;
  while (@_) {
    my $key = shift;
    my $value = shift;
    push(@ext, join("=", map { $_="" unless defined; s/,/%2C/g; $_ } $key, $value));
  }
  @ext = join(",", @ext) if @ext;
  my $old = _ldap_elem($self,3, @ext);
  return $old unless wantarray;
  map { uri_unescape($_) } map { /^([^=]+)=(.*)$/ } split(/,/,$old);
}

sub canonical
{
    my $self = shift;
    my $other = $self->SUPER::canonical;

    # The stuff below is not as efficient as one might hope...

    $other = $other->clone if $other == $self;

    $other->dn(_normalize_dn($other->dn));

    # Should really know about mixed case "postalAddress", etc...
    $other->attributes(map lc, $other->attributes);

    # Lowecase scope, remove default
    my $old_scope = $other->scope;
    my $new_scope = lc($old_scope);
    $new_scope = "" if $new_scope eq "base";
    $other->scope($new_scope) if $new_scope ne $old_scope;

    # Remove filter if default
    my $old_filter = $other->filter;
    $other->filter("") if lc($old_filter) eq "(objectclass=*)" ||
	                  lc($old_filter) eq "objectclass=*";

    # Lowercase extensions types and deal with known extension values
    my @ext = $other->extensions;
    for (my $i = 0; $i < @ext; $i += 2) {
	my $etype = $ext[$i] = lc($ext[$i]);
	if ($etype =~ /^!?bindname$/) {
	    $ext[$i+1] = _normalize_dn($ext[$i+1]);
	}
    }
    $other->extensions(@ext) if @ext;
    
    $other;
}

sub _normalize_dn  # RFC 2253
{
    my $dn = shift;

    return $dn;
    # The code below will fail if the "+" or "," is embedding in a quoted
    # string or simply escaped...

    my @dn = split(/([+,])/, $dn);
    for (@dn) {
	s/^([a-zA-Z]+=)/lc($1)/e;
    }
    join("", @dn);
}

1;

__END__

=head1 NAME

URI::ldap - LDAP Uniform Resource Locators

=head1 SYNOPSIS

  use URI;

  $uri = URI->new("ldap:$uri_string");
  $dn     = $uri->dn;
  $filter = $uri->filter;
  @attr   = $uri->attributes;
  $scope  = $uri->scope;
  %extn   = $uri->extensions;
  
  $uri = URI->new("ldap:");  # start empty
  $uri->host("ldap.itd.umich.edu");
  $uri->dn("o=University of Michigan,c=US");
  $uri->attributes(qw(postalAddress));
  $uri->scope('sub');
  $uri->filter('(cn=Babs Jensen)');
  print $uri->as_string,"\n";

=head1 DESCRIPTION

C<URI::ldap> provides an interface to parse an LDAP URI in its
constituent parts and also build a URI as described in
RFC 2255.

=head1 METHODS

C<URI::ldap> support all the generic and server methods defined by
L<URI>, plus the following.

Each of the following methods can be used to set or get the value in
the URI. The values are passed in unescaped form.  None of these will
return undefined values, but elements without a default can be empty.
If arguments are given then a new value will be set for the given part
of the URI.

=over 4

=item $uri->dn( [$new_dn] )

Set or get the I<Distinguised Name> part of the URI.  The DN
identifies the base object of the LDAP search.

=item $uri->attributes( [@new_attrs] )

Set or get the list of attribute names which will be
returned by the search.

=item $uri->scope( [$new_scope] )

Set or get the scope that the search will use. The value can be one of
C<"base">, C<"one"> or C<"sub">. If none is given in the URI then the
return value will default to C<"base">.

=item $uri->_scope( [$new_scope] )

Same as scope(), but does not default to anything.

=item $uri->filter( [$new_filter] )

Set or get the filter that the search will use. If none is given in
the URI then the return value will default to C<"(objectClass=*)">.

=item $uri->_filter( [$new_filter] )

Same as filter(), but does not default to anything.

=item $uri->extensions( [$etype => $evalue,...] )

Set or get the extensions used for the search. The list passed should
be in the form etype1 => evalue1, etype2 => evalue2,... This is also
the form of list that will be returned.

=back

=head1 SEE ALSO

L<RFC-2255|http://www.cis.ohio-state.edu/htbin/rfc/rfc2255.html>

=head1 AUTHOR

Graham Barr E<lt>F<gbarr@pobox.com>E<gt>

Slightly modified by Gisle Aas to fit into the URI distribution.

=head1 COPYRIGHT

Copyright (c) 1998 Graham Barr. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

package URI::WithBase;

use strict;
use vars qw($AUTOLOAD);
use URI;

use overload '""' => "as_string", fallback => 1;

sub as_string;  # help overload find it

sub new
{
    my($class, $uri, $base) = @_;
    my $ibase = $base;
    if ($base && ref($base) && UNIVERSAL::isa($base, "URI::WithBase")) {
	$base = $base->abs;
	$ibase = $base->[0];
    }
    bless [URI->new($uri, $ibase), $base], $class;
}

sub new_abs
{
    my $class = shift;
    my $self = $class->new(@_);
    $self->abs;
}

sub _init
{
    my $class = shift;
    my($str, $scheme) = @_;
    bless [URI->new($str, $scheme), undef], $class;
}

sub eq
{
    my($self, $other) = @_;
    $other = $other->[0] if UNIVERSAL::isa($other, "URI::WithBase");
    $self->[0]->eq($other);
}

sub AUTOLOAD
{
    my $self = shift;
    my $method = substr($AUTOLOAD, rindex($AUTOLOAD, '::')+2);
    return if $method eq "DESTROY";
    $self->[0]->$method(@_);
}

sub can {                                  # override UNIVERSAL::can
    my $self = shift;
    $self->SUPER::can(@_) || (
      ref($self)
      ? $self->[0]->can(@_)
      : undef
    )
}

sub base {
    my $self = shift;
    my $base  = $self->[1];

    if (@_) { # set
	my $new_base = shift;
	$new_base = $new_base->abs if ref($new_base);  # ensure absoluteness
	$self->[1] = $new_base;
    }
    return unless defined wantarray;

    # The base attribute supports 'lazy' conversion from URL strings
    # to URL objects. Strings may be stored but when a string is
    # fetched it will automatically be converted to a URL object.
    # The main benefit is to make it much cheaper to say:
    #   URI::WithBase->new($random_url_string, 'http:')
    if (defined($base) && !ref($base)) {
	$base = URI->new($base);
	$self->[1] = $base unless @_;
    }
    $base;
}

sub clone
{
    my $self = shift;
    my $base = $self->[1];
    $base = $base->clone if ref($base);
    bless [$self->[0]->clone, $base], ref($self);
}

sub abs
{
    my $self = shift;
    my $base = shift || $self->base || return $self->clone;
    bless [$self->[0]->abs($base, @_), $base], ref($self);
}

sub rel
{
    my $self = shift;
    my $base = shift || $self->base || return $self->clone;
    bless [$self->[0]->rel($base, @_), $base], ref($self);
}

1;

__END__

=head1 NAME

URI::WithBase - URI which remember their base

=head1 SYNOPSIS

 $u1 = URI::WithBase->new($str, $base);
 $u2 = $u1->abs;

 $base = $u1->base;
 $u1->base( $new_base )

=head1 DESCRIPTION

This module provide the C<URI::WithBase> class.  Objects of this class
are like C<URI> objects, but can keep their base too.

The methods provided in addition to or modified from those of C<URI> are:

=over 4

=item $uri = URI::WithBase->new($str, [$base])

The constructor takes a an optional base URI as the second argument.

=item $uri->base( [$new_base] )

This method can be used to get or set the value of the base attribute.

=item $uri->abs( [$base_uri] )

The $base_uri argument is now made optional as the object carries it's
base with it.

=item $uri->rel( [$base_uri] )

The $base_uri argument is now made optional as the object carries it's
base with it.

=back


=head1 SEE ALSO

L<URI>

=head1 COPYRIGHT

Copyright 1998-2000 Gisle Aas.

=cut

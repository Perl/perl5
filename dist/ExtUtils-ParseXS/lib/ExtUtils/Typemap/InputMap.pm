package ExtUtils::Typemap::InputMap;
use 5.006001;
use strict;
use warnings;
our $VERSION = '0.05';
use Carp qw(croak);

=head1 NAME

ExtUtils::Typemap::InputMap - Entry in the INPUT section of a typemap

=head1 SYNOPSIS

  use ExtUtils::Typemap;
  ...
  my $input = $typemap->get_input_map('T_NV');
  my $code = $input->code();
  $input->code("...");

=head1 DESCRIPTION

Refer to L<ExtUtils::Typemap> for details.

=head1 METHODS

=cut

=head2 new

Requires C<xstype> and C<code> parameters.

=cut

sub new {
  my $prot = shift;
  my $class = ref($prot)||$prot;
  my %args = @_;

  if (!ref($prot)) {
    if (not defined $args{xstype} or not defined $args{code}) {
      croak("Need xstype and code parameters");
    }
  }

  my $self = bless(
    (ref($prot) ? {%$prot} : {})
    => $class
  );

  $self->{xstype} = $args{xstype} if defined $args{xstype};
  $self->{code} = $args{code} if defined $args{code};
  $self->{code} =~ s/^(?=\S)/\t/mg;

  return $self;
}

=head2 code

Returns or sets the INPUT mapping code for this entry.

=cut

sub code {
  $_[0]->{code} = $_[1] if @_ > 1;
  return $_[0]->{code};
}

=head2 xstype

Returns the name of the XS type of the INPUT map.

=cut

sub xstype {
  return $_[0]->{xstype};
}

=head1 SEE ALSO

L<ExtUtils::Typemap>

=head1 AUTHOR

Steffen Mueller C<<smueller@cpan.org>>

=head1 COPYRIGHT & LICENSE

Copyright 2009-2010 Steffen Mueller

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;


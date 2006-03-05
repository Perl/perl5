package Module::Build::Platform::Unix;

use strict;
use Module::Build::Base;

use vars qw(@ISA);
@ISA = qw(Module::Build::Base);

sub make_tarball {
  my $self = shift;
  $self->{args}{tar}  ||= ['tar'];
  $self->{args}{gzip} ||= ['gzip'];
  $self->SUPER::make_tarball(@_);
}

sub _startperl { "#! " . shift()->perl }

sub _construct {
  my $self = shift()->SUPER::_construct(@_);

  # perl 5.8.1-RC[1-3] had some broken %Config entries, and
  # unfortunately Red Hat 9 shipped it like that.  Fix 'em up here.
  my $c = $self->{config};
  for (qw(siteman1 siteman3 vendorman1 vendorman3)) {
    $c->{"install${_}dir"} ||= $c->{"install${_}"};
  }

  return $self;
}

1;
__END__


=head1 NAME

Module::Build::Platform::Unix - Builder class for Unix platforms

=head1 DESCRIPTION

The sole purpose of this module is to inherit from
C<Module::Build::Base>.  Please see the L<Module::Build> for the docs.

=head1 AUTHOR

Ken Williams <ken@cpan.org>

=head1 SEE ALSO

perl(1), Module::Build(3), ExtUtils::MakeMaker(3)

=cut

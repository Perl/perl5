use 5.006;
use strict;
use warnings;
package CPAN::Meta::Feature;
our $VERSION = '2.131560'; # VERSION

use CPAN::Meta::Prereqs;


sub new {
  my ($class, $identifier, $spec) = @_;

  my %guts = (
    identifier  => $identifier,
    description => $spec->{description},
    prereqs     => CPAN::Meta::Prereqs->new($spec->{prereqs}),
  );

  bless \%guts => $class;
}


sub identifier  { $_[0]{identifier}  }


sub description { $_[0]{description} }


sub prereqs     { $_[0]{prereqs} }

1;

# ABSTRACT: an optional feature provided by a CPAN distribution

__END__

=pod

=encoding utf-8

=head1 NAME

CPAN::Meta::Feature - an optional feature provided by a CPAN distribution

=head1 VERSION

version 2.131560

=head1 DESCRIPTION

A CPAN::Meta::Feature object describes an optional feature offered by a CPAN
distribution and specified in the distribution's F<META.json> (or F<META.yml>)
file.

For the most part, this class will only be used when operating on the result of
the C<feature> or C<features> methods on a L<CPAN::Meta> object.

=head1 METHODS

=head2 new

  my $feature = CPAN::Meta::Feature->new( $identifier => \%spec );

This returns a new Feature object.  The C<%spec> argument to the constructor
should be the same as the value of the C<optional_feature> entry in the
distmeta.  It must contain entries for C<description> and C<prereqs>.

=head2 identifier

This method returns the feature's identifier.

=head2 description

This method returns the feature's long description.

=head2 prereqs

This method returns the feature's prerequisites as a L<CPAN::Meta::Prereqs>
object.

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.
Bugs can be submitted through the web interface at
L<http://rt.cpan.org/Dist/Display.html?Queue=CPAN-Meta>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 CONTRIBUTORS

=over 4

=item *

Ansgar Burchardt <ansgar@cpan.org>

=item *

Avar Arnfjord Bjarmason <avar@cpan.org>

=item *

Christopher J. Madsen <cjm@cpan.org>

=item *

Cory G Watson <gphat@cpan.org>

=item *

Damyan Ivanov <dam@cpan.org>

=item *

Eric Wilhelm <ewilhelm@cpan.org>

=item *

Gregor Hermann <gregoa@debian.org>

=item *

Ken Williams <kwilliams@cpan.org>

=item *

Kenichi Ishigaki <ishigaki@cpan.org>

=item *

Lars Dieckow <daxim@cpan.org>

=item *

Leon Timmermans <leont@cpan.org>

=item *

Mark Fowler <markf@cpan.org>

=item *

Michael G. Schwern <mschwern@cpan.org>

=item *

Randy Sims <randys@thepierianspring.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by David Golden and Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

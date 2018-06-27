package Test2::Event::TAP::Version;
use strict;
use warnings;

our $VERSION = '1.302073';

BEGIN { require Test2::Event; our @ISA = qw(Test2::Event) }
use Test2::Util::HashBase qw/version/;

sub init {
    my $self = shift;
    defined $self->{+VERSION} or $self->trace->throw("'version' is a required attribute");
}

sub summary { 'TAP version ' . $_[0]->{+VERSION} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Event::TAP::Version - Event for TAP version.

=head1 DESCRIPTION

This event is used if a TAP formatter wishes to set a version.

=head1 SYNOPSIS

    use Test2::API qw/context/;
    use Test2::Event::Encoding;

    my $ctx = context();
    my $event = $ctx->send_event('TAP::Version', version => 42);

=head1 METHODS

Inherits from L<Test2::Event>. Also defines:

=over 4

=item $version = $e->version

The TAP version being parsed.

=back

=head1 SOURCE

The source code repository for Test2 can be found at
F<http://github.com/Test-More/test-more/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2016 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut

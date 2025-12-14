package Test2::V1::Handle;
use strict;
use warnings;

our $VERSION = '1.302219';

sub DEFAULT_HANDLE_BASE { 'Test2::V1::Base' }

use parent 'Test2::Handle';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::V1::Handle - V1 subclass of L<Test2::Handle>.

=head1 DESCRIPTION

The L<Test2::V1> subclass of the L<Test2::Handle> object. This is what you
interact with when you use the C<T2()> function in a test.

=head1 SYNOPSIS

    use Test2::V1::Handle;

    my $t2 = Test2::V1::Handle->new();

    $t2->ok(1, "Passing test");

=head1 SUBCLASS OVERRIDES

The default base class used is L<Test2::V1::Base>.

=head1 SEE ALSO

See L<Test2::Handle> for more information.

=head1 SOURCE

The source code repository for Test2-Suite can be found at
F<https://github.com/Test-More/test-more/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut

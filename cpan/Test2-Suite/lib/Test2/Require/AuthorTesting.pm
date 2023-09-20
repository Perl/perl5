package Test2::Require::AuthorTesting;
use strict;
use warnings;

use base 'Test2::Require';

our $VERSION = '0.000156';

sub skip {
    my $class = shift;
    return undef if $ENV{'AUTHOR_TESTING'};
    return 'Author test, set the $AUTHOR_TESTING environment variable to run it';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Require::AuthorTesting - Only run a test when the AUTHOR_TESTING
environment variable is set.

=head1 DESCRIPTION

It is common practice to write tests that are only run when the AUTHOR_TESTING
environment variable is set. This module automates the (admittedly trivial) work
of creating such a test.

=head1 SYNOPSIS

    use Test2::Require::AuthorTesting;

    ...

    done_testing;

=head1 SOURCE

The source code repository for Test2-Suite can be found at
F<https://github.com/Test-More/Test2-Suite/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2018 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut

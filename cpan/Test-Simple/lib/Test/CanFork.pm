package Test::CanFork;
use strict;
use warnings;

use Config;

my $Can_Fork = $Config{d_fork}
    || (($^O eq 'MSWin32' || $^O eq 'NetWare')
    and $Config{useithreads}
    and $Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/);

sub import {
    my $class = shift;

    if (!$Can_Fork) {
        require Test::More;
        Test::More::plan(skip_all => "This system cannot fork");
    }

    if ($^O eq 'MSWin32' && $] == 5.010000) {
        require Test::More;
        Test::More::plan('skip_all' => "5.10 has fork/threading issues that break fork on win32");
    }

    for my $var (@_) {
        next if $ENV{$var};

        require Test::More;
        Test::More::plan(skip_all => "This forking test will only run when the '$var' environment variable is set.");
    }
}

1;

__END__

=head1 NAME

Test::CanFork - Only run tests when forking is supported, optionally conditioned on ENV vars.

=head1 DESCRIPTION

Use this first thing in a test that should be skipped when forking is not
supported. You can also specify that the test should be skipped when specific
environment variables are not set.

=head1 SYNOPSYS

Skip the test if forking is unsupported:

    use Test::CanFork;
    use Test::More;
    ...

Skip the test if forking is unsupported, or any of the specified env vars are
not set:

    use Test::CanFork qw/AUTHOR_TESTING RUN_PROBLEMATIC_TESTS .../;
    use Test::More;
    ...

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 MAINTAINER

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut

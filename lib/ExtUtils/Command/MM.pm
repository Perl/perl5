package ExtUtils::Command::MM;

use strict;

require 5.006;
require Exporter;
use vars qw($VERSION @ISA @EXPORT);
@ISA = qw(Exporter);

@EXPORT = qw(test_harness);
$VERSION = '0.01';

=head1 NAME

ExtUtils::Command::MM - Commands for the MM's to use in Makefiles

=head1 SYNOPSIS

  perl -MExtUtils::Command::MM -e "function" files...


=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY!>  The interface is not stable.

ExtUtils::Command::MM encapsulates code which would otherwise have to
be done with large "one" liners.

They all read their input from @ARGV unless otherwise noted.

Any $(FOO) used in the examples are make variables, not Perl.

=over 4

=item B<test_harness>

  perl -MExtUtils::Command::MM -e "test_harness($(TEST_VERBOSE))" t/*.t

Runs the given tests via Test::Harness.  Will exit with non-zero if
the test fails.

Typically used with t/*.t files.

=cut

sub test_harness {
    require Test::Harness;
    $Test::Harness::verbose = shift;
    Test::Harness::runtests(@ARGV);
}

=back

=cut

1;

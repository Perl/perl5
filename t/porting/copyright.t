#!perl

=head1 NAME

copyright.t

=head1 DESCRIPTION

Tests that the latest copyright years in the top-level README file and the
C<perl -v> output match each other.

If the test fails, update at least one of README and perl.c so that they match
reality.

=cut


use TestInit;
use strict;
BEGIN { require 'test.pl' }


my $readme_year = readme_year();
my $v_year = v_year();
is $readme_year, $v_year, 'README and perl -v copyright dates match';

done_testing;


sub readme_year
# returns the latest copyright year from the top-level README file
{

  open my $readme, '<', '../README' or die "Opening README failed: $!";

  # The copyright message is the first paragraph:
  local $/ = '';
  my $copyright_msg = <$readme>;

  my ($year) = $copyright_msg =~ /.*\b(\d{4,})/s
      or die "Year not found in README copyright message '$copyright_msg'";

  $year;
}


sub v_year
# returns the latest copyright year shown in perl -v
{

  my $output = runperl switches => ['-v'];
  my ($year) = $output =~ /copyright 1987.*\b(\d{4,})/i
      or die "Copyright statement not found in perl -v output '$output'";

  $year;
}

package ExtUtils::ParseXS::Utilities;
use strict;
use warnings;
use Exporter;
use File::Spec;
use lib qw( lib );
use ExtUtils::ParseXS::Constants ();
our (@ISA, @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(
  standard_typemap_locations
  trim_whitespace
  tidy_type
  C_string
  valid_proto_string
);

=head1 NAME

ExtUtils::ParseXS::Utilities - Subroutines used with ExtUtils::ParseXS

=head1 SYNOPSIS

  use ExtUtils::ParseXS::Utilities qw(
    standard_typemap_locations
    trim_whitespace
    tidy_type
  );

=head1 SUBROUTINES

The following functions are not considered to be part of the public interface.
They are documented here for the benefit of future maintainers of this module.

=head2 C<standard_typemap_locations()>

=over 4

=item * Purpose

Provide a list of filepaths where F<typemap> files may be found.  The
filepaths -- relative paths to files (not just directory paths) -- appear in this list in lowest-to-highest priority.

The highest priority is to look in the current directory.  

  'typemap'

The second and third highest priorities are to look in the parent of the
current directory and a directory called F<lib/ExtUtils> underneath the parent
directory.

  '../typemap',
  '../lib/ExtUtils/typemap',

The fourth through ninth highest priorities are to look in the corresponding
grandparent, great-grandparent and great-great-grandparent directories.

  '../../typemap',
  '../../lib/ExtUtils/typemap',
  '../../../typemap',
  '../../../lib/ExtUtils/typemap',
  '../../../../typemap',
  '../../../../lib/ExtUtils/typemap',

The tenth and subsequent priorities are to look in directories named
F<ExtUtils> which are subdirectories of directories found in C<@INC> --
I<provided> a file named F<typemap> actually exists in such a directory.
Example:

  '/usr/local/lib/perl5/5.10.1/ExtUtils/typemap',

However, these filepaths appear in the list returned by
C<standard_typemap_locations()> in reverse order, I<i.e.>, lowest-to-highest.

  '/usr/local/lib/perl5/5.10.1/ExtUtils/typemap',
  '../../../../lib/ExtUtils/typemap',
  '../../../../typemap',
  '../../../lib/ExtUtils/typemap',
  '../../../typemap',
  '../../lib/ExtUtils/typemap',
  '../../typemap',
  '../lib/ExtUtils/typemap',
  '../typemap',
  'typemap'

=item * Arguments

  my @stl = standard_typemap_locations( \@INC );

Reference to C<@INC>.

=item * Return Value

Array holding list of directories to be searched for F<typemap> files.

=back

=cut

sub standard_typemap_locations {
  my $include_ref = shift;
  my @tm = qw(typemap);

  my $updir = File::Spec->updir();
  foreach my $dir (
      File::Spec->catdir(($updir) x 1),
      File::Spec->catdir(($updir) x 2),
      File::Spec->catdir(($updir) x 3),
      File::Spec->catdir(($updir) x 4),
  ) {
    unshift @tm, File::Spec->catfile($dir, 'typemap');
    unshift @tm, File::Spec->catfile($dir, lib => ExtUtils => 'typemap');
  }
  foreach my $dir (@{ $include_ref}) {
    my $file = File::Spec->catfile($dir, ExtUtils => 'typemap');
    unshift @tm, $file if -e $file;
  }
  return @tm;
}

=head2 C<trim_whitespace()>

=over 4

=item * Purpose

Perform an in-place trimming of leading and trailing whitespace from the
first argument provided to the function.

=item * Argument

  trim_whitespace($arg);

=item * Return Value

None.  Remember:  this is an I<in-place> modification of the argument.

=back

=cut

sub trim_whitespace {
  $_[0] =~ s/^\s+|\s+$//go;
}

=head2 C<tidy_type()>

=over 4

=item * Purpose

Rationalize any asterisks (C<*>) by joining them into bunches, removing
interior whitespace, then trimming leading and trailing whitespace.

=item * Arguments

    ($ret_type) = tidy_type($_);

String to be cleaned up.

=item * Return Value

String cleaned up.

=back

=cut

sub tidy_type {
  local ($_) = @_;

  # rationalise any '*' by joining them into bunches and removing whitespace
  s#\s*(\*+)\s*#$1#g;
  s#(\*+)# $1 #g;

  # change multiple whitespace into a single space
  s/\s+/ /g;

  # trim leading & trailing whitespace
  trim_whitespace($_);

  $_;
}

=head2 C<C_string()>

=over 4

=item * Purpose

Escape backslashes (C<\>) in prototype strings.

=item * Arguments

      $ProtoThisXSUB = C_string($_);

String needing escaping.

=item * Return Value

Properly escaped string.

=back

=cut

sub C_string {
  my($string) = @_;

  $string =~ s[\\][\\\\]g;
  $string;
}

=head2 C<valid_proto_string()>

=over 4

=item * Purpose

Validate prototype string.

=item * Arguments

String needing checking.

=item * Return Value

Upon success, returns the same string passed as argument.

Upon failure, returns C<0>.

=back

=cut

sub valid_proto_string {
  my($string) = @_;

  if ( $string =~ /^$ExtUtils::ParseXS::Constants::proto_re+$/ ) {
    return $string;
  }

  return 0;
}
1;

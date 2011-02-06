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
  process_typemaps
  process_single_typemap
  make_targetable
  map_type
);

=head1 NAME

ExtUtils::ParseXS::Utilities - Subroutines used with ExtUtils::ParseXS

=head1 SYNOPSIS

  use ExtUtils::ParseXS::Utilities qw(
    standard_typemap_locations
    trim_whitespace
    tidy_type
    C_string
    valid_proto_string
    process_typemaps
    make_targetable
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

=head2 C<process_typemaps()>

=over 4

=item * Purpose

Process all typemap files.

=item * Arguments

  my ($type_kind_ref, $proto_letter_ref, $input_expr_ref, $output_expr_ref) =
    process_typemaps( $args{typemap}, $pwd );
      
List of two elements:  C<typemap> element from C<%args>; current working
directory.

=item * Return Value

Upon success, returns a list of four hash references.  (This will probably be
refactored.)

=back

=cut

sub process_typemaps {
  my ($tmap, $pwd) = @_;

  my @tm = ref $tmap ? @{$tmap} : ($tmap);

  foreach my $typemap (@tm) {
    die "Can't find $typemap in $pwd\n" unless -r $typemap;
  }

  push @tm, standard_typemap_locations( \@INC );

  my ($type_kind_ref, $proto_letter_ref, $input_expr_ref, $output_expr_ref)
    = ( {}, {}, {}, {} );

  foreach my $typemap (@tm) {
    next unless -f $typemap;
    # skip directories, binary files etc.
    warn("Warning: ignoring non-text typemap file '$typemap'\n"), next
      unless -T $typemap;
    ($type_kind_ref, $proto_letter_ref, $input_expr_ref, $output_expr_ref) =
      process_single_typemap( $typemap,
        $type_kind_ref, $proto_letter_ref, $input_expr_ref, $output_expr_ref);
  }
  return ($type_kind_ref, $proto_letter_ref, $input_expr_ref, $output_expr_ref);
}

sub process_single_typemap {
  my ($typemap,
    $type_kind_ref, $proto_letter_ref, $input_expr_ref, $output_expr_ref) = @_;
  open my $TYPEMAP, '<', $typemap
    or warn ("Warning: could not open typemap file '$typemap': $!\n"), next;
  my $mode = 'Typemap';
  my $junk = "";
  my $current = \$junk;
  while (<$TYPEMAP>) {
    # skip comments
    next if /^\s*#/;
    if (/^INPUT\s*$/) {
      $mode = 'Input';   $current = \$junk;  next;
    }
    if (/^OUTPUT\s*$/) {
      $mode = 'Output';  $current = \$junk;  next;
    }
    if (/^TYPEMAP\s*$/) {
      $mode = 'Typemap'; $current = \$junk;  next;
    }
    if ($mode eq 'Typemap') {
      chomp;
      my $logged_line = $_;
      trim_whitespace($_);
      # skip blank lines
      next if /^$/;
      my($type,$kind, $proto) =
        m/^\s*(.*?\S)\s+(\S+)\s*($ExtUtils::ParseXS::Constants::proto_re*)\s*$/
          or warn(
            "Warning: File '$typemap' Line $.  '$logged_line' " .
            "TYPEMAP entry needs 2 or 3 columns\n"
          ),
          next;
      $type = tidy_type($type);
      $type_kind_ref->{$type} = $kind;
      # prototype defaults to '$'
      $proto = "\$" unless $proto;
#      warn(
#          "Warning: File '$typemap' Line $. '$logged_line' " .
#          "Invalid prototype '$proto'\n"
#      ) unless valid_proto_string($proto);
      $proto_letter_ref->{$type} = C_string($proto);
    }
    elsif (/^\s/) {
      $$current .= $_;
    }
    elsif ($mode eq 'Input') {
      s/\s+$//;
      $input_expr_ref->{$_} = '';
      $current = \$input_expr_ref->{$_};
    }
    else {
      s/\s+$//;
      $output_expr_ref->{$_} = '';
      $current = \$output_expr_ref->{$_};
    }
  }
  close $TYPEMAP;
  return ($type_kind_ref, $proto_letter_ref, $input_expr_ref, $output_expr_ref);
}

=head2 C<make_targetable()>

=over 4

=item * Purpose

Populate C<%targetable>.

=item * Arguments

  %targetable = make_targetable(\%output_expr);
      
Reference to C<%output_expr>.

=item * Return Value

Hash.

=back

=cut

sub make_targetable {
  my $output_expr_ref = shift;
  my ($cast, $size);
  our $bal;
  $bal = qr[(?:(?>[^()]+)|\((??{ $bal })\))*]; # ()-balanced
  $cast = qr[(?:\(\s*SV\s*\*\s*\)\s*)?]; # Optional (SV*) cast
  $size = qr[,\s* (??{ $bal }) ]x; # Third arg (to setpvn)

  my %targetable;
  foreach my $key (keys %{ $output_expr_ref }) {
    # We can still bootstrap compile 're', because in code re.pm is
    # available to miniperl, and does not attempt to load the XS code.
    use re 'eval';

    my ($t, $with_size, $arg, $sarg) =
      ($output_expr_ref->{$key} =~
        m[^ \s+ sv_set ( [iunp] ) v (n)?    # Type, is_setpvn
          \s* \( \s* $cast \$arg \s* ,
          \s* ( (??{ $bal }) )    # Set from
          ( (??{ $size }) )?    # Possible sizeof set-from
          \) \s* ; \s* $
        ]x
    );
    $targetable{$key} = [$t, $with_size, $arg, $sarg] if $t;
  }
  return %targetable;
}

sub map_type {
  my ($type, $varname, $hiertype) = @_;

  # C++ has :: in types too so skip this
  $type =~ tr/:/_/ unless $hiertype;
  $type =~ s/^array\(([^,]*),(.*)\).*/$1 */s;
  if ($varname) {
    if ($type =~ / \( \s* \* (?= \s* \) ) /xg) {
      (substr $type, pos $type, 0) = " $varname ";
    }
    else {
      $type .= "\t$varname";
    }
  }
  return $type;
}

1;

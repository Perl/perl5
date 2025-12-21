package ExtUtils::ParseXS::Utilities;
use strict;
use warnings;
use Exporter;
use File::Spec;
use ExtUtils::ParseXS::Constants ();

our $VERSION = '3.62';

our (@ISA, @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(
  standard_typemap_locations
  trim_whitespace
  C_string
  valid_proto_string
  process_typemaps
  map_type
  set_cond
  Warn
  WarnHint
  current_line_number
  blurt
  death
  check_conditional_preprocessor_statements
  escape_file_for_line_directive
  report_typemap_failure
  looks_like_MODULE_line
);

=head1 NAME

ExtUtils::ParseXS::Utilities - Subroutines used with ExtUtils::ParseXS

=head1 SYNOPSIS

  use ExtUtils::ParseXS::Utilities qw(
    standard_typemap_locations
    trim_whitespace
    C_string
    valid_proto_string
    process_typemaps
    map_type
    set_cond
    Warn
    blurt
    death
    check_conditional_preprocessor_statements
    escape_file_for_line_directive
    report_typemap_failure
  );

=head1 SUBROUTINES

The following functions are not considered to be part of the public interface.
They are documented here for the benefit of future maintainers of this module.

=head2 C<standard_typemap_locations()>

=over 4

=item * Purpose

Returns a standard list of filepaths where F<typemap> files may be found.
This will typically be something like:

        map("$_/ExtUtils/typemap", reverse @INC),
        qw(
            ../../../../lib/ExtUtils/typemap
            ../../../../typemap
            ../../../lib/ExtUtils/typemap
            ../../../typemap
            ../../lib/ExtUtils/typemap
            ../../typemap
            ../lib/ExtUtils/typemap
            ../typemap
            typemap
        )

but the style of the pathnames may vary with OS. Note that the value to
use for C<@INC> is passed as an array reference, and can be something
other than C<@INC> itself.

Pathnames are returned in the order they are expected to be processed;
this means that later files will update or override entries found in
earlier files. So in particular, F<typemap> in the current directory has
highest priority. C<@INC> is searched in reverse order so that earlier
entries in C<@INC> are processed later and so have higher priority.

The values of C<-typemap> switches are not used here; they should be added
by the caller to the list of pathnames returned by this function.

=item * Arguments

  my @stl = standard_typemap_locations(\@INC);

A single argument: a reference to an array to use as if it were C<@INC>.

=item * Return Value

A list of F<typemap> pathnames.

=back

=cut

sub standard_typemap_locations {
  my $include_ref = shift;

  my @tm;

  # See function description above for why 'reverse' is used here.
  foreach my $dir (reverse @{$include_ref}) {
    my $file = File::Spec->catfile($dir, ExtUtils => 'typemap');
    push @tm, $file;
  }

  my $updir = File::Spec->updir();
  foreach my $dir (
      File::Spec->catdir(($updir) x 4),
      File::Spec->catdir(($updir) x 3),
      File::Spec->catdir(($updir) x 2),
      File::Spec->catdir(($updir) x 1),
  ) {
    push @tm, File::Spec->catfile($dir, lib => ExtUtils => 'typemap');
    push @tm, File::Spec->catfile($dir, 'typemap');
  }

  push @tm, 'typemap';

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
  my ($string) = @_;

  if ( $string =~ /^$ExtUtils::ParseXS::Constants::PrototypeRegexp+$/ ) {
    return $string;
  }

  return 0;
}

=head2 C<process_typemaps()>

=over 4

=item * Purpose

Process all typemap files. Reads in any typemap files specified explicitly
with C<-typemap> switches or similar, plus any typemap files found in
standard locations relative to C<@INC> and the current directory.

=item * Arguments

  my $typemaps_object = process_typemaps( $args{typemap}, $pwd );

The first argument is the C<typemap> element from C<%args>; the second is
the current working directory (which is only needed for error messages).

=item * Return Value

Upon success, returns an L<ExtUtils::Typemaps> object which contains the
accumulated results of all processed typemap files.

=back

=cut

sub process_typemaps {
  my ($tmap, $pwd) = @_;

  my @tm = standard_typemap_locations( \@INC );

  my @explicit = ref $tmap ? @{$tmap} : ($tmap);
  foreach my $typemap (@explicit) {
    die "Can't find $typemap in $pwd\n" unless -r $typemap;
  }
  push @tm, @explicit;

  require ExtUtils::Typemaps;
  my $typemap = ExtUtils::Typemaps->new;
  foreach my $typemap_loc (@tm) {
    next unless -f $typemap_loc;
    # skip directories, binary files etc.
    warn("Warning: ignoring non-text typemap file '$typemap_loc'\n"), next
      unless -T $typemap_loc;

    $typemap->merge(file => $typemap_loc, replace => 1);
  }

  return $typemap;
}


=head2 C<map_type($self, $type, $varname)>

Returns a mapped version of the C type C<$type>. In particular, it
converts C<Foo::bar> to C<Foo__bar>, converts the special C<array(type,n)>
into C<type *>, and inserts C<$varname> (if present) into any function
pointer type. So C<...(*)...> becomes C<...(* foo)...>.

=cut

sub map_type {
  my ExtUtils::ParseXS $self = shift;
  my ($type, $varname) = @_;

  # C++ has :: in types too so skip this
  $type =~ tr/:/_/ unless $self->{config_RetainCplusplusHierarchicalTypes};

  # map the special return type 'array(type, n)' to 'type *'
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


=head2 C<set_cond()>

=over 4

=item * Purpose

Return a string containing a snippet of C code which tests for the 'wrong
number of arguments passed' condition, depending on whether there are
default arguments or ellipsis.

=item * Arguments

C<ellipsis> true if the xsub's signature has a trailing C<, ...>.

C<$min_args> the smallest number of args which may be passed.

C<$num_args> the number of parameters in the signature.

=item * Return Value

The text of a short C code snippet.

=back

=cut

sub set_cond {
  my ($ellipsis, $min_args, $num_args) = @_;
  my $cond;
  if ($ellipsis) {
    $cond = ($min_args ? qq(items < $min_args) : 0);
  }
  elsif ($min_args == $num_args) {
    $cond = qq(items != $min_args);
  }
  else {
    $cond = qq(items < $min_args || items > $num_args);
  }
  return $cond;
}

=head2 C<current_line_number()>

=over 4

=item * Purpose

Figures out the current line number in the XS file.

=item * Arguments

C<$self>

=item * Return Value

The current line number.

=back

=cut

sub current_line_number {
  my ExtUtils::ParseXS $self = shift;
  # NB: until the first MODULE line is encountered, $self->{line_no} etc
  # won't have been populated
  my $line_number = @{$self->{line_no}}
        ? $self->{line_no}->[@{ $self->{line_no} } - @{ $self->{line} } -1]
        : $self->{lastline_no};
  return $line_number;
}



=head2 Error handling methods

There are four main methods for reporting warnings and errors.

=over

=item C<< $self->Warn(@messages) >>

This is equivalent to:

  warn "@messages in foo.xs, line 123\n";

The file and line number are based on the file currently being parsed. It
is intended for use where you wish to warn, but can continue parsing and
still generate a correct C output file.

=item C<< $self->blurt(@messages) >>

This is equivalent to C<Warn>, except that it also increments the internal
error count (which can be retrieved with C<report_error_count()>). It is
used to report an error, but where parsing can continue (so typically for
a semantic error rather than a syntax error). It is expected that the
caller will eventually signal failure in some fashion. For example,
C<xsubpp> has this as its last line:

  exit($self->report_error_count() ? 1 : 0);

=item C<< $self->death(@messages) >>

This normally equivalent to:

  $self->Warn(@messages);
  exit(1);

It is used for something like a syntax error, where parsing can't
continue.  However, this is inconvenient for testing purposes, as the
error can't be trapped. So if C<$self> is created with the C<die_on_error>
flag, or if C<$ExtUtils::ParseXS::DIE_ON_ERROR> is true when process_file()
is called, then instead it will die() with that message.

=item C<< $self->WarnHint(@messages, $hints) >>

This is a more obscure twin to C<Warn>, which does the same as C<Warn>,
but afterwards, outputs any lines contained in the C<$hints> string, with
each line wrapped in parentheses. For example:

  $self->WarnHint(@messages,
    "Have you set the foo switch?\nSee the manual for further info");

=back

=cut


# see L</Error handling methods> above

sub Warn {
  my ExtUtils::ParseXS $self = shift;
  $self->WarnHint(@_,undef);
}


# see L</Error handling methods> above

sub WarnHint {
  warn _MsgHint(@_);
}


# see L</Error handling methods> above

sub _MsgHint {
  my ExtUtils::ParseXS $self = shift;
  my $hint = pop;
  my $warn_line_number = $self->current_line_number();
  my $ret = join("",@_) . " in $self->{in_filename}, line $warn_line_number\n";
  if ($hint) {
    $ret .= "    ($_)\n" for split /\n/, $hint;
  }
  return $ret;
}


# see L</Error handling methods> above

sub blurt {
  my ExtUtils::ParseXS $self = shift;
  $self->Warn(@_);
  $self->{error_count}++
}


# see L</Error handling methods> above

sub death {
  my ExtUtils::ParseXS $self = $_[0];
  my $message = _MsgHint(@_,"");
  if ($self->{config_die_on_error}) {
    die $message;
  } else {
    warn $message;
  }
  exit 1;
}


=head2 C<check_conditional_preprocessor_statements()>

=over 4

=item * Purpose

Warn if the lines in C<< @{ $self->{line} } >> don't have balanced C<#if>,
C<endif> etc.

=item * Arguments

None

=item * Return Value

None

=back

=cut

sub check_conditional_preprocessor_statements {
  my ExtUtils::ParseXS $self = $_[0];
  my @cpp = grep(/^\#\s*(?:if|e\w+)/, @{ $self->{line} });
  if (@cpp) {
    my $cpplevel;
    for my $cpp (@cpp) {
      if ($cpp =~ /^\#\s*if/) {
        $cpplevel++;
      }
      elsif (!$cpplevel) {
        $self->Warn("Warning: #else/elif/endif without #if in this function");
        return;
      }
      elsif ($cpp =~ /^\#\s*endif/) {
        $cpplevel--;
      }
    }
    $self->Warn("Warning: #if without #endif in this function") if $cpplevel;
  }
}

=head2 C<escape_file_for_line_directive()>

=over 4

=item * Purpose

Escapes a given code source name (typically a file name but can also
be a command that was read from) so that double-quotes and backslashes are escaped.

=item * Arguments

A string.

=item * Return Value

A string with escapes for double-quotes and backslashes.

=back

=cut

sub escape_file_for_line_directive {
  my $string = shift;
  $string =~ s/\\/\\\\/g;
  $string =~ s/"/\\"/g;
  return $string;
}

=head2 C<report_typemap_failure>

=over 4

=item * Purpose

Do error reporting for missing typemaps.

=item * Arguments

The C<ExtUtils::ParseXS> object.

An C<ExtUtils::Typemaps> object.

The string that represents the C type that was not found in the typemap.

Optionally, the string C<death> or C<blurt> to choose
whether the error is immediately fatal or not. Default: C<blurt>

=item * Return Value

Returns nothing. Depending on the arguments, this
may call C<death> or C<blurt>, the former of which is
fatal.

=back

=cut

sub report_typemap_failure {
  my ExtUtils::ParseXS $self = shift;
  my ($tm, $ctype, $error_method) = @_;
  $error_method ||= 'blurt';

  my @avail_ctypes = $tm->list_mapped_ctypes;

  my $err = "Could not find a typemap for C type '$ctype'.\n"
            . "The following C types are mapped by the current typemap:\n'"
            . join("', '", @avail_ctypes) . "'\n";

  $self->$error_method($err);
  return();
}

=head2 C<looks like_MODULE_line($line)>

Returns true if the passed line looks like an attempt to be a MODULE line.
Note that it doesn't check for valid syntax. This allows the caller to do
its own parsing of the line, providing some sort of 'invalid MODULE line'
check. As compared with thinking that its not a MODULE line if its syntax
is slightly off, leading instead to some weird error about a bad start to
an XSUB or something.

In particular, a line starting C<MODULE:> returns true, because it's
likely to be an attempt by the programmer to write a MODULE line, even
though it's invalid syntax.

=cut

sub looks_like_MODULE_line {
  my $line  = shift;
  $line =~ /^MODULE\s*[=:]/;
}



1;

# vim: ts=2 sw=2 et:

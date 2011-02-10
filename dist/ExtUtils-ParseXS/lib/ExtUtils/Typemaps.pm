package ExtUtils::Typemaps;
use 5.006001;
use strict;
use warnings;
our $VERSION = '0.05';
use Carp qw(croak);

our $Proto_Regexp = "[" . quotemeta('\$%&*@;[]') . "]";

require ExtUtils::Typemaps::InputMap;
require ExtUtils::Typemaps::OutputMap;
require ExtUtils::Typemaps::Type;

=head1 NAME

ExtUtils::Typemaps - Read/Write/Modify Perl/XS typemap files

=head1 SYNOPSIS

  # read/create file
  my $typemap = ExtUtils::Typemaps->new(file => 'typemap');
  # alternatively create an in-memory typemap
  # $typemap = ExtUtils::Typemaps->new();
  # alternatively create an in-memory typemap by parsing a string
  # $typemap = ExtUtils::Typemaps->new(string => $sometypemap);
  
  # add a mapping
  $typemap->add_typemap(ctype => 'NV', xstype => 'T_NV');
  $typemap->add_inputmap (xstype => 'T_NV', code => '$var = ($type)SvNV($arg);');
  $typemap->add_outputmap(xstype => 'T_NV', code => 'sv_setnv($arg, (NV)$var);');
  $typemap->add_string(string => $typemapstring); # will be parsed and merged
  
  # remove a mapping (same for remove_typemap and remove_outputmap...)
  $typemap->remove_inputmap(xstype => 'SomeType');
  
  # save a typemap to a file
  $typemap->write(file => 'anotherfile.map');
  
  # merge the other typemap into this one
  $typemap->merge(typemap => $another_typemap);

=head1 DESCRIPTION

This module can read, modify, create and write Perl XS typemap files. If you don't know
what a typemap is, please confer the L<perlxstut> and L<perlxs> manuals.

The module is not entirely round-trip safe: For example it currently simply strips all comments.
The order of entries in the maps is, however, preserved.

We check for duplicate entries in the typemap, but do not check for missing
C<TYPEMAP> entries for C<INPUTMAP> or C<OUTPUTMAP> entries since these might be hidden
in a different typemap.

=head1 METHODS

=cut

=head2 new

Returns a new typemap object. Takes an optional C<file> parameter.
If set, the given file will be read. If the file doesn't exist, an empty typemap
is returned.

Alternatively, if the C<string> parameter is given, the supplied
string will be parsed instead of a file.

=cut

sub new {
  my $class = shift;
  my %args = @_;

  if (defined $args{file} and defined $args{string}) {
    croak("Cannot handle both 'file' and 'string' arguments to constructor");
  }

  my $self = bless {
    file            => undef,
    %args,
    typemap_section => [],
    typemap_lookup  => {},
    input_section   => [],
    output_section  => [],
  } => $class;

  $self->_init();

  return $self;
}

sub _init {
  my $self = shift;
  if (defined $self->{string}) {
    $self->_parse(\($self->{string}));
    delete $self->{string};
  }
  elsif (defined $self->{file} and -e $self->{file}) {
    open my $fh, '<', $self->{file}
      or die "Cannot open typemap file '"
             . $self->{file} . "' for reading: $!";
    local $/ = undef;
    my $string = <$fh>;
    $self->_parse(\$string, $self->{file});
  }
}

=head2 file

Get/set the file that the typemap is written to when the
C<write> method is called.

=cut

sub file {
  $_[0]->{file} = $_[1] if @_ > 1;
  $_[0]->{file}
}

=head2 add_typemap

Add a C<TYPEMAP> entry to the typemap.

Required named arguments: The C<ctype> (e.g. C<ctype =E<gt> 'double'>)
and the C<xstype> (e.g. C<xstype =E<gt> 'T_NV'>).

Optional named arguments: C<replace =E<gt> 1> forces removal/replacement of
existing C<TYPEMAP> entries of the same C<ctype>.

As an alternative to the named parameters usage, you may pass in
an C<ExtUtils::Typemaps::Type> object, a copy of which will be
added to the typemap.

=cut

sub add_typemap {
  my $self = shift;
  my $type;
  my $replace = 0;
  if (@_ == 1) {
    my $orig = shift;
    $type = $orig->new(@_);
  }
  else {
    my %args = @_;
    my $ctype = $args{ctype};
    croak("Need ctype argument") if not defined $ctype;
    my $xstype = $args{xstype};
    croak("Need xstype argument") if not defined $xstype;

    $type = ExtUtils::Typemaps::Type->new(
      xstype      => $xstype,
      'prototype' => $args{'prototype'},
      ctype       => $ctype,
    );
    $replace = $args{replace};
  }

  if ($replace) {
    $self->remove_typemap(ctype => $type->ctype);
  } else {
    $self->validate(typemap_xstype => $type->xstype, ctype => $type->ctype);
  }

  # store
  push @{$self->{typemap_section}}, $type;
  # remember type for lookup, too.
  $self->{typemap_lookup}{$type->tidy_ctype} = $#{$self->{typemap_section}};
  return 1;
}

=head2 add_inputmap

Add an C<INPUT> entry to the typemap.

Required named arguments:
The C<xstype> (e.g. C<xstype =E<gt> 'T_NV'>)
and the C<code> to associate with it for input.

Optional named arguments: C<replace =E<gt> 1> forces removal/replacement of
existing C<INPUT> entries of the same C<xstype>.

You may pass in a single C<ExtUtils::Typemaps::InputMap> object instead,
a copy of which will be added to the typemap.

=cut

sub add_inputmap {
  my $self = shift;
  my $input;
  my $replace = 0;
  if (@_ == 1) {
    my $orig = shift;
    $input = $orig->new(@_);
  }
  else {
    my %args = @_;
    my $xstype = $args{xstype};
    croak("Need xstype argument") if not defined $xstype;
    my $code = $args{code};
    croak("Need code argument") if not defined $code;

    $input = ExtUtils::Typemaps::InputMap->new(
      xstype => $xstype,
      code   => $code,
    );
    $replace = $args{replace};
  }
  if ($replace) {
    $self->remove_inputmap(xstype => $input->xstype);
  } else {
    $self->validate(inputmap_xstype => $input->xstype);
  }
  push @{$self->{input_section}}, $input;
  return 1;
}

=head2 add_outputmap

Add an C<OUTPUT> entry to the typemap.
Works exactly the same as C<add_inputmap>.

=cut

sub add_outputmap {
  my $self = shift;
  my $output;
  my $replace = 0;
  if (@_ == 1) {
    my $orig = shift;
    $output = $orig->new(@_);
  }
  else {
    my %args = @_;
    my $xstype = $args{xstype};
    croak("Need xstype argument") if not defined $xstype;
    my $code = $args{code};
    croak("Need code argument") if not defined $code;

    $output = ExtUtils::Typemaps::OutputMap->new(
      xstype => $xstype,
      code   => $code,
    );
    $replace = $args{replace};
  }
  if ($replace) {
    $self->remove_outputmap(xstype => $output->xstype);
  } else {
    $self->validate(outputmap_xstype => $output->xstype);
  }
  push @{$self->{output_section}}, $output;
  return 1;
}

=head2 add_string

Parses a string as a typemap and merge it into the typemap object.

Required named argument: C<string> to specify the string to parse.

=cut

sub add_string {
  my $self = shift;
  my %args = @_;
  croak("Need 'string' argument") if not defined $args{string};

  # no, this is not elegant.
  my $other = ExtUtils::Typemaps->new(string => $args{string});
  $self->merge(typemap => $other);
}

=head2 remove_typemap

Removes a C<TYPEMAP> entry from the typemap.

Required named argument: C<ctype> to specify the entry to remove from the typemap.

Alternatively, you may pass a single C<ExtUtils::Typemaps::Type> object.

=cut

sub remove_typemap {
  my $self = shift;
  my $ctype;
  if (@_ > 1) {
    my %args = @_;
    $ctype = $args{ctype};
    croak("Need ctype argument") if not defined $ctype;
    $ctype = _tidy_type($ctype);
  }
  else {
    $ctype = $_[0]->tidy_ctype;
  }

  return $self->_remove($ctype, 'tidy_ctype', $self->{typemap_section}, $self->{typemap_lookup});
}

=head2 remove_inputmap

Removes an C<INPUT> entry from the typemap.

Required named argument: C<xstype> to specify the entry to remove from the typemap.

Alternatively, you may pass a single C<ExtUtils::Typemaps::InputMap> object.

=cut

sub remove_inputmap {
  my $self = shift;
  my $xstype;
  if (@_ > 1) {
    my %args = @_;
    $xstype = $args{xstype};
    croak("Need xstype argument") if not defined $xstype;
  }
  else {
    $xstype = $_[0]->xstype;
  }
  
  return $self->_remove($xstype, 'xstype', $self->{input_section});
}

=head2 remove_inputmap

Removes an C<OUTPUT> entry from the typemap.

Required named argument: C<xstype> to specify the entry to remove from the typemap.

Alternatively, you may pass a single C<ExtUtils::Typemaps::OutputMap> object.

=cut

sub remove_outputmap {
  my $self = shift;
  my $xstype;
  if (@_ > 1) {
    my %args = @_;
    $xstype = $args{xstype};
    croak("Need xstype argument") if not defined $xstype;
  }
  else {
    $xstype = $_[0]->xstype;
  }
  
  return $self->_remove($xstype, 'xstype', $self->{output_section});
}

sub _remove {
  my $self   = shift;
  my $rm     = shift;
  my $method = shift;
  my $array  = shift;
  my $lookup = shift;

  if ($lookup) {
    my $index = $lookup->{$rm};
    return() if not defined $index;
    splice(@$array, $index, 1);
    foreach my $key (keys %$lookup) {
      if ($lookup->{$key} > $index) {
        $lookup->{$key}--;
      }
    }
  }
  else {
    my $index = 0;
    foreach my $map (@$array) {
      last if $map->$method() eq $rm;
      $index++;
    }
    if ($index < @$array) {
      splice(@$array, $index, 1);
      return 1;
    }
  }
  return();
}

=head2 get_typemap

Fetches an entry of the TYPEMAP section of the typemap.

Mandatory named arguments: The C<ctype> of the entry.

Returns the C<ExtUtils::Typemaps::Type>
object for the entry if found.

=cut

sub get_typemap {
  my $self = shift;
  my %args = @_;
  my $ctype = $args{ctype};
  croak("Need ctype argument") if not defined $ctype;
  $ctype = _tidy_type($ctype);

  my $index = $self->{typemap_lookup}{$ctype};
  return() if not defined $index;
  return $self->{typemap_section}[$index];
}

=head2 get_inputmap

Fetches an entry of the INPUT section of the
typemap.

Mandatory named arguments: The C<xstype> of the
entry.

Returns the C<ExtUtils::Typemaps::InputMap>
object for the entry if found.

=cut

sub get_inputmap {
  my $self = shift;
  my %args = @_;
  my $xstype = $args{xstype};
  croak("Need xstype argument") if not defined $xstype;

  foreach my $map (@{$self->{input_section}}) {
    return $map if $map->xstype eq $xstype;
  }
  return();
}

=head2 get_outputmap

Fetches an entry of the OUTPUT section of the
typemap.

Mandatory named arguments: The C<xstype> of the
entry.

Returns the C<ExtUtils::Typemaps::InputMap>
object for the entry if found.

=cut

sub get_outputmap {
  my $self = shift;
  my %args = @_;
  my $xstype = $args{xstype};
  croak("Need xstype argument") if not defined $xstype;

  foreach my $map (@{$self->{output_section}}) {
    return $map if $map->xstype eq $xstype;
  }
  return();
}

=head2 write

Write the typemap to a file. Optionally takes a C<file> argument. If given, the
typemap will be written to the specified file. If not, the typemap is written
to the currently stored file name (see C<-E<gt>file> above, this defaults to the file
it was read from if any).

=cut

sub write {
  my $self = shift;
  my %args = @_;
  my $file = defined $args{file} ? $args{file} : $self->file();
  croak("write() needs a file argument (or set the file name of the typemap using the 'file' method)")
    if not defined $file;

  open my $fh, '>', $file
    or die "Cannot open typemap file '$file' for writing: $!";
  print $fh $self->as_string();
  close $fh;
}

=head2 as_string

Generates and returns the string form of the typemap.

=cut

sub as_string {
  my $self = shift;
  my $typemap = $self->{typemap_section};
  my @code;
  push @code, "TYPEMAP\n";
  foreach my $entry (@$typemap) {
    # type kind proto
    # /^(.*?\S)\s+(\S+)\s*($Proto_Regexp*)$/o
    push @code, $entry->ctype . "\t" . $entry->xstype
              . ($entry->proto ne '' ? "\t".$entry->proto : '') . "\n";
  }

  my $input = $self->{input_section};
  if (@$input) {
    push @code, "\nINPUT\n";
    foreach my $entry (@$input) {
      push @code, $entry->xstype, "\n", $entry->code, "\n";
    }
  }

  my $output = $self->{output_section};
  if (@$output) {
    push @code, "\nOUTPUT\n";
    foreach my $entry (@$output) {
      push @code, $entry->xstype, "\n", $entry->code, "\n";
    }
  }
  return join '', @code;
}

=head2 merge

Merges a given typemap into the object. Note that a failed merge
operation leaves the object in an inconsistent state so clone if necessary.

Mandatory named argument: C<typemap =E<gt> $another_typemap>

Optional argument: C<replace =E<gt> 1> to force replacement
of existing typemap entries without warning.

=cut

sub merge {
  my $self = shift;
  my %args = @_;
  my $typemap = $args{typemap};
  croak("Need ExtUtils::Typemaps as argument")
    if not ref $typemap or not $typemap->isa('ExtUtils::Typemaps');

  my $replace = $args{replace};

  # FIXME breaking encapsulation. Add accessor code.
  #
  foreach my $entry (@{$typemap->{typemap_section}}) {
    $self->add_typemap( $entry );
  }

  foreach my $entry (@{$typemap->{input_section}}) {
    $self->add_inputmap( $entry );
  }

  foreach my $entry (@{$typemap->{output_section}}) {
    $self->add_outputmap( $entry );
  }

  return 1;
}

# Note: This is really inefficient. One could keep a hash to start with.
sub validate {
  my $self = shift;
  my %args = @_;

  if ( exists $args{ctype}
       and exists $self->{typemap_lookup}{_tidy_type($args{ctype})} )
  {
    croak("Multiple definition of ctype '$args{ctype}' in TYPEMAP section");
  }

  my %xstypes;

  %xstypes = ();
  $xstypes{$args{inputmap_xstype}}++ if defined $args{inputmap_xstype};
  foreach my $map (@{$self->{input_section}}) {
    my $xstype = $map->xstype;
    croak("Multiple definition of xstype '$xstype' in INPUTMAP section")
      if exists $xstypes{$xstype};
    $xstypes{$xstype}++;
  }

  %xstypes = ();
  $xstypes{$args{outputmap_xstype}}++ if defined $args{outputmap_xstype};
  foreach my $map (@{$self->{output_section}}) {
    my $xstype = $map->xstype;
    croak("Multiple definition of xstype '$xstype' in OUTPUTMAP section")
      if exists $xstypes{$xstype};
    $xstypes{$xstype}++;
  }

  return 1;
}

sub _parse {
  my $self = shift;
  my $stringref = shift;
  my $filename = shift;
  $filename = '<string>' if not defined $filename;

  # TODO comments should round-trip, currently ignoring
  # TODO order of sections, multiple sections of same type
  # Heavily influenced by ExtUtils::ParseXS
  my $section = 'typemap';
  my $lineno = 0;
  my $junk = "";
  my $current = \$junk;
  my @input_expr;
  my @output_expr;
  while ($$stringref =~ /^(.*)$/gcm) {
    local $_ = $1;
    ++$lineno;
    chomp;
    next if /^\s*#/;
    if (/^INPUT\s*$/) {
      $section = 'input';
      $current = \$junk;
      next;
    }
    elsif (/^OUTPUT\s*$/) {
      $section = 'output';
      $current = \$junk;
      next;
    }
    elsif (/^TYPEMAP\s*$/) {
      $section = 'typemap';
      $current = \$junk;
      next;
    }
    
    if ($section eq 'typemap') {
      my $line = $_;
      s/^\s+//; s/\s+$//;
      next if /^#/ or /^$/;
      my($type, $kind, $proto) = /^(.*?\S)\s+(\S+)\s*($Proto_Regexp*)$/o
        or warn("Warning: File '$filename' Line $lineno '$line' TYPEMAP entry needs 2 or 3 columns\n"),
           next;
      #$proto = '' if not $proto;
      # prototype defaults to '$'
      #$proto = '$' unless $proto;
      #warn("Warning: File '$filename' Line $lineno '$line' Invalid prototype '$proto'\n")
      #  unless _valid_proto_string($proto);
      $self->add_typemap(
        ExtUtils::Typemaps::Type->new(
          xstype => $kind, proto => $proto, ctype => $type
        )
      );
    } elsif (/^\s/) {
      $$current .= $$current eq '' ? $_ : "\n".$_;
    } elsif (/^$/) {
      next;
    } elsif ($section eq 'input') {
      s/\s+$//;
      push @input_expr, {xstype => $_, code => ''};
      $current = \$input_expr[-1]{code};
    } else { # output section
      s/\s+$//;
      push @output_expr, {xstype => $_, code => ''};
      $current = \$output_expr[-1]{code};
    }

  } # end while lines

  $self->{input_section}   = [ map {ExtUtils::Typemaps::InputMap->new(%$_) } @input_expr ];
  $self->{output_section}  = [ map {ExtUtils::Typemaps::OutputMap->new(%$_) } @output_expr ];
  
  # Now, setup the lookups

  return $self->validate();
}

# taken from ExtUtils::ParseXS
sub _tidy_type {
  local $_ = shift;

  # rationalise any '*' by joining them into bunches and removing whitespace
  s#\s*(\*+)\s*#$1#g;
  s#(\*+)# $1 #g ;

  # trim leading & trailing whitespace
  s/^\s+//; s/\s+$//;

  # change multiple whitespace into a single space
  s/\s+/ /g;

  $_;
}


# taken from ExtUtils::ParseXS
sub _valid_proto_string {
  my $string = shift;
  if ($string =~ /^$Proto_Regexp+$/o) {
    return $string;
  }

  return 0 ;
}

# taken from ExtUtils::ParseXS (C_string)
sub _escape_backslashes {
  my $string = shift;
  $string =~ s[\\][\\\\]g;
  $string;
}

=head1 CAVEATS

Inherits some evil code from C<ExtUtils::ParseXS>.

Adding more typemaps incurs an O(n) validation penalty
that could be optimized with a hash.

=head1 SEE ALSO

The parser is heavily inspired from the one in L<ExtUtils::ParseXS>.

For details on typemaps: L<perlxstut>, L<perlxs>.

=head1 AUTHOR

Steffen Mueller C<<smueller@cpan.org>>

=head1 COPYRIGHT & LICENSE

Copyright 2009-2011 Steffen Mueller

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;


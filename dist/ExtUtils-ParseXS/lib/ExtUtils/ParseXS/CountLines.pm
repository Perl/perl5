package ExtUtils::ParseXS::CountLines;

# Private helper module. It is used to tie a file handle, and
# whenever lines are written to it, lines which match the
#
#   ExtUtils::ParseXS::CountLines->end_marker()
#
# token are replaced with:
#
#   #line NNN file.c
#
# where NNN is the count of lines written so far.

use strict;
use warnings;

our $VERSION = '3.63';

our $SECTION_END_MARKER;

sub TIEHANDLE {
  my ($class, $cfile, $fh) = @_;
  $cfile =~ s/\\/\\\\/g;
  $cfile =~ s/"/\\"/g;
  $SECTION_END_MARKER = qq{#line --- "$cfile"};

  return bless {
    buffer => '',
    fh => $fh,
    line_no => 1,
  }, $class;
}

sub PRINT {
  my $self = shift;
  for (@_) {
    $self->{buffer} .= $_;
    while ($self->{buffer} =~ s/^([^\n]*\n)//) {
      my $line = $1;
      ++$self->{line_no};
      $line =~ s|^\#line\s+---(?=\s)|#line $self->{line_no}|;
      print {$self->{fh}} $line;
    }
  }
}

sub PRINTF {
  my $self = shift;
  my $fmt = shift;
  $self->PRINT(sprintf($fmt, @_));
}

sub DESTROY {
  # Not necessary if we're careful to end with a "\n"
  my $self = shift;
  print {$self->{fh}} $self->{buffer} if length $self->{buffer};
}

sub UNTIE {
  # This sub does nothing, but is necessary for references to be released.
}

sub end_marker {
  return $SECTION_END_MARKER;
}

1;

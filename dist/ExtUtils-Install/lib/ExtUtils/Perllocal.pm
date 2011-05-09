package ExtUtils::Perllocal;

use 5.00503;
use strict;
use Carp qw();
use vars qw($VERSION);
$VERSION = '1.44_01';
$VERSION = eval $VERSION;
require ExtUtils::Perllocal::Entry;

sub new {
  my $class = shift;
  my %opts = @_;
  die "'file' parameter required!" if not defined $opts{file};
  my $self = bless({%opts} => $class);
  return $self;
}

sub append_entry {
  my $self = shift;
  my $entry = shift;

  my $perllocal = $self->{file};
  my $pod = $entry->as_pod;
  open FH, ">>$perllocal"
    or die "Cannot open perllocal file '$perllocal' for appending: $!";
  print FH $pod;
  close FH
    or die "Failed to write to perllocal file '$perllocal': $!";
}

sub get_entries {
  my $self = shift;

  require ExtUtils::Perllocal::Parser;
  my $file = $self->{file};

  my $parser = ExtUtils::Perllocal::Parser->new;
  return $parser->parse_from_file($file);
}

1;

__END__

=head1 NAME

ExtUtils::Perllocal - manage perllocal.pod files

=head1 SYNOPSIS

  use ExtUtils::Perllocal;
  my $pl = ExtUtils::Perllocal->new(file => '/path/to/perllocal.pod');
  my $entry = ExtUtils::Perllocal::Entry->new(...);
  $pl->append_entry($entry); # writes to file
  my @entries = $pl->get_entries(); # parses file
  foreach my $entry (@entries) {
    # See ExtUtils::Perllocal::Entry
  }

=head1 DESCRIPTION

C<ExtUtils::Perllocal> provides a standard way to manage F<perllocal.pod> files.

=head1 METHODS

=head2 new

Contstructor. Takes named parameters.

Mandatory parameter C<file> should point at the F<perllocal.pod> file
that you intend to append to or parse.

=head2 append_entry

Appends an entry to the specified F<perllocal.pod> file. Takes
an L<ExtUtils::Perllocal::Entry> object as argument.

=head2 get_entries

Parses the file and returns the list of L<ExtUtils::Perllocal::Entry>
objects from the file.

B<Note:> Requires the C<Pod::Parser> and C<Time::Local> modules
at run-time when C<get_entries> is called.

=head1 AUTHOR

Steffen Mueller, C<smueller@cpan.org>

Inspired by C<ExtUtils::Command::MM> by Randy Kobes.

=head1 COPRIGHT AND LICENSE

Copyright (c) 2011 by Steffen Mueller

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

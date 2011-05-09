package ExtUtils::Perllocal::Entry;

use 5.00503;
use strict;
use Carp qw();

sub new {
  my $class = shift;
  my %opts = @_;
  if (not defined $opts{name}) {
    Carp::croak("Need module name as 'name' parameter");
  }
  
  my $self = bless({
    'time' => time(),
    type => 'Module',
    data => {},
    %opts,
  } => $class);

  return $self;
}

sub as_pod {
  my $self = shift;

  my $pod;
  $pod = sprintf <<POD, scalar localtime($self->{'time'});
=head2 %s: C<$self->{type}> L<$self->{name}|$self->{name}>
 
=over 4
 
POD

  foreach my $key (sort keys %{$self->{data}}) {
    if ($key =~ ':') {
      die "The keys in the 'data' hash of perllocal.pod entries "
          . "must not contain colons, but '$key' does!";
    }
    my $value = $self->{data}{$key};
    $pod .= <<POD
=item *

C<$key: $value>
 
POD
  }
  $pod .= "=back\n\n";

  return $pod;
}

sub name {
  my $self = shift;
  if (@_) {
    $self->{name} = shift;
  }
  return $self->{name};
}

sub time {
  my $self = shift;
  if (@_) {
    $self->{time} = shift;
  }
  return $self->{time};
}

sub type {
  my $self = shift;
  if (@_) {
    $self->{type} = shift;
  }
  return $self->{type};
}

sub data {
  my $self = shift;
  return $self->{data};
}


1;

__END__

=head1 NAME

ExtUtils::Perllocal::Entry - A single perllocal.pod entry

=head1 SYNOPSIS

  use ExtUtils::Perllocal;
  my $pl = ExtUtils::Perllocal->new(file => '/path/to/perllocal.pod');
  my $entry = ExtUtils::Perllocal::Entry->new(
    name   => 'The::Module',
    type   => 'Module', # defaults to 'Module'
    'time' => $seconds_since_epoch, # defaults to running time()
    data   => { # key/value pairs that will be written as an =item list, no defaults
      # These are all conventions:
      "installed into" => $path_to_installation,
      LINKTYPE => 'dynamic', # static|dynamic
      VERSION => The::Module->VERSION,
      EXE_FILES => join(' ', @exe_files),
    },
  );
  $pl->append_entry($entry); # writes to file

=head1 DESCRIPTION

C<ExtUtils::Perllocal::Entry> is the in-memory representation of a single
F<perllocal.pod> entry.

=head1 METHODS

=head2 new

Constructor. Takes named parameters.
Requires the C<name> parameter indicating the module name.

C<type> is the type of the thing to be installed and defaults to C<Module>.
C<time> is the installation time as seconds since the UNIX epoch.
C<data> can contain key/value pairs of additional data to include
as an itemized list in alphabetical key order. Some conventional
data is shown in the SYNOPSIS.

Due to the historic output format, the keys of the data hash
cannot contain colons or else, parsing them again would become
impossible.

=head2 as_pod

Returns the POD representation of the entry.

=head2 name

Read/write accessor for the module name.

=head2 time

Read/write accessor for the installation time.

=head2 type

Read/write accessor for the installation type.

=head2 data

Read accessor for the additional data (see constructor docs).
Returns the actual hash ref. that is contained in the object,
so modifying it modifies the state of the object.

=head1 AUTHOR

Steffen Mueller, C<smueller@cpan.org>

Inspired by C<ExtUtils::Command::MM> by Randy Kobes.

=head1 COPRIGHT AND LICENSE

Copyright (c) 2011 by Steffen Mueller

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

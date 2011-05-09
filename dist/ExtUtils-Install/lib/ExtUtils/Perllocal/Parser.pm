package ExtUtils::Perllocal::Parser;

use 5.00503;
use strict;
use Carp qw();
require ExtUtils::Perllocal::Entry;
require Pod::Simple::SimpleTree;
require Time::Local;

sub new {
  my $class = shift;
  my %opt = @_;
  my $self = bless({%opt} => $class);
  return $self;
}

sub parse_from_file {
  my $self = shift;
  my $file = shift;
  local $self->{file} = $file;
  my $psst = Pod::Simple::SimpleTree->new->parse_file($file)->root;
  my @nodes = _subnodes($psst);

  my @entries;
  while (@nodes) {
    # Parse this: =head2 Wed Nov  3 20:46:45 2010: C<Module> L<Module::CoreList|Module::CoreList> 
    my $head2 = shift @nodes;
    if ($head2->[0] ne 'head2') {
      $self->_report_error($head2, "Expected =head2");
      next;
    }
    my @subn = _subnodes($head2);
    if (@subn != 4 or ref($subn[0])
        or not ref($subn[1]) or $subn[1][0] ne 'C'
        or not ref($subn[3]) or not $subn[3][0] eq 'L')
    {
      $self->_report_error($head2, "Expected string of format '[date]: C<[type]> L<[name]>");
      next;
    }
    my $type = $subn[1][2];
    my $name = $subn[3][2];
    my $epoch = date_str_to_epoch(\$subn[0]);
    if (not $epoch or not $subn[0] =~ /^:/) {
      $self->_report_error($head2, "Expected string of format '[date]: C<[type]> L<[name]>");
    }

    my $entry = ExtUtils::Perllocal::Entry->new(
      'time' => $epoch, type => $type, name => $name,
    );
    my $entry_data = $entry->data;

    # Parse the data section (=over.. =item * C<key: value> =back)
    my $over = shift @nodes;
    @subn = _subnodes($over);
    foreach my $bullet (@subn) {
      if (not ref($bullet)) {
        $self->_report_error($over, "Expected only =item's in =over");
        next;
      }
      elsif (not $bullet->[0] eq 'item-bullet') {
        $self->_report_error($bullet, "Expected only =item's in =over");
        next;
      }
      elsif (not ref($bullet->[2]) or $bullet->[2][0] ne 'C') {
        $self->_report_error($bullet, "Expected C<> in =item");
        next;
      }
      elsif (ref($bullet->[2][2])) {
        $self->_report_error($bullet, "Expected text in the C<> within each=item");
        next;
      }
      
      my $text = $bullet->[2][2];
      my ($key, $value) = split /\s*:\s*/, $text, 2;
      if (not defined $key or not defined $value) {
        $self->_report_error($bullet, "Expected text of the form 'C<key: value>'");
      }
      $entry_data->{$key} = $value;
    }
    push @entries, $entry;
  }

  return @entries;
}

sub _subnodes {
  my $n = shift;
  return @{$n}[2..$#$n];
}

sub _report_error {
  my $self = shift;
  my $node = shift;
  my $err = shift;

  return if $self->{silent};
  my $debug = 1;
  if (ref($node)) {
    my $line = $node->[1]{start_line};
    Carp::carp("Invalid perllocal.pod at $self->{file}:$line: $err");
    if ($debug) {
      require Data::Dumper;
      warn Data::Dumper->Dump([$node], ['$node']);
    }
  }
  else {
    Carp::carp("Invalid perllocal.pod '$self->{file}': $err");
  }
}


SCOPE: {
  # Low dependency mode... parse manually. Yikes.
  my $WeekDayRegexp = qr/(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)/;
  my $MonthRegexp   = qr/(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)/;
  my $imonth = 0;
  my %MonthToNumber = map {$_ => $imonth++} qw(
    Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
  );

  sub date_str_to_epoch {
    my $strref = shift;
    $$strref =~ s/^$WeekDayRegexp\s+($MonthRegexp)
                  \s+(\d+)\s+(\d\d):(\d\d):(\d\d)\s+(\d\d\d\d)//ox
      or return();

    my $epoch = Time::Local::timelocal($5, $4, $3, $2, $MonthToNumber{$1}, $6);
    return $epoch;
  }
}

1;

__END__

=head1 NAME

ExtUtils::Perllocal::Parser - Internal parser tool for ExtUtils::Perllocal

=head1 SYNOPSIS

  use ExtUtils::Perllocal;

=head1 DESCRIPTION

Internal to L<ExtUtils::Perllocal>. B<Never> use this directly!

=head1 AUTHOR

Steffen Mueller, C<smueller@cpan.org>

Inspired by C<ExtUtils::Command::MM> by Randy Kobes.

=head1 COPRIGHT AND LICENSE

Copyright (c) 2011 by Steffen Mueller

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

#!/usr/bin/perl
use IO::File ();
use File::Find qw(find);
use Text::Wrap qw(wrap);
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);
use strict;

my %opt = (
  hide   => [],
  frames => 3,
  debug  => 0,
);

GetOptions( \%opt,
          qw(
            hide=s@
            output-file=s
            frames=i
            debug+
          ) ) or pod2usage(2);

my %hide;
my $hide_re = join '|', map { /^\w+$/ && ++$hide{$_} ? () : $_ } @{$opt{hide}};
$hide_re and $hide_re = qr/^(?:$hide_re)$/o;

my $fh = \*STDOUT;
if (exists $opt{'output-file'}) {
  $fh = new IO::File ">$opt{'output-file'}"
        or die "$opt{'output-file'}: $!\n";
}

my(%error, %leak);

find({wanted => \&filter, no_chdir => 1}, '.');
summary($fh);

exit 0;

sub summary {
  my $fh = shift;

  $Text::Wrap::columns = 80;
  
  print $fh "MEMORY ACCESS ERRORS\n\n";
  
  for my $e (sort keys %error) {
    print $fh qq("$e"\n);
    for my $frame (sort keys %{$error{$e}}) {
      print $fh ' 'x4, "$frame\n",
            wrap(' 'x8, ' 'x8, join ', ', sort keys %{$error{$e}{$frame}}),
            "\n";
    }
    print $fh "\n";
  }
  
  print $fh "\nMEMORY LEAKS\n\n";
  
  for my $l (sort keys %leak) {
    print $fh qq("$l"\n);
    for my $frames (sort keys %{$leak{$l}}) {
      my @stack = split /</, $frames;
      print $fh join('', map { ' 'x4 . "$_:$stack[$_]\n" } 0 .. $#stack ),
            wrap(' 'x8, ' 'x8, join ', ', sort keys %{$leak{$l}{$frames}}),
            "\n\n";
    }
  }
}

sub filter {
  debug(1, "$File::Find::name\n");

  /(.*)\.valgrind$/ or return;

  my $test = $1;
  $test =~ s/^[.t]\///g;

  my @l = map { chomp; s/^==\d+==\s?//; $_ }
          do { my $fh = new IO::File $_ or die "$_: $!\n"; <$fh> };

  my $hexaddr  = '0x[[:xdigit:]]+';
  my $topframe = qr/^\s+at $hexaddr:\s+/o;
  my $address  = qr/^\s+Address $hexaddr is \d+ bytes (?:before|inside|after) a block of size \d+/o;
  my $leak     = qr/^\s*\d+ bytes in \d+ blocks are (still reachable|(?:definite|possib)ly lost)/o;

  for my $i (0 .. $#l) {
    $l[$i]   =~ $topframe or next; # match on any topmost frame...
    $l[$i-1] =~ $address and next; # ...but not if it's only address details
    my $line = $l[$i-1];
    my $j    = $i;

    if ($line =~ $leak) {
      debug(2, "LEAK: $line\n");

      my $kind   = $1;
      my $inperl = 0;
      my @stack;

      while ($l[$j++] =~ /^\s+(?:at|by) $hexaddr:\s+((\w+)\s+\((?:([^:]+:\d+)|[^)]+)\))/o) {
        my($frame, $func, $loc) = ($1, $2, $3);
        defined $loc && ++$inperl or $inperl && last;
        if (exists $hide{$func} or $hide_re && $func =~ $hide_re) {
          @stack = ();
          last;
        }
        $inperl <= $opt{frames} and push @stack, $inperl ? $frame : $func;
      }

      @stack and $inperl and $leak{$kind}{join '<', @stack}{$test}++;
    } else {
      debug(1, "ERROR: $line\n");

      while ($l[$j++] =~ /^\s+(?:at|by) $hexaddr:\s+(\w+\s+\([^:]+:\d+\))?/o) {
        if (defined $1) {
          $error{$line}{$1}{$test}++;
          last;
        }
      }
    }
  }
}

sub debug {
  my $level = shift;
  $opt{debug} >= $level and print STDERR @_;
}

__END__

=head1 NAME

valgrindpp.pl - A post processor for make test.valgrind

=head1 SYNOPSIS

valgrindpp.pl [B<--output-file>=I<file>] [B<--frames>=I<number>]
[B<--hide>=I<identifier>] [B<--debug>]

=head1 DESCRIPTION

B<valgrindpp.pl> is a post processor for I<.valgrind> files
created during I<make test.valgrind>. It collects all these
files, extracts most of the information and produces a
significantly shorter summary of all detected memory access
errors and memory leaks.

=head1 OPTIONS

=over 4

=item B<--output-file>=I<file>

Redirect the output into I<file>. If this option is not
given, the output goes to I<stdout>.

=item B<--frames>=I<number>

Number of stack frames within the perl source code to 
consider when distinguishing between memory leak sources.
Increasing this value will give you a longer backtrace,
while decreasing the number will show you fewer sources
for memory leaks. The default is 3 frames.

=item B<--hide>=I<identifier>

Hide all memory leaks that have I<identifier> in their backtrace.
Useful if you want to hide leaks from functions that are known to
have lots of memory leaks. I<identifier> can also be a regular
expression, in which case all leaks with symbols matching the
expression are hidden. Can be given multiple times.

=item B<--debug>

Increase debug level. Can be given multiple times.

=back

=head1 COPYRIGHT

Copyright 2003 by Marcus Holland-Moritz <mhx@cpan.org>.

This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut

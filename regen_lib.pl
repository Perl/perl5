#!/usr/bin/perl -w
use strict;
use vars qw($Is_W32 $Is_OS2 $Is_Cygwin $Is_NetWare $Needs_Write $Verbose
	    @Changed);
use Config; # Remember, this is running using an existing perl
use File::Compare;
use Symbol;

# Common functions needed by the regen scripts

$Is_W32 = $^O eq 'MSWin32';
$Is_OS2 = $^O eq 'os2';
$Is_Cygwin = $^O eq 'cygwin';
$Is_NetWare = $Config{osname} eq 'NetWare';
if ($Is_NetWare) {
  $Is_W32 = 0;
}

$Needs_Write = $Is_OS2 || $Is_W32 || $Is_Cygwin || $Is_NetWare;

$Verbose = 0;
@ARGV = grep { not($_ eq '-q' and $Verbose = -1) }
  grep { not($_ eq '-v' and $Verbose = 1) } @ARGV;

END {
  print STDOUT "Changed: @Changed\n" if @Changed;
}

sub safer_unlink {
  my @names = @_;
  my $cnt = 0;

  my $name;
  foreach $name (@names) {
    next unless -e $name;
    chmod 0777, $name if $Needs_Write;
    ( CORE::unlink($name) and ++$cnt
      or warn "Couldn't unlink $name: $!\n" );
  }
  return $cnt;
}

sub safer_rename_silent {
  my ($from, $to) = @_;

  # Some dosish systems can't rename over an existing file:
  safer_unlink $to;
  chmod 0600, $from if $Needs_Write;
  rename $from, $to;
}

sub rename_if_different {
  my ($from, $to) = @_;

  if (compare($from, $to) == 0) {
      warn "no changes between '$from' & '$to'\n" if $Verbose > 0;
      safer_unlink($from);
      return;
  }
  warn "changed '$from' to '$to'\n" if $Verbose > 0;
  push @Changed, $to unless $Verbose < 0;
  safer_rename_silent($from, $to) or die "renaming $from to $to: $!";
}

# Saf*er*, but not totally safe. And assumes always open for output.
sub safer_open {
    my $name = shift;
    my $fh = gensym;
    open $fh, ">$name" or die "Can't create $name: $!";
    *{$fh}->{SCALAR} = $name;
    binmode $fh;
    $fh;
}

sub safer_close {
    my $fh = shift;
    close $fh or die 'Error closing ' . *{$fh}->{SCALAR} . ": $!";
}

1;

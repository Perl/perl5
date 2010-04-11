package PrimitiveCapture;
use strict;
use warnings;

sub capture_stdout {
  my $sub = shift;
  my $stdout;
  open my $oldout, ">&STDOUT" or die "Can't dup STDOUT: $!";
  close STDOUT;
  open STDOUT, '>', \$stdout or die "Can't open STDOUT: $!";

  $sub->();

  close STDOUT;
  open STDOUT, ">&", $oldout or die "Can't dup \$oldout: $!";
  return $stdout;
}

sub capture_stderr {
  my $sub = shift;
  my $stderr;
  open my $olderr, ">&STDERR" or die "Can't dup STDERR: $!";
  close STDERR;
  open STDERR, '>', \$stderr or die "Can't open STDERR: $!";

  $sub->();

  close STDERR;
  open STDERR, ">&", $olderr or die "Can't dup \$olderr: $!";
  return $stderr;
}

1;

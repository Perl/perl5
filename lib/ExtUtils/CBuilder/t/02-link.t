#! perl -w

BEGIN {
  if ($ENV{PERL_CORE}) {
    chdir 't' if -d 't';
    chdir '../lib/ExtUtils/CBuilder'
      or die "Can't chdir to lib/ExtUtils/CBuilder: $!";
    @INC = qw(../..);
  }
}

use strict;
use Test;
BEGIN { 
  if ($^O eq 'MSWin32') {
    print "1..0 # Skipped: link_executable() is not implemented yet on Win32\n";
    exit;
  }
  if ($^O eq 'VMS') {
    # So we can get the return value of system()
    require vmsish;
    import vmsish;
  }
  plan tests => 5;
}

use ExtUtils::CBuilder;
use File::Spec;

# TEST doesn't like extraneous output
my $quiet = $ENV{PERL_CORE} && !$ENV{HARNESS_ACTIVE};

my $b = ExtUtils::CBuilder->new(quiet => $quiet);
ok $b;

my $source_file = File::Spec->catfile('t', 'compilet.c');
{
  local *FH;
  open FH, "> $source_file" or die "Can't create $source_file: $!";
  print FH "int main(void) { return 11; }\n";
  close FH;
}
ok -e $source_file;

# Compile
my $object_file;
ok $object_file = $b->compile(source => $source_file);

# Link
my ($exe_file, @temps);
($exe_file, @temps) = $b->link_executable(objects => $object_file);
ok $exe_file;

# Try the executable
ok my_system($exe_file), 11;

# Clean up
for ($source_file, $exe_file, $object_file, @temps) {
  tr/"'//d;
  1 while unlink;
}

sub my_system {
  my $cmd = shift;
  if ($^O eq 'VMS') {
    return system("mcr $cmd");
  }
  return system($cmd) >> 8;
}

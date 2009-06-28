#!/usr/bin/perl

BEGIN {
  if ($ENV{PERL_CORE}) {
    chdir 't' if -d 't';
    chdir '../lib/ExtUtils/ParseXS'
      or die "Can't chdir to lib/ExtUtils/ParseXS: $!";
    @INC = qw(../.. ../../.. .);
  }
}
use strict;
use Test;
BEGIN { plan tests => 24 };
use DynaLoader;
use ExtUtils::ParseXS qw(process_file);
use ExtUtils::CBuilder;
ok(1); # If we made it this far, we're loaded.

chdir 't' or die "Can't chdir to t/, $!";

use Carp; $SIG{__WARN__} = \&Carp::cluck;

#########################

my $source_file = 'XSUsage.c';

# Try sending to file
process_file(filename => 'XSUsage.xs', output => $source_file);
ok -e $source_file, 1, "Create an output file";

# TEST doesn't like extraneous output
my $quiet = $ENV{PERL_CORE} && !$ENV{HARNESS_ACTIVE};

# Try to compile the file!  Don't get too fancy, though.
my $b = ExtUtils::CBuilder->new(quiet => $quiet);
if ($b->have_compiler) {
  my $module = 'XSUsage';

  my $obj_file = $b->compile( source => $source_file );
  ok $obj_file;
  ok -e $obj_file, 1, "Make sure $obj_file exists";

  my $lib_file = $b->link( objects => $obj_file, module_name => $module );
  ok $lib_file;
  ok -e $lib_file, 1, "Make sure $lib_file exists";

  eval {require XSUsage};
  ok $@, '';

  # The real tests here - for each way of calling the functions, call with the
  # wrong number of arguments and check the Usage line is what we expect

  eval { XSUsage::one(1) };
  ok $@;
  ok $@ =~ /^Usage: XSUsage::one/;

  eval { XSUsage::two(1) };
  ok $@;
  ok $@ =~ /^Usage: XSUsage::two/;

  eval { XSUsage::two_x(1) };
  ok $@;
  ok $@ =~ /^Usage: XSUsage::two_x/;

  eval { FOO::two(1) };
  ok $@;
  ok $@ =~ /^Usage: FOO::two/;

  eval { XSUsage::three(1) };
  ok $@;
  ok $@ =~ /^Usage: XSUsage::three/;

  eval { XSUsage::four(1) };
  ok !$@;

  eval { XSUsage::five() };
  ok $@;
  ok $@ =~ /^Usage: XSUsage::five/;

  eval { XSUsage::six() };
  ok !$@;

  eval { XSUsage::six(1) };
  ok !$@;

  eval { XSUsage::six(1,2) };
  ok $@;
  ok $@ =~ /^Usage: XSUsage::six/;

  # Win32 needs to close the DLL before it can unlink it, but unfortunately
  # dl_unload_file was missing on Win32 prior to perl change #24679!
  if ($^O eq 'MSWin32' and defined &DynaLoader::dl_unload_file) {
    for (my $i = 0; $i < @DynaLoader::dl_modules; $i++) {
      if ($DynaLoader::dl_modules[$i] eq $module) {
        DynaLoader::dl_unload_file($DynaLoader::dl_librefs[$i]);
        last;
      }
    }
  }
  1 while unlink $obj_file;
  1 while unlink $lib_file;
} else {
  skip "Skipped can't find a C compiler & linker", 1 for 3 .. 24;
}

1 while unlink $source_file;

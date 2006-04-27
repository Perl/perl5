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
BEGIN { plan tests => 10 };
use ExtUtils::ParseXS qw(process_file);
use ExtUtils::CBuilder;
ok(1); # If we made it this far, we're loaded.

chdir 't' or die "Can't chdir to t/, $!";

use Carp; $SIG{__WARN__} = \&Carp::cluck;

#########################

# Try sending to filehandle
tie *FH, 'Foo';
process_file( filename => 'XSTest.xs', output => \*FH, prototypes => 1 );
ok tied(*FH)->content, '/is_even/', "Test that output contains some text";

# Try sending to file
process_file( filename => 'XSTest.xs', output => 'XSTest.c', prototypes => 0 );
ok -e 'XSTest.c', 1, "Create an output file";

# TEST doesn't like extraneous output
my $quiet = $ENV{PERL_CORE} && !$ENV{HARNESS_ACTIVE};

# Try to compile the file!  Don't get too fancy, though.
my $b = ExtUtils::CBuilder->new(quiet => $quiet);
if ($b->have_compiler) {
  my $module = 'XSTest';

  my $obj_file = $b->compile( source => "$module.c" );
  ok $obj_file;
  ok -e $obj_file, 1, "Make sure $obj_file exists";

  my $lib_file = $b->link( objects => $obj_file, module_name => $module );
  ok $lib_file;
  ok -e $lib_file, 1, "Make sure $lib_file exists";

  eval {require XSTest};
  ok $@, '';
  ok  XSTest::is_even(8);
  ok !XSTest::is_even(9);

} else {
  skip "Skipped can't find a C compiler & linker", 1 for 1..6;
}

#####################################################################

sub Foo::TIEHANDLE { bless {}, 'Foo' }
sub Foo::PRINT { shift->{buf} .= join '', @_ }
sub Foo::content { shift->{buf} }

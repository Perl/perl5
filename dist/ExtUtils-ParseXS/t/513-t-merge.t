#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 5;
use ExtUtils::Typemaps;
use File::Spec;
use File::Temp;

my $datadir = -d 't' ? File::Spec->catdir(qw/t data/) : 'data';

sub slurp {
  my $file = shift;
  open my $fh, '<', $file
    or die "Cannot open file '$file' for reading: $!";
  local $/ = undef;
  return <$fh>;
}

my $first_typemap_file = File::Spec->catfile($datadir, 'simple.typemap');
my $second_typemap_file = File::Spec->catfile($datadir, 'other.typemap');
my $combined_typemap_file = File::Spec->catfile($datadir, 'combined.typemap');


SCOPE: {
  my $first = ExtUtils::Typemaps->new(file => $first_typemap_file);
  isa_ok($first, 'ExtUtils::Typemaps');
  my $second = ExtUtils::Typemaps->new(file => $second_typemap_file);
  isa_ok($second, 'ExtUtils::Typemaps');

  $first->merge(typemap => $second);

  is($first->as_string(), slurp($combined_typemap_file), "merging produces expected output");
}

SCOPE: {
  my $first = ExtUtils::Typemaps->new(file => $first_typemap_file);
  isa_ok($first, 'ExtUtils::Typemaps');
  my $second_str = slurp($second_typemap_file);

  $first->add_string(string => $second_str);

  is($first->as_string(), slurp($combined_typemap_file), "merging (string) produces expected output");
}

#!/perl -w
use 5.010;
use strict;

# This tests properties of dual-life modules:
#
# * Are all dual-life programs being generated in utils/?

use File::Basename;
use File::Find;
use File::Spec::Functions;
use Test::More; END { done_testing }

# Exceptions are found in dual-life bin dirs but aren't
# installed by default
my @exceptions = qw(
  ../cpan/Encode/bin/ucm2table
  ../cpan/Encode/bin/ucmlint
  ../cpan/Encode/bin/ucmsort
  ../cpan/Encode/bin/unidump
);

my @programs;

find(
  sub {
    my $name = $File::Find::name;
    return if $name =~ /blib/;
    return unless $name =~ m{/(?:bin|scripts?)/\S+\z};

    push @programs, $name;
  },
  qw( ../cpan ../dist ../ext ),
);

for my $f ( @programs ) {
  next if $f ~~ @exceptions;
  ok( -f catfile('..', 'utils', basename($f)), "$f" );
}


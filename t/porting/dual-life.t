#!/perl -w
use strict;

# This tests properties of dual-life modules:
#
# * Are all dual-life programs being generated in utils/?

use File::Basename;
use File::Find;
use File::Spec::Functions;
use Test::More; END { done_testing }

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
  ok( -f catfile('..', 'utils', basename($f)), "$f" );
}


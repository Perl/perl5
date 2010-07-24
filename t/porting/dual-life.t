#!/perl -w
use 5.010;
use strict;

# This tests properties of dual-life modules:
#
# * Are all dual-life programs being generated in utils/?

require './test.pl';

plan('no_plan');

use File::Basename;
use File::Find;
use File::Spec::Functions;

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
  $f =~ s/\.\z// if $^O eq 'VMS';
  next if qr/(?i:$f)/ ~~ @exceptions;
  $f = basename($f);
  $f .= '.com' if $^O eq 'VMS';
  ok( -f catfile('..', 'utils', $f), "$f" );
}


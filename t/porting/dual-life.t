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
my @not_installed = qw(
  ../cpan/Encode/bin/ucm2table
  ../cpan/Encode/bin/ucmlint
  ../cpan/Encode/bin/ucmsort
  ../cpan/Encode/bin/unidump
);

my %dist_dir_exe;

foreach (qw (podchecker podselect pod2usage)) {
    $dist_dir_exe{lc "$_.PL"} = "../cpan/Pod-Parser/$_";
};
foreach (qw (pod2man pod2text)) {
    $dist_dir_exe{lc "$_.PL"} = "../cpan/podlators/$_";
};
$dist_dir_exe{'pod2html.pl'} = '../ext/Pod-Html';

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

my $ext = $^O eq 'VMS' ? '.com' : '';

for my $f ( @programs ) {
  $f =~ s/\.\z// if $^O eq 'VMS';
  next if qr/(?i:$f)/ ~~ @not_installed;
  $f = basename($f);
  if(qr/\A(?i:$f)\z/ ~~ %dist_dir_exe) {
    ok( -f "$dist_dir_exe{lc $f}$ext", "$f$ext");
  } else {
    ok( -f catfile('..', 'utils', "$f$ext"), "$f$ext" );
  }
}


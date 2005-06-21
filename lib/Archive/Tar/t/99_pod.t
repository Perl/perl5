use Test::More;
use File::Spec;
use File::Find;
use strict;

eval 'use Test::Pod';
plan skip_all => "Test::Pod v0.95 required for testing POD"
    if $@ || $Test::Pod::VERSION < 0.95;

my @files;
find( sub { push @files, $File::Find::name if /\.p(?:l|m|od)$/ },
    File::Spec->catfile( qw(blib lib) ) );
plan tests => scalar @files;
for my $file ( @files ) {
    pod_file_ok( $file );
}



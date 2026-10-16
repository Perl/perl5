#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    skip_all_without_dynamic_extension($_)
      for qw(Digest::SHA Encode Time::HiRes);
}

use strict;
use warnings;
use Cwd         qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Spec;
use File::Temp qw(tempdir);

require './re/trie_bench_corpus.pl';

plan tests => 534;

my $dir      = tempdir( 'trie-corpus-XXXXXX', DIR => '.', CLEANUP => 1 );
my $manifest = TrieBenchCorpus::prepare( abs_path('..'), $dir, 32 );
my @ids      = sort keys %{ $manifest->{cases} };

is( scalar @ids, 40, 'ten corpus families in four target representations' );

for my $id (@ids) {
    my $case = TrieBenchCorpus::load_case( $dir, $id );

    is(
        0 + utf8::is_utf8( $case->{target} ),
        0 + ( $case->{encoding} !~ /^native/ ),
        "$id target flag"
    );
    is( length( $case->{target} ), $case->{characters}, "$id character count" );

    if ( $case->{encoding} eq 'native-ascii' ) {
        unlike( $case->{target}, qr/[^\x00-\x7f]/,
            "$id contains only ASCII characters" );
    }
    else {
        like( $case->{target}, qr/[\x80-\xff]/,
            "$id contains actual Latin-1 characters" );
    }

    my $non_ascii = () = $case->{target} =~ /[^\x00-\x7f]/g;
    my $wide      = () = $case->{target} =~ /[^\x00-\xff]/g;
    is( $case->{non_ascii_characters},
        $non_ascii, "$id non-ASCII character count" );
    is( $case->{wide_characters}, $wide, "$id wide character count" );
    like( $case->{target}, qr/[^\x00-\xff]/,
        "$id contains actual wide characters" )
      if $case->{encoding} eq 'utf8-wide';

    my $re = TrieBenchCorpus::compile( $case, 0 );
    my @spans;
    my $got = TrieBenchCorpus::scan( $case, $re, 1, \@spans );

    is( $got->{$_}, $case->{expected}{$_}, "$id $_" )
      for qw(matches starts lengths);
    is( sha256_hex( join( ',', @spans ) ),
        $case->{span_sha256}, "$id complete span stream" );

    my $twice = TrieBenchCorpus::scan( $case, $re, 2 );

    for my $key (qw(matches starts lengths)) {
        my $expected = $case->{expected}{$key} * 2;
        $expected &= 0x7fffffff if $key eq 'starts';
        is( $twice->{$key}, $expected, "$id repeated scan $key" );
    }
}

for my $definition ( TrieBenchCorpus::definitions() ) {
    my $name = $definition->[0];

    for my $key (qw(corpus_sha256 pattern_sha256)) {
        is(
            $manifest->{cases}{"$name.native"}{$key},
            $manifest->{cases}{"$name.utf8-latin1"}{$key},
            "$name native/upgraded pair has identical $key"
        );
    }

    is(
        $manifest->{cases}{"$name.native-ascii"}{pattern_sha256},
        $manifest->{cases}{"$name.native"}{pattern_sha256},
        "$name ASCII and Latin-1 subjects use identical dictionaries"
    );
    is(
        $manifest->{cases}{"$name.native-ascii"}{characters},
        $manifest->{cases}{"$name.native"}{characters},
        "$name ASCII conversion preserves subject length"
    );
}

eval { TrieBenchCorpus::prepare( abs_path('..'), $dir, 32 ) };
like(
    $@,
    qr/manifest already exists/,
    'refuse to overwrite an existing snapshot'
);

my $manifest_path   = File::Spec->catfile( $dir, 'manifest.json' );
my $saved_manifest  = TrieBenchCorpus::read_file($manifest_path);
my $older_generator = JSON::PP::decode_json($saved_manifest);
$older_generator->{generator_sha256} = '0' x 64;
TrieBenchCorpus::write_file( $manifest_path,
    JSON::PP::encode_json($older_generator) );
is(
    TrieBenchCorpus::load_case( $dir, $ids[0] )->{corpus_sha256},
    $manifest->{cases}{ $ids[0] }{corpus_sha256},
    'replay a frozen corpus from an older generator'
);

TrieBenchCorpus::write_file( $manifest_path, $saved_manifest );

my $case = $manifest->{cases}{ $ids[0] };
my $path = File::Spec->catfile( $dir, $case->{file} );
TrieBenchCorpus::write_file( $path,
    TrieBenchCorpus::read_file($path) . 'corrupt' );
eval { TrieBenchCorpus::load_case( $dir, $ids[0] ) };
like(
    $@,
    qr/corpus hash mismatch/,
    'detect a changed corpus instead of comparing different inputs'
);

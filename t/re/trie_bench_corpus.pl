package TrieBenchCorpus;

use strict;
use warnings;
use Config;
use Digest::SHA qw(sha256_hex);
use Encode      qw(encode decode FB_CROAK);
use File::Path  qw(make_path);
use File::Spec;
use JSON::PP;
use Time::HiRes ();

my $json      = JSON::PP->new->utf8->canonical;
my @encodings = qw(native-ascii native utf8-latin1 utf8-wide);

sub read_file {
    my ($path) = @_;

    open my $fh, '<:raw', $path or die "open $path: $!\n";
    local $/;

    return <$fh>;
}

sub write_file {
    my ( $path, $data ) = @_;

    open my $fh, '>:raw', $path or die "write $path: $!\n";
    print {$fh} $data or die "write $path: $!\n";
    close $fh         or die "close $path: $!\n";
}

sub clock {
    return
      eval { Time::HiRes::clock_gettime( Time::HiRes::CLOCK_MONOTONIC() ) }
      // Time::HiRes::time();
}

sub definitions {
    return (
        [ 'html_tokens', 'HTML tag and attribute-name searches', 'ac', 0 ],
        [
            'html_absent', 'Rare HTML/security attributes absent from the page',
            'ac',          0
        ],
        [ 'html_tags', 'Tag extraction with a leading < prefix', 'control', 1 ],
        [
            'prose_terms',
            'Technical prose terminology, trailing word boundary',
            'ac', 0
        ],
        [
            'prose_words', 'Whole-word terminology with a leading boundary',
            'control',     0
        ],
        [
            'prose_folded', 'Case-insensitive multilingual terminology', 'ac',
            1
        ],
        [
            'perl_variables',
            'Variable watchlist extracted from Porting/bench.pl',
            'ac', 0
        ],
        [
            'perl_whitespace',
            'The same Perl source with extra indentation and blank lines',
            'ac', 0
        ],
        [
            'dna_motifs',
            'Restriction sites and start/stop motifs in wrapped FASTA',
            'ac', 0
        ],
        [
            'dna_repeats',
            'The same motif list in low-complexity FASTA regions',
            'ac', 0
        ],
    );
}

sub build {
    my ( $root, $name, $wide ) = @_;

    my $intro =
      read_file( File::Spec->catfile( $root, 'pod', 'perlintro.pod' ) );
    my $source =
      read_file( File::Spec->catfile( $root, 'Porting', 'bench.pl' ) );

    my $note =
      "caf\x{e9}, na\x{ef}ve, r\x{e9}sum\x{e9}, fa\x{e7}ade, Stra\x{df}e";
    $note .= " \x{3a9} \x{4e2d}\x{6587} \x{1f600}" if $wide;

    my ( @words, $text, $prefix, $suffix );
    $prefix = $suffix = '';

    if ( $name =~ /^html_/ ) {
        @words =
          qw(article section nav aside header footer main form input button
          label table tbody thead tr td ul ol li script style link meta title
          body html figure figcaption img source video audio iframe canvas
          data-testid aria-label aria-expanded autocomplete crossorigin
          viewport charset href src class id role hidden tabindex disabled
          checked selected action method content value);

        my $paragraph = substr( $intro, 1000, 2500 );
        $paragraph =~ s/[<>&]/ /g;
        $text =
          "<!doctype html>\n<html><head><title>$note</title></head><body>\n";

        for my $i ( 1 .. 24 ) {
            $text .=
              "<section id=\"item-$i\" class=\"card\" data-testid=\"entry\">\n"
              . "  <header><h2>$note $i</h2></header>\n"
              . "  <article><p>$paragraph</p><a href=\"/entry/$i\">Details</a></article>\n"
              . "  <form action=\"/submit\" method=\"post\"><label>Name</label>\n"
              . "    <input autocomplete=\"name\"><button>Save</button></form>\n"
              . "</section>\n";
        }

        $text .= "</body></html>\n";

        if ( $name eq 'html_absent' ) {
            @words =
              qw(onpointerrawupdate onbeforexrselect onsecuritypolicyviolation
              feDisplacementMap feComponentTransfer http-equiv integrity nonce
              sandbox referrerpolicy allowfullscreen credentialless);
        }
        elsif ( $name eq 'html_tags' ) {
            @words =
              qw(article section nav aside header footer main form input button
              label table tbody thead tr td ul ol li script style link meta title
              body html figure figcaption img source video audio iframe canvas);

            $prefix = '</?';
        }

        $suffix = '\\b';
    }
    elsif ( $name =~ /^prose_/ ) {
        $text =
"$note. STRASSE and CAF\x{c9} appear in translated documentation.\n$intro";
        $text =~ s/^=\w+[^\n]*\n//mg;
        $text =~ s/\b[A-Z]<([^<>]*)>/$1/g for 1 .. 3;

        @words = (
            qw(variable scalar array hash reference package function subroutine
              module Unicode encoding pattern regular expression scope lexical return
              argument filename string number operator context list file program
              input output warning example document),
            "caf\x{e9}",   "r\x{e9}sum\x{e9}", "Stra\x{df}e", "na\x{ef}ve",
            "fa\x{e7}ade", "\x{3a9}",          "\x{4e2d}\x{6587}"
        );

        # Wide folded literals can compile into separate REQ8 branches and
        # prevent AC conversion. Keep this folding watchlist Latin-1; the
        # exact watchlists still include wide terms, and all scan wide text.
        @words  = grep { !/[^\x00-\xff]/ } @words if $name eq 'prose_folded';
        $prefix = '\\b'                           if $name eq 'prose_words';
        $suffix = '\\b';
    }
    elsif ( $name =~ /^perl_/ ) {
        my %vars;

        while ( $source =~ /\b(?:my|our)\s+(\([^;]*?\)|[\$\@%][A-Za-z_]\w*)/sg )
        {
            $vars{$_} = 1 for $1 =~ /([\$\@%][A-Za-z_]\w*)/g;
        }

        for my $sigil ( '$', '@', '%' ) {
            my @group = sort grep { substr( $_, 0, 1 ) eq $sigil } keys %vars;
            splice @group, 40 if @group > 40;
            push @words, @group;
        }

        die "source watchlist is too small\n" if @words < 20;

        $text = "# Internationalized comments: $note\n$source";
        $text =~ s/^/                        /mg if $name eq 'perl_whitespace';
        $text =~ s/\n/\n\n\n/g                   if $name eq 'perl_whitespace';
        $suffix = '(?!\\w)';
    }
    elsif ( $name =~ /^dna_/ ) {
        @words = qw(ATG TAA TAG TGA TATAAA AATAAA CCAAT GAATTC GGATCC AAGCTT
          GGTCTC CGTCTC CACGTG GCGGCCGC GATATC CTGCAG GTCGAC ACTAGT
          TCATGA GCCACC GGCC CCGG GATC TCGA);

        my $seed = 1729;
        $text = '';

        for my $record ( 1 .. 64 ) {
            $text .= ">gene_$record $note\n";
            my $seq = '';

            for ( 1 .. 960 ) {
                $seed = ( 1664525 * $seed + 1013904223 ) % 4294967296;
                $seq .= substr( 'ACGT', int( $seed / 65536 ) % 4, 1 );
            }

            $seq = ( 'N' x 180 ) . ( 'AT' x 90 ) . substr( $seq, 360 )
              if $name eq 'dna_repeats';
            substr( $seq, 480, 24 ) = 'GAATTCATGGGATCCAAGCTTTGAA';
            $seq =~ s/(.{60})/$1\n/g;
            $text .= "$seq\n";
        }
    }
    else { die "unknown corpus $name\n" }

    @words = sort { length($b) <=> length($a) || $a cmp $b } @words;
    my $pattern =
        $prefix . '(?:'
      . join( '|', map { quotemeta($_) } @words ) . ')'
      . $suffix;

    return ( $text, $pattern, scalar @words );
}

sub compile {
    my ( $case, $off, $debug ) = @_;

    local ${^RE_TRIE_MAXBUF} = $off ? -1 : 65536;
    my $pattern = $case->{pattern};
    my $code    = ( $debug ? "use re 'debug'; " : '' )
      . ( $case->{fold} ? 'qr/$pattern/iu' : 'qr/$pattern/u' );
    my $re = eval $code;
    die "compile $case->{id}: $@\n" if $@;

    return $re;
}

sub scan {
    my ( $case, $re, $repeats, $spans ) = @_;

    my ( $count, $starts, $lengths ) = ( 0, 0, 0 );
    my $target = \$case->{target};

    for ( 1 .. $repeats ) {
        pos($$target) = 0;

        while ( $$target =~ /$re/g ) {
            ++$count;
            $starts = ( $starts + $-[0] ) & 0x7fffffff;
            $lengths += $+[0] - $-[0];
            push @$spans, "$-[0]:$+[0]" if $spans;
        }
    }

    return { matches => $count, starts => $starts, lengths => $lengths };
}

sub check {
    my ( $case, $got, $repeats ) = @_;

    for my $key (qw(matches starts lengths)) {
        my $expected = $case->{expected}{$key} * $repeats;
        $expected &= 0x7fffffff if $key eq 'starts';

        die "$case->{id}: $key: got $got->{$key}, expected $expected\n"
          unless $got->{$key} == $expected;
    }
}

sub prepare {
    my ( $root, $dir, $kib ) = @_;

    die "corpus size must be 1..4096 KiB\n"
      unless $kib =~ /^\d+$/ && $kib >= 1 && $kib <= 4096;

    make_path($dir);
    die "manifest already exists in $dir\n"
      if -e File::Spec->catfile( $dir, 'manifest.json' );

    my $manifest = {
        schema           => 1,
        kib              => 0 + $kib,
        cases            => {},
        sources          => {},
        generator_sha256 => sha256_hex( read_file(__FILE__) )
    };

    for my $file ( 'Porting/bench.pl', 'pod/perlintro.pod' ) {
        $manifest->{sources}{$file} = sha256_hex(
            read_file( File::Spec->catfile( $root, split '/', $file ) ) );
    }

    for my $definition ( definitions() ) {
        my ( $name, $description, $role, $fold ) = @$definition;

        for my $encoding (@encodings) {
            my ( $unit, $pattern, $alternatives ) =
              build( $root, $name, $encoding eq 'utf8-wide' );
            my $target =
              substr( $unit x ( 1 + int( $kib * 1024 / length($unit) ) ),
                0, $kib * 1024 );

            if ( $encoding eq 'native-ascii' ) {

                # Keep the dictionary and character offsets unchanged while
                # making the subject entirely ASCII. The accented fixture
                # letters have single-character ASCII counterparts here.
                $target =~ tr/\x{e9}\x{ef}\x{e7}\x{df}\x{c9}/eicsE/;
                $target =~ s/[^\x00-\x7f]/ /g;
            }
            else {
                die "fixture lost its Latin-1 text: $name\n"
                  unless $target =~ /[\x80-\xff]/;
            }

            die "fixture lost its wide text: $name\n"
              if $encoding eq 'utf8-wide' && $target !~ /[^\x00-\xff]/;

            utf8::downgrade( $target, 1 )
              or die "not native: $name\n"
              if $encoding =~ /^native/;
            utf8::upgrade($target) if $encoding !~ /^native/;

            my $id      = "$name.$encoding";
            my $encoded = encode( 'UTF-8', $target );
            my $case    = {
                id             => $id,
                name           => $name,
                description    => $description,
                encoding       => $encoding,
                role           => $role,
                fold           => 0 + $fold,
                alternatives   => $alternatives,
                pattern        => $pattern,
                pattern_sha256 => sha256_hex( encode( 'UTF-8', $pattern ) ),
                corpus_sha256  => sha256_hex($encoded),
                characters     => length($target),
                non_ascii_characters =>
                  scalar( () = $target =~ /[^\x00-\x7f]/g ),
                wide_characters => scalar( () = $target =~ /[^\x00-\xff]/g ),
                octets          => do { use bytes; length($target) },
                file            => "$id.utf8",
                target          => $target
            };

            my ( @plain, @trie );
            $case->{expected} = scan( $case, compile( $case, 1 ), 1, \@plain );
            check( $case, scan( $case, compile( $case, 0 ), 1, \@trie ), 1 );

            die "span mismatch: $id\n"
              unless join( ',', @plain ) eq join( ',', @trie );
            $case->{span_sha256} = sha256_hex( join( ',', @plain ) );

            write_file( File::Spec->catfile( $dir, $case->{file} ), $encoded );
            delete $case->{target};
            $manifest->{cases}{$id} = $case;
        }
    }

    write_file( File::Spec->catfile( $dir, 'manifest.json' ),
        $json->encode($manifest) );

    return $manifest;
}

sub load_case {
    my ( $dir, $id ) = @_;

    my $manifest = $json->decode(
        read_file( File::Spec->catfile( $dir, 'manifest.json' ) ) );

    # The generator hash records provenance. Frozen inputs remain replayable
    # after generator changes; validate their stored schema and hashes instead.
    die "unsupported corpus schema\n" unless $manifest->{schema} == 1;

    my $saved = $manifest->{cases}{$id} or die "unknown case $id\n";
    my %case  = %$saved;

    die "pattern hash mismatch: $id\n"
      unless sha256_hex( encode( 'UTF-8', $case{pattern} ) ) eq
      $case{pattern_sha256};

    my $bytes = read_file( File::Spec->catfile( $dir, $case{file} ) );
    die "corpus hash mismatch: $id\n"
      unless sha256_hex($bytes) eq $case{corpus_sha256};

    $case{target} = decode( 'UTF-8', $bytes, FB_CROAK );

    if ( $case{encoding} =~ /^native(?:-ascii)?$/ ) {
        utf8::downgrade( $case{target}, 1 ) or die "not native: $id\n";
    }
    else { utf8::upgrade( $case{target} ) }

    return \%case;
}

sub main {
    my ( $root, $action, @args ) = @_;

    if ( $action eq 'prepare' ) {
        print $json->encode( prepare( $root, $args[0], $args[1] // 32 ) ), "\n";
        return;
    }

    if ( $action eq 'config' ) {
        my $options = eval { join ' ', Internals::V() } // '';

        print $json->encode(
            {
                version         => "$^V",
                executable      => $^X,
                compile_options => $options,
                debugging       => 0 + !!(
                    $options =~ /\bDEBUGGING\b/
                    || ( $Config{ccflags} // '' ) =~ /(?:^|\s)-DDEBUGGING\b/
                ),
                threaded => 0 + !!(
                    ( $Config{useithreads} // '' ) eq 'define'
                    || $options =~ /\bUSE_ITHREADS\b/
                ),
                map { $_ => $Config{$_} // '' }
                  qw(archname cc ccflags optimize
                  useithreads usemultiplicity use64bitint use64bitall git_commit_id)
            }
          ),
          "\n";
        return;
    }

    my ( $dir, $id, $repeats ) = @args;
    my $case = load_case( $dir, $id );
    my $re   = compile( $case, 0, $action eq 'explain' );

    if ( $action eq 'explain' ) {
        print $json->encode( { id => $id } ), "\n";
        return;
    }

    die "repeats must be 1..1000000\n"
      unless defined($repeats)
      && $repeats =~ /^\d+$/
      && $repeats >= 1
      && $repeats <= 1000000;

    my @spans;

    if ( $action eq 'verify' ) {
        my $got = scan( $case, $re, 1, \@spans );
        check( $case, $got, 1 );
        die "span hash mismatch: $id\n"
          unless sha256_hex( join( ',', @spans ) ) eq $case->{span_sha256};
    }
    elsif ( $action ne 'run' ) { die "unknown corpus action $action\n" }

    my $start   = clock();
    my $got     = scan( $case, $re, $repeats );
    my $elapsed = clock() - $start;

    check( $case, $got, $repeats );

    print $json->encode(
        {
            %$got,
            id             => $id,
            repeats        => 0 + $repeats,
            elapsed        => $elapsed,
            corpus_sha256  => $case->{corpus_sha256},
            pattern_sha256 => $case->{pattern_sha256},
            utf8           => 0 + utf8::is_utf8( $case->{target} )
        }
      ),
      "\n";
}

1;

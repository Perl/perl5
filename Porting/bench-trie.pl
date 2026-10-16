#!/usr/bin/env perl

use strict;
use warnings;
use Cwd qw(abs_path);
use Data::Dumper;
use Digest::SHA    qw(sha256_hex);
use File::Basename qw(dirname);
use File::Path     qw(make_path);
use File::Spec;
use Getopt::Long qw(GetOptions);
use IO::Handle;
use JSON::PP;
use POSIX qw(ceil strftime);

my ( @perls,  @args,    $out, $base, $cpu, $perf, $report, $help );
my ( $runs,   $seconds, $size ) = ( 12, 0.05, 32 );
my ( $wanted, $encodings ) =
  ( '', 'native-ascii,native,utf8-latin1,utf8-wide' );

GetOptions(
    'perl=s@'    => \@perls,
    'arg=s@'     => \@args,
    'out=s'      => \$out,
    'base=s'     => \$base,
    'cpu=i'      => \$cpu,
    'perf!'      => \$perf,
    'runs=i'     => \$runs,
    'seconds=f'  => \$seconds,
    'size=i'     => \$size,
    'case=s'     => \$wanted,
    'encoding=s' => \$encodings,
    'report=s'   => \$report,
    'help'       => \$help
) or die "See --help\n";

if ($help) {
    print
"Usage: perl $0 --perl before=/path/perl --perl after=/path/perl [options]\n"
      . "  --arg label=argument     Extra argument (repeatable, e.g. before=-Ilib)\n"
      . "  --base label            Baseline (default: first Perl)\n"
      . "  --case name,name        Select corpus families\n"
      . "  --encoding name,name    native-ascii,native,utf8-latin1,utf8-wide (default: all)\n"
      . "  --runs N --seconds S    Samples and target scan time (default: 12, 0.05)\n"
      . "  --size KiB --out DIR    Fixture size (default: 32) and result directory\n"
      . "  --cpu N --perf          Optional Linux CPU affinity and counters\n"
      . "  --report DIR            Regenerate report from saved samples\n"
      . "See perldoc $0 for methodology and instruction profiling.\n";
    exit;
}

my $json      = JSON::PP->new->canonical->utf8;
my $root      = dirname( dirname( abs_path($0) ) );
my $worker    = File::Spec->catfile( $root, 't', 're', 'trie_bench.pl' );
my $module    = File::Spec->catfile( $root, 't', 're', 'trie_bench_corpus.pl' );
my $dumbbench = eval { require Dumbbench::Stats; 1 };

sub read_file {
    open my $fh, '<:raw', $_[0] or die "open $_[0]: $!\n";

    local $/;

    return <$fh>;
}

sub write_file {
    open my $fh, '>:raw', $_[0] or die "write $_[0]: $!\n";
    print {$fh} $_[1] or die "write $_[0]: $!\n";
    close $fh         or die "close $_[0]: $!\n";
}

sub median {
    my @v = sort { $a <=> $b } @_;

    return @v % 2
      ? $v[ @v / 2 ]
      : ( $v[ @v / 2 - 1 ] + $v[ @v / 2 ] ) / 2;
}

sub estimate {
    my @values = @_;
    my @good   = @values;

    if ($dumbbench) {
        my ($good) =
          Dumbbench::Stats->new( data => \@values )->filter_outliers(
            variability_measure => 'mad',
            nsigma_outliers     => 3
          );

        @good = @$good if @$good;
    }

    my $mean = 0;
    $mean += $_ / @good for @good;

    my $mid = median(@good);
    my $mad = median( map { abs( $_ - $mid ) } @good );

    return ( $mean, $mad / sqrt(@good), scalar @good );
}

sub render {
    my ($directory) = @_;

    my $meta = $json->decode(
        read_file( File::Spec->catfile( $directory, 'run.json' ) ) );

    if ( exists $meta->{stats_filter} ) {
        die "This run's report needs Dumbbench::Stats\n"
          if $meta->{stats_filter} eq 'dumbbench-3mad' && !$dumbbench;
        $dumbbench = $meta->{stats_filter} eq 'dumbbench-3mad';
    }

    my %samples;
    for my $line ( split /\n/,
        read_file( File::Spec->catfile( $directory, 'samples.jsonl' ) ) )
    {
        my $row = $json->decode($line);
        $samples{ $row->{id} }{ $row->{label} }{ $row->{trial} } = $row;
    }

    my $text =
        "# Trie corpus comparison\n\nBaseline: `$meta->{base}`. "
      . "Target: $meta->{seconds} seconds/sample, $meta->{runs} interleaved samples.\n\n"
      . "Elapsed time includes scanning and offset/length accumulation; corpus loading, "
      . "decoding, compilation and validation are outside the timed region. "
      . "Perf counters, when requested, cover the whole child process.\n\n"
      . "Paired changes use "
      . ( $dumbbench ? 'Dumbbench 3-MAD filtering' : 'unfiltered samples' )
      . "; uncertainties are MAD/sqrt(n), not confidence intervals. "
      . "Each case has its own baseline; no overall average hides regressions.\n\n"
      . "| Case | Perl | Start class | Base ms | Perl ms | Time change % | n |\n"
      . "|---|---|---|---:|---:|---:|---:|\n";

    for my $id ( @{ $meta->{cases} } ) {
        for my $label ( @{ $meta->{order} } ) {
            next if $label eq $meta->{base};

            my ( @before, @after, @changes );

            for my $trial ( 0 .. $meta->{runs} - 1 ) {
                my $a = $samples{$id}{ $meta->{base} }{$trial} or next;
                my $b = $samples{$id}{$label}{$trial}          or next;

                push @before,  $a->{elapsed};
                push @after,   $b->{elapsed};
                push @changes, 100 * ( $b->{elapsed} / $a->{elapsed} - 1 );
            }

            next unless @changes;

            my ( $change, $uncertainty, $n ) = estimate(@changes);
            my $stclass = $meta->{engines}{$id}{$label} // 'unknown';

            $text .=
              sprintf
              "| %s | %s | %s | %.3f | %.3f | %+.2f +/- %.2f | %d/%d |\n",
              $id, $label, $stclass, 1000 * median(@before),
              1000 * median(@after),
              $change, $uncertainty, $n, scalar @changes;
        }
    }

    if ( $meta->{perf} ) {
        $text .=
            "\n## Whole-process hardware counters\n\n"
          . "Paired percentage changes include startup, loading and compilation. "
          . "Use the Cachegrind export to subtract setup for scan instruction counts.\n\n"
          . "| Case | Perl | Cycles % | Instructions % | Branch misses % |\n"
          . "|---|---|---:|---:|---:|\n";

        for my $id ( @{ $meta->{cases} } ) {
            for my $label ( grep { $_ ne $meta->{base} } @{ $meta->{order} } ) {
                my @cells;
                for
                  my $event ( 'cycles:u', 'instructions:u', 'branch-misses:u' )
                {
                    my @changes;

                    for my $trial ( 0 .. $meta->{runs} - 1 ) {
                        my $a =
                          $samples{$id}{ $meta->{base} }{$trial}{perf}{$event};
                        my $b = $samples{$id}{$label}{$trial}{perf}{$event};

                        push @changes, 100 * ( $b / $a - 1 )
                          if $a && defined $b;
                    }

                    push @cells,
                      @changes
                      ? sprintf( '%+.2f +/- %.2f',
                        ( estimate(@changes) )[ 0, 1 ] )
                      : 'n/a';
                }

                $text .= '| ' . join( ' | ', $id, $label, @cells ) . " |\n";
            }
        }
    }

    my $manifest = $json->decode(
        read_file(
            File::Spec->catfile(
                $directory, $meta->{corpus_subdir} // 'corpus',
                'manifest.json'
            )
        )
    );

    $text .=
        "\n## Workloads\n\n"
      . "Sizes are target storage bytes; matches and characters are per scan.\n\n"
      . "| Case | Bytes | Characters | Codepoints >=128 | Codepoints >255 | Alternatives | Matches | Baseline start class |\n"
      . "|---|---:|---:|---:|---:|---:|---:|---|\n";

    for my $id ( @{ $meta->{cases} } ) {
        my $case = $manifest->{cases}{$id};

        $text .= '| '
          . join( ' | ',
            $id,
            @{$case}{qw(octets characters)},
            $case->{non_ascii_characters} // 'unknown',
            $case->{wide_characters}      // 'unknown',
            $case->{alternatives},
            $case->{expected}{matches},
            $meta->{engines}{$id}{ $meta->{base} } // 'unknown' )
          . " |\n";
    }

    $text .= "\n## Build configurations\n\n";

    for my $label ( @{ $meta->{order} } ) {
        my $p = $meta->{perls}{$label};

        $text .=
            "- `$label`: `$p->{config}{version}`, `$p->{binary}`; "
          . "optimize=`$p->{config}{optimize}`, threads=`$p->{config}{useithreads}`, "
          . "debugging="
          . (
            exists $p->{config}{debugging}
            ? ( $p->{config}{debugging} ? 'on' : 'off' )
            : 'unrecorded'
          )
          . ", "
          . "arch=`$p->{config}{archname}`; binary SHA-256 `$p->{sha256}`.\n";
    }

    $text .=
        "\nFull flags, corpus/pattern hashes, checksums, repetition counts, "
      . "start-class traces and raw samples are in this run directory. "
      . "Different compilers/build flags make historical comparisons contextual; "
      . "matched before/after builds isolate the current patch.\n";

    write_file( File::Spec->catfile( $directory, 'report.md' ), $text );
    print $text;
}

if ($report) { render( abs_path($report) ); exit }

die "Specify at least two --perl label=/path/to/perl options\n"
  unless @perls >= 2;
die "runs must be >= 6; seconds must be positive\n"
  unless $runs >= 6 && $seconds > 0;

my ( %p, @order );

for my $spec (@perls) {
    my ( $label, $binary ) = split /=/, $spec, 2;

    die "bad or duplicate --perl $spec\n"
      unless defined($binary)
      && $label =~ /^[A-Za-z0-9_-]+$/
      && !$p{$label};

    $binary = abs_path($binary) // die "no such Perl: $binary\n";
    die "not executable: $binary\n" unless -x $binary;

    $p{$label} = {
        binary => $binary,
        args   => [],
        sha256 => sha256_hex( read_file($binary) )
    };
    push @order, $label;
}

for my $spec (@args) {
    my ( $label, $arg ) = split /=/, $spec, 2;
    die "bad --arg $spec\n" unless defined($arg) && $p{$label};
    push @{ $p{$label}{args} }, $arg;
}

$base //= $order[0];
die "unknown baseline $base\n" unless $p{$base};

$out //= File::Spec->catdir( $root, 'tmp',
    strftime( 'trie-corpus-%Y%m%d-%H%M%S', localtime ) );
make_path($out);
$out = abs_path($out);
die "run.json already exists in $out; use --report or a new directory\n"
  if -e File::Spec->catfile( $out, 'run.json' );
make_path( File::Spec->catdir( $out, 'logs' ) );

local $ENV{PERL_HASH_SEED}    = 0;
local $ENV{PERL_PERTURB_KEYS} = 0;
local $ENV{LC_ALL}            = 'C';
local @ENV{qw(PERL5OPT PERL5LIB PERLLIB PERL_UNICODE TRIE_BENCH_MODE)};
delete @ENV{qw(PERL5OPT PERL5LIB PERLLIB PERL_UNICODE TRIE_BENCH_MODE)};

sub command {
    my ( $label, @tail ) = @_;

    my @command = (
        $p{$label}{binary},
        @{ $p{$label}{args} },
        $worker, '--corpus', @tail
    );
    unshift @command, ( 'taskset', '-c', $cpu ) if defined $cpu;

    return @command;
}

sub invoke {
    my ( $log, @command ) = @_;
    my $data;

    {
        my $pid = open my $child, '-|';
        die "fork: $!\n" unless defined $pid;

        if ( !$pid ) {
            open STDERR, '>:raw', $log or die "write $log: $!\n";
            exec { $command[0] } @command;
            die "exec $command[0]: $!\n";
        }

        local $/;
        $data = <$child>;
        close $child or die "child failed; see $log\n";
    }

    return $json->decode($data);
}

for my $label (@order) {
    $p{$label}{config} =
      invoke( File::Spec->catfile( $out, 'logs', "$label.config" ),
        command( $label, 'config' ) );

    die "$label is a debugging Perl; use a nondebugging build\n"
      if $p{$label}{config}{debugging};
    die "$label is a threaded Perl; use an unthreaded build\n"
      if $p{$label}{config}{threaded};
}

my $corpus   = File::Spec->catdir( $out, '.corpus' );
my $manifest = invoke(
    File::Spec->catfile( $out, 'logs', 'prepare' ),
    command( $base, 'prepare', $corpus, $size )
);

my %names    = map           { $_->{name} => 1 } values %{ $manifest->{cases} };
my %selected = $wanted ? map { $_         => 1 } split( /,/, $wanted ) : %names;
die "unknown case $_\n" for grep { !$names{$_} } keys %selected;

my %enc = map { $_ => 1 } split /,/, $encodings;
die "unknown encoding $_\n"
  for grep { !/^(?:native-ascii|native|utf8-latin1|utf8-wide)$/ } keys %enc;

my @cases = sort grep {
         $selected{ $manifest->{cases}{$_}{name} }
      && $enc{ $manifest->{cases}{$_}{encoding} }
  }
  keys %{ $manifest->{cases} };
die "no cases selected\n" unless @cases;

my $meta = {
    schema           => 1,
    base             => $base,
    runs             => $runs,
    seconds          => $seconds,
    perls            => \%p,
    order            => \@order,
    cases            => \@cases,
    engines          => {},
    repetitions      => {},
    cpu              => $cpu,
    perf             => 0 + !!$perf,
    corpus_subdir    => '.corpus',
    generator_sha256 => sha256_hex( read_file($module) ),
    driver_sha256    => sha256_hex( read_file(__FILE__) ),
    started          => strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime ),
    stats_filter     => $dumbbench ? 'dumbbench-3mad' : 'none'
};

# Export this exact frozen corpus to the existing instruction-profiling tool.
my @grind;

for my $id (@cases) {
    my $name = $id;
    $name =~ s/[^A-Za-z0-9_]/_/g;

    my $quote =
      sub { Data::Dumper->new( [ $_[0] ] )->Terse(1)->Useqq(1)->Dump };
    my $setup =
        'require '
      . $quote->($module)
      . '; my $case = TrieBenchCorpus::load_case('
      . $quote->($corpus) . ', '
      . $quote->($id)
      . '); my $re = TrieBenchCorpus::compile($case, 0);';

    push @grind, "regex::ac_corpus::$name",
      {
        desc  => $manifest->{cases}{$id}{description},
        setup => $setup,
        code  =>
'my $got = TrieBenchCorpus::scan($case, $re, 1); TrieBenchCorpus::check($case, $got, 1);'
      };
}

write_file(
    File::Spec->catfile( $out, 'cachegrind-benchmarks' ),
    Data::Dumper->new( [ \@grind ] )->Terse(1)->Useqq(1)->Dump
);
write_file( File::Spec->catfile( $out, 'run.json' ), $json->encode($meta) );

open my $samples, '>:raw', File::Spec->catfile( $out, 'samples.jsonl' )
  or die "$!\n";
$| = 1;

for my $id (@cases) {
    for my $label (@order) {
        invoke(
            File::Spec->catfile( $out, 'logs', "$id.$label.verify" ),
            command( $label, 'verify', $corpus, $id, 1 )
        );

        my $trace = File::Spec->catfile( $out, 'logs', "$id.$label.explain" );
        invoke( $trace, command( $label, 'explain', $corpus, $id ) );

        my $debug = read_file($trace);
        my ($stclass) = $debug =~ /^stclass\s+([^\s]+)/m;
        $meta->{engines}{$id}{$label} = $stclass
          // ( $debug =~ /^anchored /m ? 'anchored-prefix' : 'none' );

        die "expected AC start class: $id ($label); see $trace\n"
          if $manifest->{cases}{$id}{role} eq 'ac'
          && ( $stclass // '' ) !~ /^AHOCORASICK/;
    }
}

write_file( File::Spec->catfile( $out, 'run.json' ), $json->encode($meta) );

print "Verified all match spans and start classes across "
  . scalar(@order)
  . " Perls.\n";
printf "Measuring %d cases x %d Perls x %d samples = %d samples.\n",
  scalar(@cases), scalar(@order), $runs, @cases * @order * $runs;

my $case_number = 0;

for my $id (@cases) {
    my ( $calibration, $slowest );

    for my $label (@order) {
        my $sample =
          invoke( File::Spec->catfile( $out, 'logs', "$id.$label.calibrate" ),
            command( $label, 'run', $corpus, $id, 1 ) );

        if ( !$calibration || $sample->{elapsed} > $calibration->{elapsed} ) {
            ( $calibration, $slowest ) = ( $sample, $label );
        }
    }

    my $repeats = ceil( $seconds / ( $calibration->{elapsed} || 0.000001 ) );
    $repeats = 1000000 if $repeats > 1000000;
    $meta->{repetitions}{$id} = $repeats;
    write_file( File::Spec->catfile( $out, 'run.json' ), $json->encode($meta) );

    printf "[%d/%d] %s: calibrated %.3f seconds/sample for %s (%d scans)\n",
      ++$case_number, scalar(@cases), $id, $calibration->{elapsed} * $repeats,
      $slowest, $repeats;
    warn
"$id ($slowest): one scan exceeds twice --seconds; consider a smaller --size\n"
      if $calibration->{elapsed} > 2 * $seconds;

    for my $label (@order) {
        invoke(
            File::Spec->catfile( $out, 'logs', "$id.$label.warmup" ),
            command( $label, 'run', $corpus, $id, $repeats )
        );
    }

    for my $trial ( 0 .. $runs - 1 ) {
        for my $offset ( 0 .. $#order ) {
            my $label   = $order[ ( $trial + $offset ) % @order ];
            my @command = command( $label, 'run', $corpus, $id, $repeats );
            my $stem = File::Spec->catfile( $out, 'logs', "$id.$label.$trial" );

            unshift @command,
              (
                'perf',
                'stat',
                '-x',
                ',',
                '-e',
'cycles:u,instructions:u,branches:u,branch-misses:u,task-clock,context-switches,cpu-migrations',
                '-o',
                "$stem.perf",
                '--'
              ) if $perf;

            my $row = invoke( "$stem.stderr", @command );
            $row->{label} = $label;
            $row->{trial} = $trial;

            if ($perf) {
                for my $line ( split /\n/, read_file("$stem.perf") ) {
                    my @fields = split /,/, $line;
                    next unless @fields > 2 && $fields[0] =~ /^\d+(?:\.\d+)?$/;

                    $row->{perf}{ $fields[2] } = 0 + $fields[0];
                }

                die "perf counters unavailable: $stem.perf\n"
                  unless $row->{perf}{'cycles:u'};
            }

            print {$samples} $json->encode($row), "\n" or die "$!\n";
        }
    }

    $samples->flush or die "$!\n";
    print "$id: $repeats scans/sample, $runs samples/Perl\n";
}

close $samples or die "$!\n";
render($out);

__END__

=head1 NAME

bench-trie.pl - Compare corpus scanning across Perl builds

=head1 SYNOPSIS

  perl Porting/bench-trie.pl \
    --perl before=/path/to/before/perl --arg before=-I/path/to/core/lib \
    --perl after=/path/to/after/perl --arg after=-I/path/to/core/lib \
    --base before --cpu 2 --perf --out tmp/trie-corpus-run

  perl Porting/bench-trie.pl --report tmp/trie-corpus-run

=head1 DESCRIPTION

Extends F<t/re/trie_bench.pl> with a small reproducible corpus basket. It does
not replace the existing short-string, compilation, large-alternation or
Statistics::Regression benchmarks. It requires Perl 5.14 or later and core
modules; installed Dumbbench::Stats is optional for outlier filtering.

The ten corpus families cover HTML tokens and rare attributes, prefixed HTML
tag extraction, technical prose terminology, whole-word searches, Unicode
folding, a variable watchlist extracted from real Perl source, whitespace-heavy
source, and balanced/repetitive FASTA. All have ASCII-only native-byte,
native-byte Latin-1 containing characters above 127, UTF-8-flagged Latin-1,
and genuinely wide UTF-8 variants. DNA bases remain ASCII; FASTA
descriptions carry the non-ASCII text. Motifs do not cross line breaks.

HTML and FASTA are deterministic generated fixtures. Prose comes from
F<pod/perlintro.pod>; variables and source come from F<Porting/bench.pl>.
Internationalized comments/text are added. C<native-ascii> transliterates the
accented fixture letters to single ASCII characters and replaces remaining
non-ASCII characters with spaces, preserving offsets and the pattern dictionary.
C<native> retains characters in 128..255 with the UTF-8 flag off. These are
mixed ASCII/Latin-1 texts, not texts consisting entirely of high bytes. Reports
include non-ASCII and wide character counts. The native and UTF-8-Latin-1 pair
has identical characters and patterns. Wide variants include Greek, CJK and
emoji text. The run freezes UTF-8 fixture files, patterns, SHA-256 hashes,
expected counts, offsets and lengths in F<.corpus/manifest.json>. The fixture
directory is hidden so source POD copied into the corpus is not mistaken for
distribution documentation by the porting checks.

Preparation compares every match span with trie construction disabled.
Each executable then validates its own complete span stream before timing.
Measured scans accumulate match counts, offsets and lengths rather than
running an empty match loop. Every sample checks those results. Corpus setup,
decoding, pattern compilation and validation are outside the timed region.

Leading word boundaries and shared literal prefixes can disable AC. The tool
records actual start-class traces for every Perl/case and includes those
patterns as controls. Cases intended to exercise AC must actually select it.
It does not silently remove a realistic boundary to improve the result.
The folded watchlist uses Latin-1 terms against all four text encodings;
mixing wide folded literals can create separate branches and prevent AC.
Exact prose watchlists include wide terms as well.

Use C<--case=perl_variables,dna_motifs> and
C<--encoding=native-ascii,native> to compare ASCII-only and high-byte-containing
native subjects. C<--encoding=utf8-latin1,utf8-wide> selects the UTF-8 subjects.
C<--runs> defaults to 12;
C<--seconds> to 0.05; C<--size> to 32 KiB characters per fixture. The slowest
executable calibrates one repetition count used by all executables. Faster
builds may take less than the target time. Their order rotates
between samples, with warmup and deterministic hash settings. Raw data is
retained in F<samples.jsonl>; the report keeps each workload separate.
The default is a screening run comparing two builds. Add older release Perls
when a historical comparison is needed. Confirm questionable cases with
C<--case>, C<--runs=20> and C<--seconds=0.2>, rather than lengthening the whole
basket. Use C<--size> explicitly to study larger inputs or cache effects.
The time target is approximate: a single scan is the minimum sample, and dense
UTF-8 matches can become disproportionately expensive as input size grows.
Calibration prints the expected slowest scan time before measuring each case.
Child processes ignore inherited Perl library, startup-option, Unicode-I/O
and C<TRIE_BENCH_MODE> environment settings; supply explicit C<--arg> options.

Perl executables and their extra arguments are explicit: repeat
C<--arg label=argument> as necessary. Give core-build library paths only to
the corresponding builds; installed Perls should use their own libraries.
Build versions, flags, threading and executable hashes are recorded. Historical
build differences are context, not evidence isolating a compiler optimization.
Measured executables must be unthreaded and nondebugging; the runner checks
their configuration and compile options and rejects unsuitable builds.

C<--cpu> optionally uses Linux taskset. C<--perf> adds Linux perf user-mode
counters; these cover the whole process, including setup. They are not the
same measurement as the internal scan timer. Do not run wall-time and
Cachegrind jobs concurrently on the measured CPU.
Raw samples also retain task-clock milliseconds, context switches and CPU
migrations to help assess interference from other activity.

=head1 DETAILED INSTRUCTION PROFILING

Every run emits F<cachegrind-benchmarks> using the existing F<Porting/bench.pl>
format and the same frozen corpus. Its setup/loop subtraction isolates scanning
from fixture loading and compilation. For example, select a few cases first:

  perl Porting/bench.pl \
    --benchfile=tmp/trie-corpus-run/cachegrind-benchmarks \
    --tests='/perl_variables_native|prose_folded_utf8_wide/' \
    --fields=Ir,Dr,Dw,COND,COND_m \
    --write=tmp/trie-corpus-instructions.json \
    /path/to/before/perl=before --args=-I/path/to/core/lib \
    /path/to/after/perl=after --args=-I/path/to/core/lib

Read the saved instruction results using the existing C<--read>, C<--fields>,
C<--norm> and C<--sort> options. Cachegrind counts explain work and simulated
cache/branch behavior; they do not measure native CPU cycles.

Individual workers are also available for perf record/annotate:

  ./perl -Ilib t/re/trie_bench.pl --corpus run \
    tmp/trie-corpus-run/.corpus perl_variables.native 100

=cut

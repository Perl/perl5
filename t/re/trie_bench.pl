#!./perl

use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;

my $has_octet_trie;
BEGIN {
    my $internals_v = eval { join ' ', Internals::V() } // '';
    $has_octet_trie = $internals_v =~ /\bPERL_REGEX_OCTET_TRIE\b/;
    if (defined(my $mode = $ENV{TRIE_BENCH_MODE})) {
        my %maxbuf = (default => undef, off => -1, list => 0,
            table => 655360, trie => undef);
        die "unknown TRIE_BENCH_MODE '$mode'\n"
            unless exists $maxbuf{$mode};
        my $effective_mode = $mode;
        $effective_mode = 'trie'
            if $mode eq 'list' && $has_octet_trie;
        $effective_mode = 'list'
            if $mode eq 'trie' && !$has_octet_trie;
        my $value = $maxbuf{$effective_mode};
        ${^RE_TRIE_MAXBUF} = $value if defined $value;
    }
}

sub latin1 { pack 'C*', @_ }

my $grinning = chr 0x1F600;
my $han      = chr 0x4E2D;
my $country  = chr 0x56FD;

my $numeric_max = 100000;
my @numeric_k = sort { $a <=> $b }
    (10, 20, 40, 80, 160, 320, 640, 1280);
my $numeric_common = $numeric_k[0];
my @numeric_padding = (10, 20, 40, 80);

sub numeric_case {
    my ($max, $count, $common, $repeats, $padding) = @_;

    my @pattern_words = ($max - $count) .. ($max - 1);
    my @target_words = ($max - $common) .. ($max - 1);
    my $pattern = join '|', @pattern_words;
    my $re = qr/(?:$pattern)/;
    # [name, regexp, target words, expected matches, compile divisor,
    #  repeats, padding]
    return ["numeric-$count-pad$padding", $re, \@target_words, $common,
        $count, $repeats, $padding];
}

sub benchmark_case {
    my ($name, $re, $inputs, $expected, $repeats) = @_;
    return [$name, $re, $inputs, $expected, undef, $repeats];
}

my @cases = (
    # Small ASCII alternatives with a four-byte common prefix.
    benchmark_case('ascii-common-prefix', qr/(?:ABCP|ABCG|ABCE|ABCB|ABCA|ABCD)/,
        [qw(ABCD ABCG ABCP XXXX)], 3, 10_000),
    # ASCII alternatives with several shared prefixes and varied lengths.
    benchmark_case('ascii-wide-alphabet', qr/(?:alpha|alpine|altar|algebra|almanac|aloe|alter|altruist)/,
        [qw(alpine altar almanac alter absent)], 4, 10_000),
    # Native, non-UTF-8 Latin-1 byte strings.
    benchmark_case('latin1-native', qr/(?:caf\xE9|na\xEFve|r\xE9sum\xE9|touch\xE9|fa\xE7ade)/,
        [latin1(0x63,0x61,0x66,0xE9), latin1(0x6E,0x61,0xEF,0x76,0x65),
         latin1(0x6E,0x6F,0x70,0x65)], 2, 10_000),
    # UTF-8 alternatives containing two-, three-, and four-byte codepoints.
    benchmark_case('utf8-wide-codepoints', qr/(?:\x{3A9}mega|\x{3BC}icro|\Q$grinning\Eface|\Q$han$country\E|cafe)/,
        ["\x{3A9}mega", "\x{3BC}icro", $grinning . 'face', 'nope'], 3, 10_000),
    # One trie mixing ASCII, Latin-1, and codepoints above Latin-1.
    benchmark_case('mixed-ascii-and-wide', qr/(?:abc|\x{E9}clair|\x{3A9}mega|abacus|\Q$han$country\E)/,
        ['abc', 'abacus', "\x{E9}clair", "\x{3A9}mega", 'none'], 4, 10_000),
    # Unicode case folding, including Greek mu, Kelvin, and sharp-s.
    benchmark_case('unicode-folding', qr/(?:\x{39C}u|\x{3BC}u|\x{212A}elvin|kelvin|Stra\x{DF}e)/i,
        ["\x{3BC}u", "\x{39C}u", 'KELVIN', 'strasse', 'nothing'], 4, 10_000),
    # Latin-1 and Unicode fold equivalents for micro sign and Angstrom.
    benchmark_case('latin1-folding', qr/(?:\x{B5}unit|\x{39C}unit|\x{C5}ngstrom|\x{212B}ngstrom)/i,
        ["\x{B5}unit", "\x{39C}unit", "\x{C5}ngstrom", 'nothing'], 3, 10_000),
    # Many accepting states, shared prefixes, and long continuations.  The
    # common initial 'f' is extracted as a prefix, leaving the overlap-heavy
    # part for the trie.
    benchmark_case('overlap-prefixes', qr/(?:fe|fi|fo|fum|foo|foolish|foolishly|food|foal|foot|footfall|football|fodder)/,
        [qw(fe fi fo fum foo foolish foolishly food foal foot footfall football fodder nope)],
        13, 10_000),
    # The same overlap pattern in the middle of a larger expression.  This
    # uses an ordinary startclass instead of an Aho-Corasick startclass.
    benchmark_case('overlap-middle', qr/[a-d](?:fe|fi|fo|fum|foo|foolish|foolishly|food|foal|foot|footfall|football|fodder)[g-m]/,
        ['afeg', 'afig', 'afog', 'afoog', 'afooz'], 4, 10_000),
    # Several jump continuations share the same trie word.
    benchmark_case('jump-continuations', qr/(?:foo[ab]|foo[bc]|foo[de])/,
        [qw(fooa foob fooc food foof)], 4, 10_000),
    # An accepting state is also the prefix of multiple jump continuations.
    benchmark_case('jump-accepting-prefix', qr/(?:foo|foo[ab]|foo[bc])/,
        [qw(foo fooa foob fooc food fop)], 5, 10_000),
    # Duplicate words and nested shared prefixes should not disturb the
    # acceptance chains or the extracted prefix.
    benchmark_case('duplicate-overlap', qr/(?:foo|foo|foob|fooba|foobar|fool)/,
        [qw(foo foo foob fooba foobar fool fop)], 6, 10_000),
);

my @large_cases = (
    # Numeric suffix alternatives. Every case tests the same target strings;
    # only the number of items in the pattern varies.
    map {
        my $count = $_;
        map {
            numeric_case($numeric_max, $count, $numeric_common, 100, $_)
        } @numeric_padding
    } @numeric_k,
);

sub target_inputs {
    my ($case) = @_;
    if ($case->[0] =~ /^numeric-/) {
        my $padding = $case->[6];
        return map { (' ' x $padding) . $_ . (' ' x $padding) }
            @{$case->[2]};
    }
    return @{$case->[2]};
}

sub filter_cases {
    my ($source) = @_;
    my @selected = @$source;
    if (my $wanted = $ENV{TRIE_BENCH_CASES}) {
        my %wanted = map { $_ => 1 } split /,/, $wanted;
        @selected = grep { $wanted{$_->[0]} } @selected;
    }
    return @selected;
}

sub selected_cases {
    return filter_cases([ @cases, @large_cases ]);
}

sub selected_bench_cases {
    my ($phase) = @_;
    # The large-alternation phase owns its complete K x padding matrix.
    return @large_cases if $phase eq 'large-alternation';
    return filter_cases(\@cases);
}

sub run_tests {
    for my $case (selected_cases()) {
        my ($name, $re, $inputs, $expected) = @$case;
        my @targets = target_inputs($case);
        for my $i (0 .. $#targets) {
            my $want = $i < $expected;
            my $got = $targets[$i] =~ $re;
            main::ok(!!$got == $want, "$name input $i");
        }
    }
}

sub run_case {
    my ($case, $iterations) = @_;
    my ($name, $re, $inputs, $expected) = @$case;
    my $matched = 0;
    for (1 .. $iterations) {
        $matched += ($_ =~ $re) for target_inputs($case);
    }
    die "unexpected match count for $name: $matched\n"
        unless $matched == $iterations * $expected;
}

sub set_mode {
    my ($mode) = @_;
    my %maxbuf = (default => undef, off => -1, list => 0,
        table => 655360, trie => undef);
    die "unknown benchmark mode '$mode'\n" unless exists $maxbuf{$mode};
    my $effective_mode = $mode;
    $effective_mode = 'trie' if $mode eq 'list' && $has_octet_trie;
    $effective_mode = 'list' if $mode eq 'trie' && !$has_octet_trie;
    my $value = $maxbuf{$effective_mode};
    ${^RE_TRIE_MAXBUF} = $value if defined $value;
}

sub effective_mode {
    my ($mode) = @_;
    return 'trie' if $mode eq 'list' && $has_octet_trie;
    return 'list' if $mode eq 'trie' && !$has_octet_trie;
    return $mode;
}

sub display_mode {
    my ($mode) = @_;
    return 'trie' if $has_octet_trie
        && ($mode eq 'trie' || $mode eq 'list');
    return 'list' if $mode eq 'trie' && !$has_octet_trie;
    return $mode;
}

sub iterations_for_case {
    my ($case) = @_;
    my $multiplier = $ENV{TRIE_BENCH_MULTIPLIER} // 1;
    die "TRIE_BENCH_MULTIPLIER must be a positive number\n"
        unless $multiplier =~ /\A(?:\d+(?:\.\d*)?|\.\d+)\z/ && $multiplier > 0;
    return int($case->[5] * $multiplier + 0.5) || 1;
}

sub compile_case {
    my ($case, $serial) = @_;
    my $source = "$case->[1]";
    my $re = eval "qr/(?:$source)(?#trie-bench-$serial)/";
    die "could not compile $case->[0]: $@\n" unless $re;
    return $re;
}

sub run_phase {
    my $phase = $ENV{TRIE_BENCH_PHASE} // 'match';
    my $case_name = $ENV{TRIE_BENCH_CASE}
        // (@ARGV > 1 && $ARGV[0] eq '--phase' ? $ARGV[1] : undef);
    my ($case) = grep { $_->[0] eq $case_name }
        selected_bench_cases($phase);
    die "unknown benchmark case '$case_name'\n" unless $case;
    my $iterations = iterations_for_case($case);
    my $mode = $ENV{TRIE_BENCH_MODE} // ($has_octet_trie ? 'trie' : 'list');
    if ($mode eq 'table' && $has_octet_trie) {
        print "table mode not supported on this Perl; skipping\n";
        return;
    }
    set_mode($mode);

    my $serial = 0;
    if ($phase eq 'compile') {
        compile_case($case, ++$serial); # validate before timing
        my $compile_iterations = $case->[4]
            ? int(($iterations + $case->[4] - 1) / $case->[4]) || 1
            : $iterations;
        for (1 .. $compile_iterations) {
            compile_case($case, ++$serial);
        }
    }
    elsif ($phase eq 'match') {
        my $re = compile_case($case, ++$serial);
        for (1 .. $iterations) {
            my $matched = 0;
            $matched += ($_ =~ $re) for target_inputs($case);
            die "unexpected match count\n"
                unless $matched == $case->[3];
        }
    }
    elsif ($phase eq 'large-alternation') {
        my $re = compile_case($case, ++$serial);
        for (1 .. $iterations) {
            my $matched = 0;
            $matched += ($_ =~ $re) for target_inputs($case);
            die "unexpected match count\n"
                unless $matched == $case->[3];
        }
    }
    else {
        die "unknown benchmark phase '$phase'\n";
    }
}

sub run_profile {
    my ($profile, $case_name, $iterations) = @ARGV[1 .. 3];
    die "usage: $0 --profile compile|match CASE ITERATIONS\n"
        unless defined $profile && defined $case_name && defined $iterations;
    die "unknown profiling phase '$profile'\n"
        unless $profile eq 'compile' || $profile eq 'match';
    die "profiling iteration count must be a positive integer\n"
        unless $iterations =~ /\A[1-9][0-9]*\z/;

    my ($case) = grep { $_->[0] eq $case_name } @cases;
    die "unknown benchmark case '$case_name'\n" unless $case;

    my $mode = $ENV{TRIE_BENCH_MODE} // ($has_octet_trie ? 'trie' : 'list');
    set_mode($mode);

    if ($profile eq 'compile') {
        my $serial = 0;
        # The unique comment prevents the compiler from reusing a previous
        # regexp while retaining the complete qr// compilation path.
        for (1 .. $iterations) {
            compile_case($case, ++$serial);
        }
    }
    else {
        my $re = compile_case($case, 1);
        my @targets = target_inputs($case);
        my $matched = 0;
        for (1 .. $iterations) {
            $matched += ($_ =~ $re) for @targets;
        }
        my $expected = $iterations * $case->[3];
        die "unexpected match count for $case_name: $matched\n"
            unless $matched == $expected;
    }
}

sub find_dumbbench {
    for my $dir (File::Spec->path) {
        my $candidate = File::Spec->catfile($dir, 'dumbbench');
        return $candidate if -x $candidate;
    }
    return;
}

sub run_with_dumbbench {
    my $dumbbench = find_dumbbench();
    unless ($dumbbench) {
        print "dumbbench not found in PATH; skipping trie benchmarks\n",
            "Install it with: cpanm Dumbbench\n";
        return;
    }

    open my $help, '-|', $dumbbench, '--help'
        or do {
            print "dumbbench could not be executed; skipping trie benchmarks\n",
                "Install it with: cpanm Dumbbench\n";
            return;
        };
    local $/;
    my $help_output = <$help> // '';
    close $help;
    if ($help_output !~ /Usage:/) {
        print "dumbbench is not usable; skipping trie benchmarks\n",
            "Install it with: cpanm Dumbbench\n";
        return;
    }

    my $script = abs_path($0);
    my $built  = abs_path('./perl');
    my @requested_modes = $ENV{TRIE_BENCH_MODES}
        ? split /,/, $ENV{TRIE_BENCH_MODES}
        : ($has_octet_trie ? qw(off trie) : qw(off list));
    my @modes;
    my %seen_modes;
    for my $mode (@requested_modes) {
        my $effective = effective_mode($mode);
        push @modes, $effective unless $seen_modes{$effective}++;
    }
    my @phases = $ENV{TRIE_BENCH_PHASES}
        ? split /,/, $ENV{TRIE_BENCH_PHASES}
        : qw(compile match);
    my $multiplier = $ENV{TRIE_BENCH_MULTIPLIER} // 1;
    my $precision = 0.03;
    my $initial = 8;
    my $maxiter = 40;
    my $verbose = 1;
    my %timings;

    for my $mode (@modes) {
        if ($mode eq 'table' && $has_octet_trie) {
            print "table mode not supported on this Perl; skipping\n";
            next;
        }
        set_mode($mode);
        for my $phase (@phases) {
            die "unknown benchmark phase '$phase'\n"
                unless $phase eq 'compile' || $phase eq 'match'
                    || $phase eq 'large-alternation';
            for my $case (selected_bench_cases($phase)) {
                my $child_iterations = iterations_for_case($case);
                my $target_count = scalar @{$case->[2]};
                my $display_mode = display_mode($mode);
                print "=== $display_mode $phase $case->[0] ===\n";
                print "    targets=$target_count child_iterations=$child_iterations",
                    " multiplier=$multiplier",
                    " precision=" . ($precision * 100) . "%",
                    " initial_runs=$initial max_runs=$maxiter",
                    " verbose=$verbose\n";
                local $ENV{TRIE_BENCH_MODE} = $mode;
                local $ENV{TRIE_BENCH_PHASE} = $phase;
                local $ENV{TRIE_BENCH_CASE} = $case->[0];
                my @command = (
                    $dumbbench,
                    '-p', $precision, '-i', $initial, '-m', $maxiter,
                    ('-v') x $verbose, '--float', '--',
                    $built, '-Ilib', $script, '--phase', $phase,
                );
                open my $bench, '-|', @command
                    or die "could not run dumbbench: $!\n";
                my $time;
                while (my $line = <$bench>) {
                    print $line;
                    $time = $1
                        if $line =~ /Rounded run time per iteration \(seconds\):\s+([0-9.]+)/;
                }
                close $bench;
                die "dumbbench failed for $mode $phase $case->[0]\n"
                    if $? != 0;
                die "dumbbench produced no timing for $mode $phase $case->[0]\n"
                    unless defined $time;
                $timings{$phase}{$case->[0]}{$mode} = 0 + $time;
            }
        }
    }

    print "\n=== benchmark summary (seconds per child) ===\n";
    my @display_modes = map { display_mode($_) } @modes;
    my $have_speedup = $seen_modes{off} && $seen_modes{trie};
    printf "%-18s %-20s", 'phase', 'case';
    printf " %12s", $_ for @display_modes;
    printf " %12s", 'trie/off' if $have_speedup;
    print "\n";
    for my $phase (@phases) {
        for my $case (selected_bench_cases($phase)) {
            my $name = $case->[0];
            printf "%-18s %-20s", $phase, $name;
            for my $mode (@modes) {
                my $time = $timings{$phase}{$name}{$mode};
                printf " %12s", defined $time ? sprintf('%.6f', $time) : '-';
            }
            if ($have_speedup) {
                my $off = $timings{$phase}{$name}{off};
                my $trie = $timings{$phase}{$name}{trie};
                my $speedup = defined $off && defined $trie
                    ? sprintf('%.2fx', $off / $trie) : '-';
                printf " %12s", $speedup;
            }
            print "\n";
        }
    }

    print_regression_report(\%timings, \@phases, \@modes);
}

sub load_statistics_regression {
    return 1 if eval { require Statistics::Regression; 1 };

    # The benchmark normally runs under ./perl, while optional analysis
    # modules are installed for the Perl in PATH.  Ask that Perl where its
    # module lives, then add the corresponding library root to this Perl's
    # @INC. Statistics::Regression is pure Perl.
    my $module = qx{perl -MStatistics::Regression -e 'print \$INC{"Statistics/Regression.pm"}' 2>/dev/null};
    chomp $module;
    return 0 unless $module && -f $module;

    my $lib = dirname(dirname($module));
    unshift @INC, $lib unless grep { $_ eq $lib } @INC;
    return eval { require Statistics::Regression; 1 } ? 1 : 0;
}

sub print_regression_report {
    my ($timings, $phases, $modes) = @_;
    return unless grep { $_ eq 'large-alternation' } @$phases;

    unless (load_statistics_regression()) {
        print "\nRegression unavailable; install Statistics::Regression "
            . "for a timing model (for example: cpanm Statistics::Regression)\n";
        return;
    }

    my @cases = selected_bench_cases('large-alternation');
    my %padding = map { $_->[6] => 1 } @cases;
    my @predictors = keys(%padding) > 1
        ? qw(const n_alt n_pad inter)
        : qw(const n_alt);

    print "\n=== timing regression (large-alternation) ===\n";
    print "model: seconds/child = intercept plus coefficients for ",
        join(', ', @predictors[1 .. $#predictors]), "\n";

    for my $mode (@$modes) {
        my $reg = Statistics::Regression->new(
            "trie benchmark $mode", \@predictors
        );
        my $observations = 0;
        for my $case (@cases) {
            my $time = $timings->{'large-alternation'}{$case->[0]}{$mode};
            next unless defined $time;
            my $k = $case->[4];
            my $p = $case->[6];
            my @x = (1, $k);
            push @x, ($p, $k * $p) if @predictors > 2;
            $reg->include($time, \@x);
            ++$observations;
        }
        my $required = scalar @predictors;
        if ($observations <= $required) {
            print "$mode: insufficient observations ($observations; need more than ",
                $required - 1, ")\n";
            next;
        }
        my @theta = $reg->theta();
        my @stderr = $reg->standarderrors();
        my @tstat = map {
            $stderr[$_] && $stderr[$_] != 0
                ? abs($theta[$_] / $stderr[$_]) : 0
        } 0 .. $#theta;
        print "\n--- ", display_mode($mode), " ---\n";
        print "Variables: n_alt = number of alternations, "
            . "n_pad = padding length, inter = (n_alt * n_pad)\n";
        printf "Fitted model: time = %.9g", $theta[0];
        printf " + (%+.9g * n_alt)", $theta[1];
        if (@predictors > 2) {
            printf " + (%+.9g * n_pad)", $theta[2];
            printf " + (%+.9g * (n_alt * n_pad))", $theta[3];
        }
        print "\n";
        $reg->print();

        my $expected = $mode eq 'off' ? 3 : 0;
        my $other_max = 0;
        for my $i (0 .. $#tstat) {
            next if $i == $expected;
            $other_max = $tstat[$i] if $tstat[$i] > $other_max;
        }
        my $dominance = $other_max ? $tstat[$expected] / $other_max : 0;
        my $shape_ok = $other_max == 0 || $dominance >= 5;
        printf "Dominance check: %s (%s t-stat %.2f, next strongest %.2f, "
            . "ratio %.2fx)\n",
            $shape_ok ? 'PASS' : 'WARNING',
            $predictors[$expected], $tstat[$expected], $other_max, $dominance;
    }
}

sub run_benchmark {
    if (@ARGV && $ARGV[0] eq '--with-dumbbench') {
        run_with_dumbbench();
        return;
    }
    if (@ARGV && $ARGV[0] eq '--phase') {
        run_phase();
        return;
    }
    if (@ARGV && $ARGV[0] eq '--profile') {
        run_profile();
        return;
    }
}

if (caller) {
    run_tests();
} else {
    run_benchmark();
}

1;

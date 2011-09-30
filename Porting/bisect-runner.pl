#!/usr/bin/perl -w
use strict;

use Getopt::Long;

my @targets = qw(miniperl lib/Config.pm perl test_prep);

my $target = 'test_prep';
my $j = '9';
my $test_should_pass = 1;
my $clean = 1;
my $one_liner;
my $match;

sub usage {
    die "$0: [--target=...] [-j=4] [--expect-pass=0|1] thing to test";
}

unless(GetOptions('target=s' => \$target,
		  'jobs|j=i' => \$j,
		  'expect-pass=i' => \$test_should_pass,
		  'expect-fail' => sub { $test_should_pass = 0; },
		  'clean!' => \$clean, # mostly for debugging this
		  'one-liner|e=s' => \$one_liner,
                  'match=s' => \$match,
		 )) {
    usage();
}

my $exe = $target eq 'perl' || $target eq 'test_prep' ? 'perl' : 'miniperl';
my $expected = $target eq 'test_prep' ? 'perl' : $target;

unshift @ARGV, "./$exe", '-Ilib', '-e', $one_liner if defined $one_liner;

usage() unless @ARGV || $match;

die "$0: Can't build $target" unless grep {@targets} $target;

$j = "-j$j" if $j =~ /\A\d+\z/;

sub extract_from_file {
    my ($file, $rx, $default) = @_;
    open my $fh, '<', $file or die "Can't open $file: $!";
    while (<$fh>) {
	my @got = $_ =~ $rx;
	return wantarray ? @got : $got[0]
	    if @got;
    }
    return $default if defined $default;
    return;
}

sub clean {
    if ($clean) {
        # Needed, because files that are build products in this checked out
        # version might be in git in the next desired version.
        system 'git clean -dxf';
        # Needed, because at some revisions the build alters checked out files.
        # (eg pod/perlapi.pod). Also undoes any changes to makedepend.SH
        system 'git reset --hard HEAD';
    }
}

sub skip {
    my $reason = shift;
    clean();
    warn "skipping - $reason";
    exit 125;
}

sub report_and_exit {
    my ($ret, $pass, $fail, $desc) = @_;

    clean();

    my $got = ($test_should_pass ? !$ret : $ret) ? 'good' : 'bad';
    if ($ret) {
        print "$got - $fail $desc\n";
    } else {
        print "$got - $pass $desc\n";
    }

    exit($got eq 'bad');
}

# Not going to assume that system perl is yet new enough to have autodie
system 'git clean -dxf' and die;

if ($match) {
    my $matches;
    my $re = qr/$match/;
    foreach my $file (`git ls-files`) {
        chomp $file;
        open my $fh, '<', $file or die "Can't open $file: $!";
        while (<$fh>) {
            if ($_ =~ $re) {
                ++$matches;
                $_ .= "\n" unless /\n\z/;
                print "$file: $_";
            }
        }
        close $fh or die "Can't close $file: $!";
    }
    report_and_exit(!$matches, 'matches for', 'no matches for', $match);
}

skip('no Configure - is this the //depot/perlext/Compiler branch?')
    unless -f 'Configure';

# This changes to PERL_VERSION in 4d8076ea25903dcb in 1999
my $major
    = extract_from_file('patchlevel.h',
			qr/^#define\s+(?:PERL_VERSION|PATCHLEVEL)\s+(\d+)\s/,
			0);

# There was a bug in makedepend.SH which was fixed in version 96a8704c.
# Symptom was './makedepend: 1: Syntax error: Unterminated quoted string'
# Remove this if you're actually bisecting a problem related to makedepend.SH
system 'git show blead:makedepend.SH > makedepend.SH' and die;

my @paths = qw(/usr/local/lib64 /lib64 /usr/lib64);

# if Encode is not needed for the test, you can speed up the bisect by
# excluding it from the runs with -Dnoextensions=Encode
# ccache is an easy win. Remove it if it causes problems.
my @ARGS = ('-des', '-Dusedevel', '-Doptimize=-g', '-Dcc=ccache gcc',
	    '-Dld=gcc', "-Dlibpth=@paths");

# Commit 1cfa4ec74d4933da adds ignore_versioned_solibs to Configure, and sets it
# to true in hints/linux.sh
# On dromedary, from that point on, Configure (by default) fails to find any
# libraries, because it scans /usr/local/lib /lib /usr/lib, which only contain
# versioned libraries. Without -lm, the build fails.
# Telling /usr/local/lib64 /lib64 /usr/lib64 works from that commit onwards,
# until commit faae14e6e968e1c0 adds it to the hints.
# However, prior to 1cfa4ec74d4933da telling Configure the truth doesn't work,
# because it will spot versioned libraries, pass them to the compiler, and then
# bail out pretty early on. Configure won't let us override libswanted, but it
# will let us override the entire libs list.

unless (extract_from_file('Configure', 'ignore_versioned_solibs')) {
    # Before 1cfa4ec74d4933da, so force the libs list.

    my @libs;
    # This is the current libswanted list from Configure, less the libs removed
    # by current hints/linux.sh
    foreach my $lib (qw(sfio socket inet nsl nm ndbm gdbm dbm db malloc dl dld
			ld sun m crypt sec util c cposix posix ucb BSD)) {
	foreach my $dir (@paths) {
	    next unless -f "$dir/lib$lib.so";
	    push @libs, "-l$lib";
	    last;
	}
    }
    push @ARGS, "-Dlibs=@libs";
}

# This seems to be necessary to avoid makedepend becoming confused, and hanging
# on stdin. Seems that the code after make shlist || ...here... is never run.
push @ARGS, q{-Dtrnl='\n'}
    if $major < 4;

# </dev/null because it seems that some earlier versions of Configure can
# call commands in a way that now has them reading from stdin (and hanging)
my $pid = fork;
die "Can't fork: $!" unless defined $pid;
if (!$pid) {
    # Before dfe9444ca7881e71, Configure would refuse to run if stdin was not a
    # tty. With that commit, the tty requirement was dropped for -de and -dE
    open STDIN, '<', '/dev/null' if $major > 4;
    exec './Configure', @ARGS;
    die "Failed to start Configure: $!";
}
waitpid $pid, 0
    or die "wait for Configure, pid $pid failed: $!";

# Skip if something went wrong with Configure
skip('no config.sh') unless -f 'config.sh';

# Correct makefile for newer GNU gcc
# Only really needed if you comment out the use of blead's makedepend.SH
{
    local $^I = "";
    local @ARGV = qw(makefile x2p/makefile);
    while (<>) {
	print unless /<(?:built-in|command|stdin)/;
    }
}

# Parallel build for miniperl is safe
system "make $j miniperl";

if ($target ne 'miniperl') {
    # Nearly all parallel build issues fixed by 5.10.0. Untrustworthy before that.
    $j = '' unless $major > 10;

    if ($target eq 'test_prep') {
        if ($major < 8) {
            # test-prep was added in 5.004_01, 3e3baf6d63945cb6.
            # renamed to test_prep in 2001 in 5fe84fd29acaf55c.
            # earlier than that, just make test. It will be fast enough.
            $target = extract_from_file('Makefile.SH', qr/^(test[-_]prep):/,
                                        'test');
        }
    }

    system "make $j $target";
}

skip("could not build $target")
    if $expected =~ /perl$/ ? !-x $expected : !-r $expected;

# This is what we came here to run:
my $ret = system @ARGV;

report_and_exit($ret, 'zero exit from', 'non-zero exit from', "@ARGV");

# Local variables:
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# ex: set ts=8 sts=4 sw=4 et:

#!/usr/bin/perl -w
use strict;

my $start_time = time;

use Getopt::Long;

sub usage {
    die "$0: [--start revlike] [--end revlike] [--target=...] [-j=4] [--expect-pass=0|1] thing to test";
}

my %options;
unless(GetOptions(\%options,
                  'start=s',
                  'end=s',
                  'target=s',
                  'jobs|j=i',
                  'expect-pass=i',
                  'expect-fail',
                  'one-liner|e=s',
                  'match=s',
                 )) {
    usage();
}

my $start = delete $options{start};
# Currently the earliest version that the runner can build
$start = 'perl-5.004' unless defined $start;
my $end = delete $options{end};
$end = 'blead' unless defined $end;

system "git rev-parse $start >/dev/null" and die;
system "git rev-parse $end >/dev/null" and die;

my $modified = () = `git ls-files --modified --deleted --others`;

die "This checkout is not clean - $modified modified or untracked file(s)"
    if $modified;

system "git bisect reset" and die;

my @ARGS;
foreach (sort keys %options) {
    push @ARGS, defined $options{$_} ? "--$_=$options{$_}" : "--$_";
}
push @ARGS, @ARGV;

my $runner = $0;
$runner =~ s/bisect\.pl/bisect-runner.pl/;

die "Can't find bisect runner $runner" unless -f $runner;

# Sanity check the first and last revisions:
system "git checkout $start" and die;
my $ret = system $^X, $runner, @ARGS;
die "Runner returned $ret, not 0 for start revision" if $ret;

system "git checkout $end" and die;
$ret = system $^X, $runner, @ARGS;
die "Runner returned $ret for end revision" unless $ret;

system "git bisect start" and die;
system "git bisect good $start" and die;
system "git bisect bad $end" and die;

# And now get git bisect to do the hard work:
system 'git', 'bisect', 'run', $^X, $runner, @ARGS and die;

END {
    my $end_time = time;

    printf "That took %d seconds\n", $end_time - $start_time
        if defined $start_time;
}

# Local variables:
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# ex: set ts=8 sts=4 sw=4 et:

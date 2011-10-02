#!/usr/bin/perl -w
use strict;

my $start_time = time;

# The default, auto_abbrev will treat -e as an abbreviation of --end
# Which isn't what we want.
use Getopt::Long qw(:config pass_through no_auto_abbrev);

sub usage {
    die "$0: [--start revlike] [--end revlike] [--target=...] [-j4] [--expect-pass=0|1] thing to test";
}

my ($start, $end);
unless(GetOptions('start=s' => \$start,
                  'end=s' => \$end,
                 )) {
    usage();
}

# We try these in this order for the start revision if none is specified.
my @stable = qw(perl-5.002 perl-5.003 perl-5.004 perl-5.005 perl-5.6.0
                perl-5.8.0 v5.10.0 v5.12.0 v5.14.0);

if ($start) {
    system "git rev-parse $start >/dev/null" and die;
}
$end = 'blead' unless defined $end;
system "git rev-parse $end >/dev/null" and die;

my $modified = () = `git ls-files --modified --deleted --others`;

die "This checkout is not clean - $modified modified or untracked file(s)"
    if $modified;

system "git bisect reset" and die;

my $runner = $0;
$runner =~ s/bisect\.pl/bisect-runner.pl/;

die "Can't find bisect runner $runner" unless -f $runner;

system $^X, $runner, '--check-args', @ARGV and exit 255;

# Sanity check the first and last revisions:
if (defined $start) {
    system "git checkout $start" and die;
    my $ret = system $^X, $runner, @ARGV;
    die "Runner returned $ret, not 0 for start revision" if $ret;
} else {
    # Try to find the earliest version for which the test works
    foreach my $try (@stable) {
        system "git checkout $try" and die;
        my $ret = system $^X, $runner, @ARGV;
        if (!$ret) {
            $start = $try;
            last;
        }
    }
    die "Can't find a suitable start revision to default to. Tried @stable"
        unless defined $start;
}
system "git checkout $end" and die;
my $ret = system $^X, $runner, @ARGV;
die "Runner returned $ret for end revision" unless $ret;

system "git bisect start" and die;
system "git bisect good $start" and die;
system "git bisect bad $end" and die;

# And now get git bisect to do the hard work:
system 'git', 'bisect', 'run', $^X, $runner, @ARGV and die;

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

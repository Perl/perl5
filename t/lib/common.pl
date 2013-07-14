# This code is used by lib/charnames.t, lib/croak.t, lib/feature.t,
# lib/subs.t, lib/strict.t and lib/warnings.t
#
# On input, $::local_tests is the number of tests in the caller; or
# 'no_plan' if unknown, in which case it is the caller's responsibility
# to call cur_test() to find out how many this executed

BEGIN {
    require './test.pl';
}

use Config;
use File::Path;
use File::Spec::Functions qw(catfile curdir rel2abs);

use strict;
use warnings;
my (undef, $file) = caller;
my ($pragma_name) = $file =~ /([A-Za-z_0-9]+)\.t$/
    or die "Can't identify pragama to test from file name '$file'";

$| = 1;

my @w_files;

if (@ARGV) {
    print "ARGV = [@ARGV]\n";
    @w_files = map { "./lib/$pragma_name/$_" } @ARGV;
} else {
    @w_files = sort glob catfile(curdir(), "lib", $pragma_name, "*");
}

my $tests;
my @prgs;
foreach my $file (@w_files) {
    next if $file =~ /(?:~|\.orig|,v)$/;
    next if $file =~ /perlio$/ && !PerlIO::Layer->find('perlio');
    next if -d $file;

    open my $fh, '<', $file or die "Cannot open $file: $!\n" ;
    my $found;
    while (<$fh>) {
        if (/^__END__/) {
            ++$found;
            last;
        }
    }
    # This is an internal error, and should never happen. All bar one of the
    # files had an __END__ marker to signal the end of their preamble, although
    # for some it wasn't technically necessary as they have no tests.
    # It might be possible to process files without an __END__ by seeking back
    # to the start and treating the whole file as tests, but it's simpler and
    # more reliable just to make the rule that all files must have __END__ in.
    # This should never fail - a file without an __END__ should not have been
    # checked in, because the regression tests would not have passed.
    die "Could not find '__END__' in $file"
        unless $found;

    {
        local $/ = undef;
        my @these = split "\n########\n", <$fh>;
        $tests += @these;
        push @prgs, $file, @these;
    }

    close $fh
        or die "Cannot close $file: $!\n";
}

$^X = rel2abs($^X);
@INC = map { rel2abs($_) } @INC;
my $tempdir = tempfile;

mkdir $tempdir, 0700 or die "Can't mkdir '$tempdir': $!";
chdir $tempdir or die die "Can't chdir '$tempdir': $!";
my $cleanup = 1;

END {
    if ($cleanup) {
	chdir '..' or die "Couldn't chdir .. for cleanup: $!";
	rmtree($tempdir);
    }
}

if ($::local_tests && $::local_tests =~ /\D/) {
    # If input is 'no_plan', pass it on unchanged
    plan $::local_tests;
} else {
    plan $tests + ($::local_tests || 0);
}

run_multiple_progs('../..', @prgs);

1;

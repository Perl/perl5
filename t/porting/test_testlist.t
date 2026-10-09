BEGIN {
    chdir '..' if -d '../dist';
    push @INC, "lib";
    require './t/test.pl';
}

use strict;
use warnings;
use feature 'say';
use File::Spec;
use Data::Dumper;$Data::Dumper::Indent=1;

my $thisperl = "$^X -Ilib";

test_via_TEST( qw| op/args.t op/bool.t ../lib/vars.t | );

test_via_harness( qw| op/args.t op/bool.t ../lib/vars.t | );

test_via_runtests( qw| op/args.t op/bool.t ../lib/vars.t | );

my (%th, %tt, %all);
$ENV{PERL_TORTURE_TEST} = 1;
$ENV{PERL_TEST_MEMORY} = 1;
$ENV{PERL_BENCHMARK} = 1;

#   ./perl -lib t/harness -dump_tests
# should be equal to the number of "manifested tests" dumped via
#   ./perl -Ilib t/TEST   -dump_manifested_tests

for my $file (`"$^X" t/TEST -dump_manifested_tests`) {
    chomp $file;
    $all{$file}++;
    $tt{$file}++;
}

for my $file (`"$^X" t/harness -dump_tests`) {
    chomp $file;
    $all{$file}++;
    $th{$file}++;
}

cmp_ok(scalar keys %tt, '==', scalar keys %th,
    "Count of manifested test files found by t/TEST matches count of test files found by t/harness");

my (@missing_from_th, @missing_from_tt);
for my $k (keys %th) {
    unless ($tt{$k}) {
        push @missing_from_tt, $k;
    }
}
is(scalar @missing_from_th, 0,
    "No files found by t/TEST missing from t/harness");

for my $k (keys %tt) {
    unless ($th{$k}) {
        push @missing_from_th, $k;
    }
}
is(scalar @missing_from_tt, 0,
    "No files found by t/harness missing from t/TEST");

done_testing;

##### SUBROUTINES #####

sub test_via_TEST {
    my @these_tests = @_;
    my $test_lookup = get_TEST_reporting_names(@these_tests);

    my @output = `$thisperl t/TEST @these_tests`;
    for my $l (@output) {
        chomp $l;
        next unless $l =~ m{^t/};
        my $root = (split /\s+/, $l)[0];
        ok($test_lookup->{$root}, "$test_lookup->{$root} was tested via t/TEST");
    }
}

sub get_TEST_reporting_names {
    my @these_tests = @_;
    my $test_lookup = {};
    for my $arg (@these_tests) {
        my ($stem) = $arg =~ m{^(.*)\.t$};
        my $startdir = 't';
        my $lookup = File::Spec->catfile($startdir, $stem);
        $test_lookup->{$lookup} = $arg;
    }
    return $test_lookup;
}

sub test_via_harness {
    my @these_tests = @_;
    my $test_lookup = get_harness_reporting_names(@these_tests);

    my @output = `$thisperl t/harness @these_tests`;
    for my $l (@output) {
        chomp $l;
        my $root = (split /\s+/, $l)[0];
        next unless $root =~ m/\.t$/;
        ok($test_lookup->{$root}, "$test_lookup->{$root} was tested via t/harness");
    }
}

sub get_harness_reporting_names {
    my @these_tests = @_;
    my $test_lookup = {};
    for my $arg (@these_tests) {
        $test_lookup->{$arg} = $arg;
    }
    return $test_lookup;
}

sub test_via_runtests {
    my @these_tests = @_;
    my $test_lookup = get_TEST_reporting_names(@these_tests);

    ok(-f './runtests', "runtests is found in top level directory");
    ok(-e './runtests', "runtests is executable");
    my $TEST_FILES = join ' ' => @these_tests;
    my @output = `TEST_FILES="$TEST_FILES" ./runtests choose`;
    for my $l (@output) {
        chomp $l;
        next unless $l =~ m{^t/};
        my $root = (split /\s+/, $l)[0];
        ok($test_lookup->{$root}, "$test_lookup->{$root} was tested via ./runtests");
    }
}

#################### SUBROUTINES NEEDING WORK ####################

sub get_extensions {
    my %extensions;
    open my $ifh, "<", "config.sh"
        or die "Failed to open 'config.sh': $!";
    while (<$ifh>) {
        if (/^extensions='([^']+)'/) {
            my $list = $1;
            NAME:
            foreach my $name (split /\s+/, $list) {
                $name = "PathTools" if $name eq "Cwd";
                $name = "Scalar/List/Utils" if $name eq "List/Util";
                my $sub_dir = $name;
                $sub_dir =~ s!/!-!g unless $sub_dir =~ /^Encode/;
                foreach my $dir (qw(cpan dist ext)) {
                    if (-e "$dir/$sub_dir") {
                        $extensions{"$dir/$sub_dir"} = $name;
                        next NAME;
                    }
                }
                die "Could not find '$name'\n";
            }
            last;
        }
    }
    close $ifh;
    return \%extensions;
}

sub find_in_manifest_but_missing {
    my $extension = get_extensions();
    my %missing;
    my $is_os2 = $^O eq "os2";
    my $is_win32 = $^O eq "MSWin32";
    open my $ifh, "<", "MANIFEST"
        or die "Failed to open 'MANIFEST' for read: $!";
    while (<$ifh>) {
        chomp;
        my ($file, $descr) = split /\t+/, $_;
        next if $file eq "t/test.pl"
             or $file!~m!(?:\.t|/test\.pl)\z!
             or (!$is_os2 and $file=~m!^(?:t/)?os2/!)
             or (!$is_win32 and $file=~m!^(?:t/)?win32/!);
        if ($file=~m!^(cpan|dist|ext/[^/]+)!) {
            my $path = $1;
            next unless $extension->{$path};
        }
        $missing{$file}++ unless $all{$file};
    }
    close $ifh;
    return \%missing;
}

############### TO BE REWORKED ###############

# Test that t/TEST and t/harness test the same files, and that all the
# test files (.t files) listed in MANIFEST are tested by both.
#
# We enabled the various special tests as this simplifies our MANIFEST
# parsing.  In theory if someone adds a new test directory this should
# tell us if one of the files does not know about it.

#
##use Data::Dumper;
##print STDERR Dumper [ sort keys %tt ]; print "\n";
##print STDERR scalar keys %tt, "\n";
##print STDERR Dumper [ sort keys %th ]; print "\n";
##print STDERR scalar keys %th, "\n";
#
##my (%ttonly, %thonly, %both);
##%ttonly = map { ! $th{$_} } keys %tt;
##for my $k (keys %tt) {
##    $ttonly{$k}++ unless $th{$k};
##}
##print STDERR "TT only: ", scalar keys %ttonly, "\n";
##print STDERR Dumper \%ttonly;
##
##for my $k (keys %th) {
##    $thonly{$k}++ unless $tt{$k};
##}
##print STDERR "TH only: ", scalar keys %thonly, "\n";
##print STDERR Dumper \%thonly;
##
###%both = map { ! $th{$_} and ! $tt{$_} } keys %both;
###print STDERR "BOTH: ", scalar keys %both, "\n";
#
##my $missing = find_in_manifest_but_missing();
##is(0+keys(%$missing), 0, "Nothing in manifest that we wouldn't test")
##    or print STDERR map { "# $_\n" } sort keys %$missing;
#

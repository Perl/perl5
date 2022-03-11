#!./perl -w

# * What does this test? *
#
# This tests the well-formed-ness of the MANIFEST file
# and of the Porting/MANIFEST.dev file, and if git is present
# it will confirm that every file known to git ls-files is
# listed in one of the two MANIFEST files.
#
# * Why do we test this? *
#
# We want to keep the files sorted according to our preferred
# sort order. See t/manifest_lib.pm for details. We also want
# to ensure that the file doesn't have any issues that would
# break any parsers that process it.
#
# * It's broken - how do I fix it? *
#
# If MANIFEST or Porting/MANIFEST.dev are not sorted properly,
# you will get this error output something like this:
#
#      got ''MANIFEST' is NOT sorted properly'
#      # expected /(?^:is sorted properly)/
#
# To correct this, run this:
#
#   make manisort
#
# which will output something like "WARNING: re-sorting MANIFEST" but which
# will also correct the problem. This will sort BOTH files with one simple
# command so it is the preferred option.
#
# Alternatively you can manually run what it does under the hood:
#
#   ./perl -Ilib Porting/manisort -o MANIFEST MANIFEST
#   ./perl -Ilib Porting/manisort -o Porting/MANIFEST.dev Porting/MANIFEST.dev
#
# which will output something like "'MANIFEST' is NOT sorted properly" but
# which will also correct the problem.
#
# For other errors you may need to hand edit the file, for instance if a file
# is listed in both MANIFEST or Porting/MANIFEST.dev then you will need to
# decide which file should keep the listing. The rule of thumb is whether
# the file is used only for development purposes when there is a git repo
# available, in which case it should go in Porting/MANIFEST.dev, or if the
# file is required to build perl, in which case it should go in MANIFEST.
# If the file is missing outright you will need to add the file to one of the
# manifests, etc.
#
# Note the file format for MANIFEST files uses *tabs* as a separator, NOT
# spaces, and mixed tabs and spaces as a separator will trigger a test
# failure. Make sure the separator does not contain spaces. You may add a
# description for each file after the tabs, but it is not required. If you
# omit the description then you should trim trailing spaces from the line.
# The description itself may contain spaces however.
#

use Config;
use ExtUtils::Manifest 'maniskip';
BEGIN {
    if (-f '../TestInit.pm') {
        @INC = '..';
    } elsif (-f './TestInit.pm') {
        @INC = '.';
    }
}

use TestInit qw(T); # T is chdir to the top level
require './t/test.pl';
use strict;

skip_all("Cross-compiling, the entire source might not be available")
    if $Config{usecrosscompile};

plan('no_plan');

# this script should be refactored with Porting/manifest_lib.pm and
# Porting/manicheck

sub read_manifest {
    my ($manifest) = @_;

    open my $m, '<', $manifest or die "Can't open '$manifest': $!";
    my @files_array;
    my %files_hash;

    # Test that MANIFEST uses tabs - not spaces - after the name of the file.
    while (defined(my $input_line = <$m>)) {
        chomp($input_line);
        my $file_and_line = "'$manifest' at line $.";

        my ($file, $sep, $descr) = $input_line =~ m/^(\S+)(\s+)?(\S+.*)?\z/;

        isnt($file, undef, "Line does not start with whitespace in $file_and_line")
            or next;

        ok(-f $file, "File '$file' exists in $file_and_line");

        if (my $prev_line = $files_hash{$file}) {
            fail("File '$file' is not duplicated in $file_and_line # previous at line $prev_line");
        }

        push @files_array, $file unless $files_hash{$file};
        $files_hash{$file} = $.;

        next unless defined $sep;

        $sep =~ s/\t/\\t/g;

        ok($sep !~ /\s/, "Separator is all tabs in $file_and_line")
            or diag("Separator is '$sep'");

        ok(defined($descr), "Line with separator also has description in $file_and_line");

    }
    close $m or die "Failed to close '$manifest': $!";
    return (\@files_array, \%files_hash);
}

my $manifest_file = "MANIFEST";
my $porting_file = "Porting/MANIFEST.dev";
my ($manifest_files, $manifest_hash) = read_manifest("MANIFEST");
my ($porting_files, $porting_hash) = read_manifest("Porting/MANIFEST.dev");

foreach my $file (@$manifest_files) {
    if ($porting_hash->{$file}) {
        fail("File '$file' is not listed in both manifests");
        _diag("# File '$file' is listed in '$manifest_file' at line $manifest_hash->{$file} " .
             "and in '$porting_file' at line $porting_hash->{$file}");
    }
}

# Test that MANIFEST is properly sorted
SKIP: {
    my @files = ($manifest_file, $porting_file);
    skip("Sorting order is different under EBCDIC", 0+@files)
        if $::IS_EBCDIC || $::IS_EBCDIC;
    skip("'Porting/manisort' not found", 0+@files)
        if (! -f 'Porting/manisort');

    for my $file ( @files ) {
        my $result = runperl(
                         'progfile' => 'Porting/manisort',
                         'args'     => [ $file ],
                         'stderr'   => 1,
                         'nolib'    => 1 );
        chomp $result;
        like($result, qr/is sorted properly/,
            "'$file' sorted properly");
    }
}

SKIP: {
    find_git_or_skip(5);
    my $skip = maniskip;
    my %repo_seen; # De-dup ls-files output (can appear more than once)
    my @unlisted;
    foreach my $file (`git ls-files`) {
        chomp($file);
        next if $skip->($file);
        next if !-e($file)
             or $repo_seen{$file}++;
        if (!$porting_hash->{$file} and !$manifest_hash->{$file}) {
            push @unlisted, $file;
        }
    }
    skip("git ls-files didnt work (this shouldn't happen)",5)
        unless keys %repo_seen;

    is("Unlisted: @unlisted", "Unlisted: ",
        "All files are listed in either '$manifest_file' or '$porting_file'");

    foreach my $file (keys %repo_seen) {
        delete $porting_hash->{$file};
        delete $manifest_hash->{$file};
    }
    my @still_in_porting = sort keys %$porting_hash;
    my @still_in_manifest = sort keys %$manifest_hash;

    is("Git does not know file: @still_in_porting",
       "Git does not know file: ",
       "Git knows about all files in '$porting_file'");
    is("Git does not know file: @still_in_manifest",
       "Git does not know file: ",
       "Git knows about all files in '$manifest_file'");
    is(0+keys(%repo_seen),@$manifest_files+@$porting_files,
       "git ls-files has the same count of files as our manifests");

    delete $repo_seen{$_} for @$manifest_files, @$porting_files;
    my @still_in_repo_seen = sort keys %repo_seen;
    is("Not listed in either manifest: @still_in_repo_seen",
       "Not listed in either manifest: ",
       "All files from git ls-files are in one of our manifests");
}

# EOF

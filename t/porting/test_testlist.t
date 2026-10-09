BEGIN {
    chdir '..' if -d '../dist';
    push @INC, "lib";
    require './t/test.pl';
}

use strict;
use warnings;

# Test that t/TEST and t/harness test the same files, and that all the
# test files (.t files) listed in MANIFEST are tested by both.
#
# We enabled the various special tests as this simplifies our MANIFEST
# parsing.  In theory if someone adds a new test directory this should
# tell us if one of the files does not know about it.

#plan tests => 3;
#plan skip_all => "pending revision of t/harness";

my (%th, %tt, %all);
$ENV{PERL_TORTURE_TEST} = 1;
$ENV{PERL_TEST_MEMORY} = 1;
$ENV{PERL_BENCHMARK} = 1;

#   ./perl -lib t/harness -dump_tests
# should be equal to the number of "manifested tests" dumped via
#   ./perl -Ilib t/TEST   -dump_manifested_tests

#for my $file (`"$^X" t/TEST -dump_manifested_tests`) {
#    chomp $file;
#    $all{$file}++;
#    delete $th{$file} or $tt{$file}++;
#}
#
#for my $file (`"$^X" t/harness -dump_tests`) {
#    chomp $file;
#    $all{$file}++;
#    $th{$file}++;
#}
#
#is(0+keys(%th), 0, "t/harness will not test anything that t/TEST does not")
#    or print STDERR map { "# t/harness: $_\n" } sort keys %th;
#is(0+keys(%tt), 0, "t/TEST will not test anything that t/harness does not")
#    or print STDERR map { "# t/TEST: $_\n" } sort keys %tt;

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


#use Data::Dumper;
#print STDERR Dumper [ sort keys %tt ]; print "\n";
#print STDERR scalar keys %tt, "\n";
#print STDERR Dumper [ sort keys %th ]; print "\n";
#print STDERR scalar keys %th, "\n";

#my (%ttonly, %thonly, %both);
#%ttonly = map { ! $th{$_} } keys %tt;
#for my $k (keys %tt) {
#    $ttonly{$k}++ unless $th{$k};
#}
#print STDERR "TT only: ", scalar keys %ttonly, "\n";
#print STDERR Dumper \%ttonly;
#
#for my $k (keys %th) {
#    $thonly{$k}++ unless $tt{$k};
#}
#print STDERR "TH only: ", scalar keys %thonly, "\n";
#print STDERR Dumper \%thonly;
#
##%both = map { ! $th{$_} and ! $tt{$_} } keys %both;
##print STDERR "BOTH: ", scalar keys %both, "\n";

#my $missing = find_in_manifest_but_missing();
#is(0+keys(%$missing), 0, "Nothing in manifest that we wouldn't test")
#    or print STDERR map { "# $_\n" } sort keys %$missing;

done_testing();

##### SUBROUTINES #####

#sub get_extensions {
#    my %extensions;
#    open my $ifh, "<", "config.sh"
#        or die "Failed to open 'config.sh': $!";
#    while (<$ifh>) {
#        if (/^extensions='([^']+)'/) {
#            my $list = $1;
#            NAME:
#            foreach my $name (split /\s+/, $list) {
#                $name = "PathTools" if $name eq "Cwd";
#                $name = "Scalar/List/Utils" if $name eq "List/Util";
#                my $sub_dir = $name;
#                $sub_dir =~ s!/!-!g unless $sub_dir =~ /^Encode/;
#                foreach my $dir (qw(cpan dist ext)) {
#                    if (-e "$dir/$sub_dir") {
#                        $extensions{"$dir/$sub_dir"} = $name;
#                        next NAME;
#                    }
#                }
#                die "Could not find '$name'\n";
#            }
#            last;
#        }
#    }
#    close $ifh;
#    return \%extensions;
#}
#
#sub find_in_manifest_but_missing {
#    my $extension = get_extensions();
#    my %missing;
#    my $is_os2 = $^O eq "os2";
#    my $is_win32 = $^O eq "MSWin32";
#    open my $ifh, "<", "MANIFEST"
#        or die "Failed to open 'MANIFEST' for read: $!";
#    while (<$ifh>) {
#        chomp;
#        my ($file, $descr) = split /\t+/, $_;
#        next if $file eq "t/test.pl"
#             or $file!~m!(?:\.t|/test\.pl)\z!
#             or (!$is_os2 and $file=~m!^(?:t/)?os2/!)
#             or (!$is_win32 and $file=~m!^(?:t/)?win32/!);
#        if ($file=~m!^(cpan|dist|ext/[^/]+)!) {
#            my $path = $1;
#            next unless $extension->{$path};
#        }
#        $missing{$file}++ unless $all{$file};
#    }
#    close $ifh;
#    return \%missing;
#}


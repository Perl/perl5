#!/usr/bin/perl -w

#
# cmpVERSION - compare the current Perl source tree and a given tag
# for modules that have identical version numbers but different contents.
#
# with -d option, output the diffs too
# with -x option, exclude dual-life modules (after all, there are tools
#                 like core-cpan-diff that can already deal with them)
#                 With this option, one of the directories must be '.'.
#
# Original by slaven@rezic.de, modified by jhi and matt.w.johnson@gmail.com.
#

use strict;

use ExtUtils::MakeMaker;
use File::Compare;
use File::Find;
use File::Spec::Functions qw(rel2abs abs2rel catfile catdir curdir);
use Getopt::Std;

use lib 'Porting';
use Maintainers;

sub usage {
die <<"EOF";
usage: $0 [ -d -x ] source_dir tag_to_compare
EOF
}

my %opts;
getopts('dx', \%opts) or usage;
@ARGV == 2 or usage;

my ($source_dir, $tag_to_compare) = @ARGV[0,1];
die "$0: '$source_dir' does not look like a Perl directory\n"
    unless -f catfile($source_dir, "perl.h") && -d catdir($source_dir, "Porting");
die "$0: '$source_dir' is a Perl directory but does not look like Git working directory\n"
    unless -d catdir($source_dir, ".git");

my $null = $^O eq 'MSWin32' ? 'nul' : '/dev/null';

my $tag_exists = `git --no-pager tag -l $tag_to_compare 2>$null`;
chomp $tag_exists;

die "$0: '$tag_to_compare' is not a known Git tag\n"
    unless $tag_exists eq $tag_to_compare;

my %dual_files;
if ($opts{x}) {
    die "With -x, the directory must be '.'\n"
	unless $source_dir eq '.';
    for my $m (grep $Maintainers::Modules{$_}{CPAN},
				keys %Maintainers::Modules)
    {

	$dual_files{$_} = 1 for Maintainers::get_module_files($m);
    }
}

chdir $source_dir or die "$0: chdir '$source_dir' failed: $!\n";

# Files to skip from the check for one reason or another,
# usually because they pull in their version from some other file.
my %skip;
@skip{
    'lib/Carp/Heavy.pm',
    'lib/Config.pm',		# no version number but contents will vary
    'lib/Exporter/Heavy.pm',
    'win32/FindExt.pm',
} = ();
my $skip_dirs = qr|^t/lib|;

my @all_diffs = `git --no-pager diff --name-only $tag_to_compare`;
chomp @all_diffs;

my @module_diffs = grep {
    my $this_dir;
    $this_dir = $1 if m/^(.*)\//;
    /\.pm$/ &&
    (!defined($this_dir) || ($this_dir !~ $skip_dirs)) &&
    !exists $skip{$_} &&
    !exists $dual_files{$_}
} @all_diffs;

my (@output_files, @output_diffs);

foreach my $pm_file (@module_diffs) {
    (my $xs_file = $pm_file) =~ s/\.pm$/.xs/;
    my $pm_eq = compare_git_file($pm_file, $tag_to_compare);
    next unless defined $pm_eq;
    my $xs_eq = 1;
    if (-e $xs_file) {
        $xs_eq = compare_git_file($xs_file, $tag_to_compare);
        next unless defined $xs_eq;
    }
    next if ($pm_eq && $xs_eq);
    my $pm_version = eval {MM->parse_version($pm_file)};
    my $orig_pm_content = get_file_from_git($pm_file, $tag_to_compare);
    my $orig_pm_version = eval {MM->parse_version(\$orig_pm_content)};
    next if ( ! defined $pm_version || ! defined $orig_pm_version );
    next if ( $pm_version eq 'undef' || $orig_pm_version eq 'undef' ); # sigh
    next if $pm_version ne $orig_pm_version;
    push @output_files, $pm_file;
    push @output_diffs, $pm_file unless $pm_eq;
    push @output_diffs, $xs_file unless $xs_eq;
}

sub compare_git_file {
    my ($file, $tag) = @_;
    open(my $orig_fh, "-|", "git --no-pager show $tag:$file 2>$null");
    return undef if eof($orig_fh);
    my $is_eq = compare($file, $orig_fh) == 0;
    close($orig_fh);
    return $is_eq;
}

sub get_file_from_git {
    my ($file, $tag) = @_;
    local $/ = undef;
    my $file_content = `git --no-pager show $tag:$file 2>$null`;
    return $file_content;
}

for (sort @output_files) {
    print "$_\n";
}

exit unless $opts{d};

for (sort @output_diffs) {
    print "\n";
    system "git --no-pager diff $tag_to_compare '$_'";
}


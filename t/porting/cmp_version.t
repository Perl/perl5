#!./perl -w

#
# Compare the current Perl source tree against the version at the most
# recent tag, for modules that have identical version numbers but
# different contents. Skips cpan/.
#
# Original by slaven@rezic.de, modified by jhi and matt.w.johnson@gmail.com
#
# Adapted from Porting/cmpVERSION.pl by Abigail
#

BEGIN {
    chdir '..' unless -d 't';
    unshift @INC, 'lib', 'Porting';
}

use strict;
use warnings;
use version;
use ExtUtils::MakeMaker;
use File::Compare;
use File::Find;
use File::Spec::Functions qw(rel2abs abs2rel catfile catdir curdir);
use Getopt::Std;
use Maintainers;

if (! -d '.git' ) {
    print "1..0 # SKIP: not being run from a git checkout\n";
    exit 0;
}

#
# Thanks to David Golden for this suggestion.
#
my $tag_to_compare = `git describe --abbrev=0`;
chomp $tag_to_compare;
my $source_dir = '.';

my $null = $^O eq 'MSWin32' ? 'nul' : '/dev/null';

my $tag_exists = `git --no-pager tag -l $tag_to_compare 2>$null`;
chomp $tag_exists;


if ($tag_exists ne $tag_to_compare) {
    print "1..0 # SKIP: '$tag_to_compare' is not a known Git tag\n";
    exit 0;
}


my %dual_files;
for my $m (grep $Maintainers::Modules {$_} {CPAN}, keys %Maintainers::Modules) {
    $dual_files{$_} = 1 for Maintainers::get_module_files ($m);
}


# Files to skip from the check for one reason or another,
# usually because they pull in their version from some other file.
my %skip;
@skip{
    'lib/Carp/Heavy.pm',
    'lib/Config.pm',		# no version number but contents will vary
    'lib/Exporter/Heavy.pm',
    'win32/FindExt.pm',
} = ();

# Files to skip just for particular version(s),
# usually due to some # mix-up

my %skip_versions = (
    # 'some/sample/file.pm' => [ '1.23', '1.24' ],
    'dist/threads/lib/threads.pm' => [ '1.83' ],
);

my $skip_dirs = qr{^(?:t/lib|cpan)};

my @all_diffs = `git --no-pager diff --name-only $tag_to_compare`;
chomp @all_diffs;

my @tmp_diffs = grep {
    my $this_dir;
    $this_dir = $1 if m/^(.*)\//;
    /\.pm$/ &&
    (!defined($this_dir) || ($this_dir !~ $skip_dirs)) &&
    !exists $skip{$_};
} @all_diffs;
my   @module_diffs =  grep {!exists $dual_files {$_}} @tmp_diffs;
push @module_diffs => grep { exists $dual_files {$_}} @tmp_diffs;

unless (@module_diffs) {
    print "1..1\n";
    print "ok 1 - No difference found\n";
    exit;
}

my (@output_files, @output_diffs);

printf "1..%d\n" => scalar @module_diffs;

my $count = 0;
my @diff;
foreach my $pm_file (@module_diffs) {
    @diff = ();
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
    next if exists $skip_versions{$pm_file}
	 and grep $pm_version eq $_, @{$skip_versions{$pm_file}};
    push @diff => $pm_file unless $pm_eq;
    push @diff => $xs_file unless $xs_eq;
}
continue {
    if (@diff) {
        foreach my $diff (@diff) {
            print "# $_" for `git --no-pager diff $tag_to_compare '$diff'`;
        }
        printf "not ok %d - %s\n" => ++ $count, $pm_file;
    }
    else {
        printf "ok %d - %s\n" => ++ $count, $pm_file;
    }
}

exit;

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

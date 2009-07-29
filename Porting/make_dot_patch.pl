#!/usr/bin/perl
use strict;
use warnings;

# This is a quickie script which I wrote to generate the .patch file for
# an arbitrary commit. It takes on sha1 as an argument, or saving that
# uses the sha1 associated to HEAD.
# It tries to find which of our primary branches the sha1 can be found on,
# and then prints to standard out something similar to what our rsync feed
# would produce for that situation. The main difference being, in that case
# we KNOW what branch we are on, and in this one we dont, and in that case
# the $tstamp field holds the time the snapshot was generated (so that multiple
# fetches will always have an increasing tstamp field), however in this case
# we use the commit date of the sha1.
#
# This is more or less intended to be used as a utility to generated .patch
# files for other processes, like gitweb and snapshots.
#
# The script assumes it is being run from a git WD.
#
# Yves

use POSIX qw(strftime);
sub isotime { strftime "%Y-%m-%d.%H:%M:%S",gmtime(shift||time) }

my $target= shift || 'HEAD';
chomp(my ($git_dir, $is_bare, $sha1)=`git rev-parse --git-dir --is-bare-repository $target`);
die "Not in a git repository!" if !$git_dir;
$is_bare= "" if $is_bare and $is_bare eq 'false';
my @branches=(
          'blead',
          'maint-5.10',
          'maint-5.8',
          'maint-5.8-dor',
          'maint-5.6',
          'maint-5.005',
          'maint-5.004',
);
my $reftype= $is_bare ? "heads" : "remotes/origin";
my $branch;
foreach my $name (@branches) {
    my $cmd= "git name-rev --name-only --refs=refs/$reftype/$name $sha1";
    chomp($branch= `$cmd`);
    last if $branch ne 'undefined';
}
$branch ||= "error";
$branch =~ s!^\Q$reftype\E/!!;
$branch =~ s![~^].*\z!!;
my $tstamp= isotime(`git log -1 --pretty="format:%ct" $sha1`);
chomp(my $describe= `git describe`);
print join(" ", $branch, $tstamp, $sha1, $describe) . "\n";


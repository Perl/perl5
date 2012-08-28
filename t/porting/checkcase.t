#!/usr/bin/perl
# Finds the files that have the same name, case insensitively in the build tree

BEGIN {
    @INC = '..' if -f '../TestInit.pm';
}
use TestInit qw(T); # T is chdir to the top level

use warnings;
use strict;
use File::Find;

my %files;
my $test_count = 0;

find({no_chdir => 1, wanted => sub {
	   my $name = $File::Find::name;
	   # Assumes that the path separator is exactly one character.
	   $name =~ s/^\..//;

	   # Special exemption for Makefile, makefile
	   return if $name =~ m!\A(?:x2p/)?[Mm]akefile\z!;

	   if ($name eq '.git') {
	       # Don't scan the .git directory, as its contents are outside
	       # our control. In particular, as fetch doesn't default to
	       # --prune, # someone pushing a branch upstream with a name
	       # which case-conflicts with a previously deleted branch will
	       # cause action-at-a-distance failures, because locally
	       # .git/logs/refs/remotes will contain both.
	       ++$File::Find::prune;
	       return;
	   }

	   push @{$files{lc $name}}, $name;
	 }}, '.');

foreach (sort values %files) {
    if (@$_ > 1) {
		print "not ok ".++$test_count. " - ". join(", ", @$_), "\n";
		print STDERR "# $_\n" foreach @$_;
    } else {
		print "ok ".++$test_count. " - ". join(", ", @$_), "\n";
	}
}

print "1..".$test_count."\n";

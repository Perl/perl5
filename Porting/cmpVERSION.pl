#!/usr/bin/perl -w

#
# cmpVERSION - compare two Perl source trees for modules
# that have identical version numbers but different contents.
#
# Original by slaven@rezic.de, modified by jhi.
#

use strict;

use ExtUtils::MakeMaker;
use File::Compare;
use File::Find;
use File::Spec::Functions qw(rel2abs abs2rel catfile catdir curdir);

for (@ARGV[0, 1]) {
    die "$0: '$_' does not look like Perl directory\n"
	unless -f catfile($_, "perl.h") && -d catdir($_, "Porting");
}

my $dir2 = rel2abs($ARGV[1]);
chdir $ARGV[0] or die "$0: chdir '$ARGV[0]' failed: $!\n";

my @wanted;
find(
     sub { /\.pm$/ &&
	       do { my $file2 =
			catfile(catdir($dir2, $File::Find::dir), $_);
		    return if compare($_, $file2) == 0;
		    my $version1 = eval {MM->parse_version($_)};
		    my $version2 = eval {MM->parse_version($file2)};
		    push @wanted, $File::Find::name
			if $version1 eq $version2
		} }, curdir);
print map { $_, "\n" } sort @wanted;



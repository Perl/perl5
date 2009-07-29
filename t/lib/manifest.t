#!./perl -w

# Test the well-formed-ness of the MANIFEST file.

BEGIN {
    chdir 't';
    @INC = '../lib';
}

use strict;
use File::Spec;
require './test.pl';

plan('no_plan');

my $manifest = File::Spec->catfile(File::Spec->updir(), 'MANIFEST');

open my $m, '<', $manifest or die "Can't open '$manifest': $!";

my $last_seen = '';
my $sorted = 1;

# Test that MANIFEST uses tabs - not spaces - after the name of the file.
while (<$m>) {
    chomp;

    my ($file, $separator) = /^(\S+)(\s*)/;
    isnt($file, undef, "Line $. doesn't start with a blank") or next;

    # Manifest order is "dictionary order, lowercase" for ASCII:
    my $normalised = $_;
    $normalised =~ tr/A-Z/a-z/;
    $normalised =~ s/[^a-z0-9\s]//g;

    if ($normalised le $last_seen) {
	fail("Sort order broken by $file");
	undef $sorted;
    }
    $last_seen = $normalised;

    if (!$separator) {
	# Ignore lines without whitespace (i.e., filename only)
    } elsif ($separator !~ tr/\t//c) {
	# It's all tabs
	next;
    } elsif ($separator !~ tr/ //c) {
	# It's all spaces
	fail("Spaces in entry for $file");
    } elsif ($separator =~ tr/\t//) {
	fail("Mixed tabs and spaces in entry for $file");
    } else {
	fail("Odd whitespace in entry for $file");
    }
}

close $m or die $!;

ok($sorted, 'MANIFEST properly sorted');

# EOF

#!./perl -w

# Test the well formed-ness of the MANIFEST file.
# For now, just test that it uses tabs not spaces after the name of the file.

BEGIN {
    chdir 't';
    @INC = '../lib';
}

use strict;
use File::Spec;
require './test.pl';

my $failed = 0;

plan('no_plan');

my $manifest = File::Spec->catfile(File::Spec->updir(), 'MANIFEST');

open my $m, '<', $manifest or die "Can't open '$manifest': $!";

while (<$m>) {
    chomp;
    next unless /\s/;
    my ($file, $separator) = /^(\S+)(\s+)/;
    isnt($file, undef, "Line $. doesn't start with a blank") or next;
    if ($separator !~ tr/\t//c) {
	# It's all tabs
	next;
    } elsif ($separator !~ tr/ //c) {
	# It's all spaces
	fail("Spaces in entry for $file");
	next;
    } elsif ($separator =~ tr/\t//) {
	fail("Mixed tabs and spaces in entry for $file");
    } else {
	fail("Odd whitespace in entry for $file");
    }
}

close $m or die $!;

is($failed, 0, 'All lines are good');

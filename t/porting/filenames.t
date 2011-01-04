#!./perl -w

=head1 filenames.t

Test the well-formed-ness of filenames names in the MANIFEST file. Current
tests being done:

=over 4

=item * no more than 39 characters before the dot, and 39 after

=item * no filenames starting with -

=item * don't use any of these names (regardless of case) before the dot: CON,
PRN, AUX, NUL, COM1, COM2, COM3, COM4, COM5, COM6, COM7, COM8, COM9, LPT1,
LPT2, LPT3, LPT4, LPT5, LPT6, LPT7, LPT8, and LPT9

=item * no spaces, ( or & in filenames

=back

=cut

BEGIN {
    chdir 't';
    @INC = '../lib';
}

use strict;
use File::Spec;
use File::Basename;
require './test.pl';

plan('no_plan');

my $manifest = File::Spec->catfile(File::Spec->updir(), 'MANIFEST');

open my $m, '<', $manifest or die "Can't open '$manifest': $!";
my @files;
while (<$m>) {
    chomp;
    my($path) = split /\t+/;

    validate_file_name($path);
}
close $m or die $!;

sub validate_file_name {
    my $path = shift;
    my $filename = basename $path;

    note("testing $path");

    my @path_components = split('/',$path);
    pop @path_components; # throw away the filename
    for my $component (@path_components) {
        unlike($component, qr/\..*?\./,
	      "no directory components containing more than one '.'")
	    or return;

        cmp_ok(length $component, '<=', 32,
	       "no directory with a name over 32 characters (VOS requirement)")
	    or return;
    }


    unlike($filename, qr/^\-/, "filename does not start with -");

    my($before, $after) = split /\./, $filename;
    cmp_ok(length $before, '<=', 39,
	   "filename has 39 or fewer characters before the dot");
    if ($after) {
	cmp_ok(length $after, '<=', 39,
	       "filename has 39 or fewer characters after the dot");
    }

    unlike($filename, qr/^(?:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])\./i,
	   "filename has a reserved name");

    unlike($filename, qr/\s|\(|\&/, "filename has a reserved character");
}

# EOF

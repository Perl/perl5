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
use File::Basename;
require './test.pl';
require '../Porting/Manifest.pm';

my @files = Porting::Manifest::get_porting_files();

plan(scalar @files);

PATHNAME: for my $pathname (@files) {
    my @path_components = split('/',$pathname);
    my $filename = pop @path_components;
    for my $component (@path_components) {
        next if $component eq ".github";
        if ($component =~ /\./) {
            fail("$pathname has directory components containing '.'");
            next PATHNAME;
        }
        if (length $component > 32) {
            fail("$pathname has a name over 32 characters (VOS requirement)");
            next PATHNAME;
        }
    }


    if ($filename =~ /^\-/) {
        fail("$pathname starts with -");
            next PATHNAME;
    }

    my($before, $after) = split /\./, $filename;
    if (length $before > 39) {
        fail("$pathname has more than 39 characters before the dot");
    } elsif ($after && length $after > 39) {
        fail("$pathname has more than 39 characters after the dot");
    } elsif ($filename =~ /^(?:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])\./i) {
        fail("$pathname has a reserved name");
    } elsif ($filename =~ /\s|\(|\&/) {
        fail("$pathname has a reserved character");
    } else {
        pass("$pathname ok");
    }
}

# EOF

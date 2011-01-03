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

my @dont = qw/CON PRN AUX NUL COM1 COM2 COM3 COM4 COM5 COM6 COM7 COM8 COM9 LPT1 LPT2 LPT3 LPT4 LPT5 LPT6 LPT7 LPT8 LPT9/;
my @more_dont = ('\s','\(','\&');

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


    my @path_components = split('/',$path);
    pop @path_components; # throw away the filename
    for my $component (@path_components) {
        if ($component =~ /\..*?\./) {
            fail("$path has a directory component containing more than one '.'");
            return;
        }

        if (length($component) > 32) {
            fail("$path has a directory with a name over 32 characters. This fails on VOS");
        }
    }


    if ($filename =~ m/^\-/) {
        fail("starts with -: $path");
        return;
    }

    my($before, $after) = split /\./, $filename;
    if (length $before > 39) {
        fail("more than 39 characters before the dot: $path");
        return;
    }
    if ($after and (length $after > 39)) {
        fail("more than 39 characters after the dot: $path");
        return;
    }

    foreach (@dont) {
        if ($filename =~ m/^$_\./i) {
            fail("found $_ before the dot: $path");
            return;
        }
    }

    foreach (@more_dont) {
        if ($filename =~ m/$_/) {
            fail("found $_: $path");
            return;
        }
    }

    ok($filename, $path);
}

# EOF

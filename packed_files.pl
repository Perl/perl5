#!perl
use strict;
use Getopt::Std;

my $opts = {};
getopts('uch', $opts );

die usage() if $opts->{'h'} or ( not $opts->{'u'} and not $opts->{'c'} );

my $Pack = 'pack.pl';
die "Could not find $Pack" unless -e $Pack;

open my $fh, "MANIFEST" or die "Could not open MANIFEST";

while( my $line = <$fh> ) {
    chomp $line;
    my ($file) = split /\s+/, $line;

    next unless $file =~ /\.packed/;

    my $out = $file;
    $out =~ s/\.packed//;

    ### unpack
    if( $opts->{'u'} ) {

        my $cmd =  "$^X -Ilib $Pack -u -v $file $out";
        system( $cmd ) and die "Could not unpack $file: $?";

    ### clean up
    } else {

        ### file exists?
        unless( -e $out ) {
            print "File $file was not unpacked into $out. Can not remove.\n";

        ### remove it
        } else {
            print "Removing $out\n";
            1 while unlink $out;
        }
    }
}

sub usage {
    return qq[
Usage: $^X $0 -u | -c | -h

    Unpack or clean up .packed files from the source tree.
    This program is just a wrapper around $Pack.

Options:
    -u  Unpack all files in this source tree
    -c  Clean up all unpacked files from this source tree
    -h  Display this help text

];
}

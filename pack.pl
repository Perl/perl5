#!perl
use strict;
use Getopt::Std;

my $opts = {};
getopts('ushvD', $opts );

die usage() if $opts->{h};

my $file    = shift or die "Need file\n". usage();
my $outfile = shift || '';
my $mode    = (stat($file))[2] & 07777;

open my $fh, $file or die "Could not open input file $file: $!";
my $str = do { local $/; <$fh> };

### unpack?
my $outstr;
if( $opts->{u} ) {
    if( !$outfile ) {
        $outfile = $file;
        $outfile =~ s/\.packed$//;
    }

    $outstr  = unpack 'u', $str;

} else {
    $outfile ||= $file . '.packed';

    $outstr = pack 'u', $str;
}

### output the file
if( $opts->{'s'} ) {
    print STDOUT $outstr;
} else {
    print "Writing $file into $outfile\n" if $opts->{'v'};
    open my $outfh, ">$outfile"
        or die "Could not open $outfile for writing: $!";
    print $outfh $outstr;
    close $outfh;

    chmod $mode, $outfile;
}

### delete source file?
if( $opts->{'D'} and $file ne $outfile ) {
    1 while unlink $file;
}

sub usage {
    return qq[
Usage: $0 [-v] [-s] [-D] SOURCE [OUTPUT_FILE]
       $0 [-v] [-s] [-D] -u SOURCE [OUTPUT_FILE]
       $0 -h

    uuencodes a file, either to a target file or STDOUT.
    If no output file is provided, it outputs to SOURCE.packed

Options:
    -v  Run verbosely
    -s  Output to STDOUT rather than OUTPUT_FILE
    -h  Display this help message
    -u  Unpack rather than pack
    -D  Delete source file after encoding/decoding

]
}

#!perl -w
use strict;

use vars qw($trysource $tryout $sentinel);
$trysource = "try.c";
$tryout = "try.i";

my $macro = shift;
die "$0 macro [headers]" unless defined $macro;

$sentinel = "$macro expands to";

foreach($trysource, $tryout) {
    die "You already have a $_" if -e $_;
}

if (!@ARGV) {
    open my $fh, '<', 'MANIFEST' or die "Can't open MANIFEST: $!";
    while (<$fh>) {
	push @ARGV, $1 if m!^([^/]+\.h)\t!;
    }
}

my $args = '';

while (<>) {
    next unless /^#\s*define\s+$macro/;
    my ($def_args) = /^#\s*define\s+$macro\(([^)]*)\)/;
    if (defined $def_args) {
	my @args = split ',', $def_args;
	my $argname = "A0";
	$args = '(' . join (', ', map {$argname++} 1..@args) . ')';
    }
    last;
}

open my $out, '>', $trysource or die "Can't open $trysource: $!";

print $out <<"EOF";
#include "EXTERN.h"
#include "perl.h"
#line 3 "$sentinel"
$macro$args
EOF

close $out or die "Can't close $trysource: $!";

system "make $tryout" and die;

open my $fh, '<', $tryout or die "Can't open $tryout: $!";

while (<$fh>) {
    print if /$sentinel/o .. 1;
}

foreach($trysource, $tryout) {
    die "Can't unlink $_" unless unlink $_;
}

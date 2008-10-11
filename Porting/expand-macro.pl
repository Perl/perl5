#!perl -w
use strict;

use Getopt::Std;

use vars qw($trysource $tryout $sentinel);
$trysource = "try.c";
$tryout = "try.i";

getopts('fF:ekvI:', \my %opt) or usage();

sub usage {
    die<<EO_HELP;
@_;
usage: $0 [options] <macro-name> [headers]
options:
    -f		use 'indent' to format output
    -F	<tool>	use <tool> to format output  (instead of -f)
    -e		erase try.[ic] instead of failing when theyre present (errdetect)
    -k		keep them after generating (for handy inspection)
    -v		verbose
    -I <indent-opts>	passed into indent
EO_HELP
}

my $macro = shift;
usage "missing <macro-name>" unless defined $macro;

$sentinel = "$macro expands to";

usage "-f and -F <tool> are exclusive\n" if $opt{f} and $opt{F};

foreach($trysource, $tryout) {
    unlink $_ if $opt{e};
    die "You already have a $_" if -e $_;
}

if (!@ARGV) {
    open my $fh, '<', 'MANIFEST' or die "Can't open MANIFEST: $!";
    while (<$fh>) {
	push @ARGV, $1 if m!^([^/]+\.h)\t!;
    }
}

my $args = '';

my $header;
while (<>) {
    next unless /^#\s*define\s+$macro\b/;
    my ($def_args) = /^#\s*define\s+$macro\(([^)]*)\)/;
    if (defined $def_args) {
	my @args = split ',', $def_args;
	print "# macro: $macro args: @args in $_\n" if $opt{v};
	my $argname = "A0";
	$args = '(' . join (', ', map {$argname++} 1..@args) . ')';
    }
    $header = $ARGV;
    last;
}
die "$macro not found\n" unless defined $header;

open my $out, '>', $trysource or die "Can't open $trysource: $!";

print $out <<"EOF";
#include "EXTERN.h"
#include "perl.h"
#include "$header"
#line 4 "$sentinel"
$macro$args
EOF

close $out or die "Can't close $trysource: $!";

print "doing: make $tryout\n" if $opt{v};
system "make $tryout" and die;

# if user wants 'indent' formatting ..
my $out_fh;

if ($opt{f} || $opt{F}) {
    # a: indent is a well behaved filter when given 0 arguments, reading from
    #    stdin and writing to stdout
    # b: all our braces should be balanced, indented back to column 0, in the
    #    headers, hence everything before our #line directive can be ignored
    #
    # We can take advantage of this to reduce the work to indent.

    my $indent_command = $opt{f} ? 'indent' : $opt{F};

    if (defined $opt{I}) {
	$indent_command .= " $opt{I}";
    }
    open $out_fh, '|-', $indent_command or die $?;
} else {
    $out_fh = \*STDOUT;
}

open my $fh, '<', $tryout or die "Can't open $tryout: $!";

while (<$fh>) {
    print $out_fh $_ if /$sentinel/o .. 1;
}

unless ($opt{k}) {
    foreach($trysource, $tryout) {
	die "Can't unlink $_" unless unlink $_;
    }
}

#!./perl -- -*- mode: cperl; cperl-indent-level: 4 -*-

BEGIN {
    if ($^O eq 'VMS') {
	print "1..0 # skip on VMS\n";
	exit 0;
    }
    chdir 't' if -d 't';
    @INC = '../lib';
    $ENV{PERL5LIB} = '../lib';    # so children will see it too
}

use strict;

$|=1;
undef $/;
my @prgs = split "########\n", <DATA>;
close DATA;
print "1..", scalar @prgs, "\n";
require "dumpvar.pl";

our $tmpfile = "perl5db0";
1 while -f ++$tmpfile;
END { if ($tmpfile) { 1 while unlink $tmpfile; } }

my $i = 0;
$ENV{PERLDB_OPTS} = "TTY=0";
my($ornament1,$ornament2);
for (@prgs){
    my($prog,$expected) = split(/\nEXPECT\n?/, $_);
    open my $select, "| $^X -de0 2> $tmpfile" or die $!;
    print $select $prog;
    close $select;
    my $got = do { open my($fh), $tmpfile or die; local $/; <$fh>; };
    $got =~ s/^\s*Loading.*\nEditor.*\n\nEnter.*\n\nmain::\(-e:1\):\s0\n//;
    unless (defined $ornament1) {
        ($ornament1,$ornament2) = $got =~
            /(.*?)0\s+'reserved example for calibrating the ornaments'\n(.*)/
    }
    $got =~ s/^\Q$ornament1\E//;
    $got =~ s/\Q$ornament2\E\z//;
    my $not = "";
    my $why = "";
    if ($got !~ /$expected/) {
        $not = "not ";
        $got = dumpvar::unctrl($got);
        $why = " # prog[$prog]got[$got]expected[$expected]";
    }
    print $not, "ok ", ++$i, $why, "\n";
}

__END__
x "reserved example for calibrating the ornaments"
EXPECT
0  'reserved example for calibrating the ornaments'
########
x "foo"
EXPECT
0  'foo'
########
x 1..3
EXPECT
0  1
1  2
2  3
########
x +{1..4}
EXPECT
0\s+HASH\(0x[\da-f]+\)
\s+1 => 2
\s+3 => 4
########

#!./perl -- -*- mode: cperl; cperl-indent-level: 4 -*-

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    unless (find PerlIO::Layer 'perlio') { # PerlIO::scalar
	print "1..0 # Skip: not perlio\n";
	exit 0;
    }
}

use strict;

$|=1;
undef $/;
my @prgs = split "########\n", <DATA>;
close DATA;
print "1..", scalar @prgs, "\n";
require "dumpvar.pl";

my $i = 0;
for (@prgs){
    my($prog,$expected) = split(/\nEXPECT\n?/, $_);
    open my $select, ">", \my $got or die;
    select $select;
    eval $prog;
    my $not = "";
    my $why = "";
    if ($@) {
        $not = "not ";
        $why = " # prog[$prog]\$\@[$@]";
    } elsif ($got ne $expected) {
        $not = "not ";
        $why = " # prog[$prog]got[$got]expected[$expected]";
    }
    close $select;
    select STDOUT;
    print $not, "ok ", ++$i, $why, "\n";
}

__END__
"";
EXPECT
########
dumpValue(1);
EXPECT
1
########
dumpValue("1\n2\n3");
EXPECT
'1
2
3'
########
dumpValue([1..3],1);
EXPECT
0  1
1  2
2  3
########
dumpValue({1..4},1);
EXPECT
1 => 2
3 => 4
########

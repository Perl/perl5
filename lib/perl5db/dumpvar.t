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

my @prgs;
{
    local $/;
    @prgs = split "########\n", <DATA>;
    close DATA;
}

use Test::More;

plan tests => scalar @prgs;

require "dumpvar.pl";

for (@prgs) {
    my($prog, $expected) = split(/\nEXPECT\n?/, $_);
    open my $select, ">", \my $got or die;
    select $select;
    eval $prog;
    my $ERR = $@;
    close $select;
    select STDOUT;
    if ($ERR) {
        ok(0, "$prog - $ERR");
    } else {
        is($got, $expected, $prog);
    }
}

__END__
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

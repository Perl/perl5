#!./perl -- -*- mode: cperl; cperl-indent-level: 4 -*-

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    $ENV{PERL5LIB} = '../lib';    # so children will see it too
    if ($^O eq 'VMS') {
	print "1..0 # skip on $^O, no piped open\n";
	exit 0;
    }
}

use strict;

$| = 1;

my @prgs;

{
    local $/;
    @prgs = split "########\n", <DATA>;
    close DATA;
}

use Test::More;

plan tests => scalar @prgs;

require "dumpvar.pl";

use File::Temp qw/tempfile/;

our ($tmpfh, $tmpfile) = tempfile();

$ENV{PERLDB_OPTS} = "TTY=0";
my($ornament1,$ornament2);
for (@prgs){
    my($prog, $expected) = split(/\nEXPECT\n?/, $_);
    open my $select, "| $^X -de0 2> $tmpfile" or die $!;
    print $select $prog;
    close $select;
    my $got = do { open my($fh), $tmpfile or die; local $/; <$fh>; };
    $got =~ s/^\s*Loading.*\nEditor.*\n\nEnter.*\n\nmain::\(-e:1\):\s0\n//;
    unless (defined $ornament1) {
        ($ornament1, $ornament2) = $got =~
            /(.*?)0\s+'reserved example for calibrating the ornaments'\n(.*)/
    }
    $got =~ s/^\Q$ornament1\E//;
    $got =~ s/\Q$ornament2\E\z//;
    like($got, qr:$expected:i, $prog);
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
x "\x{100}"
EXPECT
0  '\\x\{0100\}'
########
x *a
EXPECT
0  \*main::a
########
x 1..3
EXPECT
0  1
1  2
2  3
########
x +{1..4}
EXPECT
0\s+HASH\(0x[0-9a-f]+\)
\s+1 => 2
\s+3 => 4
########

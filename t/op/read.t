#!./perl

# $RCSfile: read.t,v $$Revision: 4.1 $$Date: 92/08/07 18:28:17 $

BEGIN {
    chdir 't';
    @INC = '../lib';
    require './test.pl';
}
use strict;

plan tests => 4;

open(FOO,'op/read.t') || open(FOO,'t/op/read.t') || open(FOO,':op:read.t') || die "Can't open op.read";
seek(FOO,4,0) or die "Seek failed: $!";
my $buf;
my $got = read(FOO,$buf,4);

is ($got, 4);
is ($buf, "perl");

seek (FOO,0,2) || seek(FOO,20000,0);
$got = read(FOO,$buf,4);

is ($got, 0);
is ($buf, "");

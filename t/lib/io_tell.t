#!./perl

# $RCSfile: tell.t,v $$Revision: 1.1 $$Date: 1996/05/01 10:52:47 $

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib' if -d '../lib';
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bIO\b/ && !($^O eq 'VMS')) {
	print "1..0\n";
	exit 0;
    }
}

print "1..13\n";

use IO::File;

$tst = IO::File->new("TEST","r") || die("Can't open TEST");

if ($tst->eof) { print "not ok 1\n"; } else { print "ok 1\n"; }

$firstline = <$tst>;
$secondpos = tell;

$x = 0;
while (<$tst>) {
    if (eof) {$x++;}
}
if ($x == 1) { print "ok 2\n"; } else { print "not ok 2\n"; }

$lastpos = tell;

unless (eof) { print "not ok 3\n"; } else { print "ok 3\n"; }

if ($tst->seek(0,0)) { print "ok 4\n"; } else { print "not ok 4\n"; }

if (eof) { print "not ok 5\n"; } else { print "ok 5\n"; }

if ($firstline eq <$tst>) { print "ok 6\n"; } else { print "not ok 6\n"; }

if ($secondpos == tell) { print "ok 7\n"; } else { print "not ok 7\n"; }

if ($tst->seek(0,1)) { print "ok 8\n"; } else { print "not ok 8\n"; }

if ($tst->eof) { print "not ok 9\n"; } else { print "ok 9\n"; }

if ($secondpos == tell) { print "ok 10\n"; } else { print "not ok 10\n"; }

if ($tst->seek(0,2)) { print "ok 11\n"; } else { print "not ok 11\n"; }

if ($lastpos == $tst->tell) { print "ok 12\n"; } else { print "not ok 12\n"; }

unless (eof) { print "not ok 13\n"; } else { print "ok 13\n"; }

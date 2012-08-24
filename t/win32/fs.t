#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require "./test.pl";
    eval 'use Errno';
    die $@ if $@ and !is_miniperl();
}

use Config;

plan tests => 4;

my $tmpfile1 = tempfile();
my $tmpfile2 = tempfile();

SKIP: {
    # RT #112272
    -e $tmpfile1 || -e $tmpfile2
        and skip("somehow, the files exist", 4);
    ok(!link($tmpfile1, $tmpfile2),
       "Cannot link to unknown file");
    is(0+$!, &Errno::ENOENT, "check errno is ENOENT");
    open my $fh, ">", $tmpfile1
	or skip("Cannot create test link src", 2);
    close $fh;
    open my $fh, ">", $tmpfile2
	or skip("Cannot create test link target", 2);
    close $fh;
    ok(!link($tmpfile1, $tmpfile2),
       "Cannot link to existing file");
    is(0+$!, &Errno::EEXIST, "check for EEXIST");
}

END {
    unlink($tmpfile1, $tmpfile2);
}

#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bFileHandle\b/ && $^O ne 'VMS') {
	print "1..0\n";
	exit 0;
    }
}

use FileHandle;
use strict subs;

$mystdout = new_from_fd FileHandle 1,"w";
$| = 1;
autoflush $mystdout;
print "1..4\n";

print $mystdout "ok ",fileno($mystdout),"\n";

$fh = new FileHandle "TEST", O_RDONLY and print "ok 2\n";
$buffer = <$fh>;
print $buffer eq "#!./perl\n" ? "ok 3\n" : "not ok 3\n";

ungetc $fh 65;
CORE::read($fh, $buf,1);
print $buf eq 'A' ? "ok 4\n" : "not ok 4\n";

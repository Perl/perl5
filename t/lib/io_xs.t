#!./perl

BEGIN {
    unless(grep /blib/, @INC) {
	chdir 't' if -d 't';
	@INC = '../lib' if -d '../lib';
    }
}

use Config;

BEGIN {
    if(-d "lib" && -f "TEST") {
        if ($Config{'extensions'} !~ /\bIO\b/ && $^O ne 'VMS') {
	    print "1..0\n";
	    exit 0;
        }
    }
}

use IO::File;
use IO::Seekable;

print "1..2\n";
use IO::File;
$x = new_tmpfile IO::File or print "not ";
print "ok 1\n";
print $x "ok 2\n";
$x->seek(0,SEEK_SET);
print <$x>;

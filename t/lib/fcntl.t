#!./perl

# A modest test: exercises only O_WRONLY, O_CREAT, and O_RDONLY.
# Have to be modest to be portable: could possibly extend testing
# also to O_RDWR and O_APPEND, but dunno about the portability of,
# say, O_TRUNC and O_EXCL, not to mention O_NONBLOCK.

use Fcntl;

print "1..6\n";

print "ok 1\n";

if (sysopen(my $wo, "fcntl$$", O_WRONLY|O_CREAT)) {
    print "ok 2\n";
    if (syswrite($wo, "foo") == 3) {
	print "ok 3\n";
	close($wo);
	if (sysopen(my $ro, "fcntl$$", O_RDONLY)) {
	    print "ok 4\n";
	    if (sysread($ro, my $read, 3)) {
		print "ok 5\n";
		if ($read eq "foo") {
		    print "ok 6\n";
		} else {
		    print "not ok 6 # content '$read' not ok\n";
		}
	    } else {
		print "not ok 5 # sysread failed: $!\n";
	    }
	} else {
	    print "not ok 4 # sysopen O_RDONLY failed: $!\n";
	}
	close($ro);
    } else {
	print "not ok 3 # syswrite failed: $!\n";
    }
    close($wo);
} else {
    print "not ok 2 # sysopen O_WRONLY failed: $!\n";
}

END {
    1 while unlink "fcntl$$";
}


BEGIN {
	eval { pack "q", 0 };
	if ($@) {
		print "1..0\n# no 64-bit types\n";
		exit(0);
	}
}

# First try to figure out whether we have sparse files.

if ($^O eq 'win32' || $^O eq 'vms') {
    print "1..0\n# no sparse files\n";
    exit(0);
}

open(BIG, ">big");
close(BIG);

my @s;

@s = stat("big");

unless (@s == 13 && defined $s[11] && defined $s[12]) {
    print "1..0\n# no sparse files\n";
    exit(0);
}

# By now we better be sure that we do have sparse files:
# if we are not, the following will hog 5 gigabytes of disk.  Ooops.

print "1..8\n";

open(BIG, ">big");
binmode BIG;
seek(BIG, 5_000_000_000, 0);
print BIG "big";
close BIG;

@s = stat("big");

print "not " unless $s[7] == 5_000_000_003;
print "ok 1\n";

print "not " unless -s "big" == 5_000_000_003;
print "ok 2\n";

open(BIG, "big");
binmode BIG;

seek(BIG, 4_500_000_000, 0);

print "not " unless tell(BIG) == 4_500_000_000;
print "ok 3\n";

seek(BIG, 1, 1);

print "not " unless tell(BIG) == 4_500_000_001;
print "ok 4\n";

seek(BIG, -1, 1);

print "not " unless tell(BIG) == 4_500_000_000;
print "ok 5\n";

seek(BIG, -3, 2);

print "not " unless tell(BIG) == 5_000_000_000;
print "ok 6\n";

my $big;

print "not " unless read(BIG, $big, 3) == 3;
print "ok 7\n";

print "not " unless $big eq "big";
print "ok 8\n";

close(BIG);

# Testing sysseek() and other sys*() io would be nice but for
# the tests to be be portable they require the SEEK_* constants.

unlink "big";


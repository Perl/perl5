# NOTE: this file tests how large files (>2GB) work with raw system IO.
# open(), tell(), seek(), print(), read() are tested in t/op/lfs.t.
# If you modify/add tests here, remember to update also t/op/lfs.t.

BEGIN {
	eval { my $q = pack "q", 0 };
	if ($@) {
		print "1..0\n# no 64-bit types\n";
		bye();
	}
	chdir 't' if -d 't';
	unshift @INC, '../lib';
	require Fcntl; import Fcntl;
}

sub bye {
    close(BIG);
    unlink "big";
    exit(0);
}

# First try to figure out whether we have sparse files.

if ($^O eq 'win32' || $^O eq 'vms') {
    print "1..0\n# no sparse files\n";
    bye();
}

# We'll start off by creating a one megabyte file which has
# only three "true" bytes.

sysopen(BIG, "big", O_WRONLY|O_CREAT|O_TRUNC) or
	do { warn "sysopen failed: $!\n"; bye };
sysseek(BIG, 1_000_000, SEEK_SET);
syswrite(BIG, "big");
close(BIG);

my @s;

@s = stat("big");

print "# @s\n";

unless (@s == 13 &&
	$s[7] == 1_000_003 &&
	defined $s[11] &&
	defined $s[12] &&
       $s[11] * $s[12] < 1000_003) {
    print "1..0\n# no sparse files?\n";
    bye();
}

# By now we better be sure that we do have sparse files:
# if we are not, the following will hog 5 gigabytes of disk.  Ooops.

print "1..8\n";

sysopen(BIG, "big", O_WRONLY|O_CREAT|O_TRUNC) or
	do { warn "sysopen failed: $!\n"; bye };
sysseek(BIG, 5_000_000_000, SEEK_SET);
syswrite(BIG, "big");
close BIG;

@s = stat("big");

print "# @s\n";

print "not " unless $s[7] == 5_000_000_003;
print "ok 1\n";

print "not " unless -s "big" == 5_000_000_003;
print "ok 2\n";

sysopen(BIG, "big", O_RDONLY) or do { warn "sysopen failed: $!\n"; bye };

sysseek(BIG, 4_500_000_000, SEEK_SET);

print "not " unless sysseek(BIG, 0, SEEK_CUR) == 4_500_000_000;
print "ok 3\n";

sysseek(BIG, 1, SEEK_CUR);

print "not " unless sysseek(BIG, 0, SEEK_CUR) == 4_500_000_001;
print "ok 4\n";

sysseek(BIG, -1, SEEK_CUR);

print "not " unless sysseek(BIG, 0, SEEK_CUR) == 4_500_000_000;
print "ok 5\n";

sysseek(BIG, -3, SEEK_END);

print "not " unless sysseek(BIG, 0, SEEK_CUR) == 5_000_000_000;
print "ok 6\n";

my $big;

print "not " unless sysread(BIG, $big, 3) == 3;
print "ok 7\n";

print "not " unless $big eq "big";
print "ok 8\n";

bye();

# eof

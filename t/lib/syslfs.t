# NOTE: this file tests how large files (>2GB) work with raw system IO.
# open(), tell(), seek(), print(), read() are tested in t/op/lfs.t.
# If you modify/add tests here, remember to update also t/op/lfs.t.

BEGIN {
	# Don't bother if there are no quads.
	eval { my $q = pack "q", 0 };
	if ($@) {
		print "1..0\n# no 64-bit types\n";
		exit(0);
	}
	chdir 't' if -d 't';
	unshift @INC, '../lib';
	require Config; import Config;
	# Don't bother if there are no quad offsets.
	if ($Config{lseeksize} < 8) {
		print "1..0\n# no 64-bit file offsets\n";
		exit(0);
	}
	require Fcntl; import Fcntl;
}

sub bye {
    close(BIG);
    unlink "big";
    exit(0);
}

sub explain {
    print <<EOM;
#
# If the lfs (large file support: large meaning larger than two gigabytes)
# tests are skipped or fail, it may mean either that your process is not
# allowed to write large files or that the file system you are running
# the tests on doesn't support large files, or both.  You may also need
# to reconfigure your kernel. (This is all very system-dependent.)
#
# Perl may still be able to support large files, once you have
# such a process and such a (file) system.
#
EOM
}

# Known have-nots.
if ($^O eq 'win32' || $^O eq 'vms') {
    print "1..0\n# no sparse files\n";
    bye();
}

# Then try to deduce whether we have sparse files.

# We'll start off by creating a one megabyte file which has
# only three "true" bytes.  If we have sparseness, we should
# consume less blocks than one megabyte (assuming nobody has
# one megabyte blocks...)

sysopen(BIG, "big", O_WRONLY|O_CREAT|O_TRUNC) or
	do { warn "sysopen failed: $!\n"; bye };
sysseek(BIG, 1_000_000, SEEK_SET);
syswrite(BIG, "big");
close(BIG);

my @s;

@s = stat("big");

print "# @s\n";

my $BLOCKSIZE = 512; # is this really correct everywhere?

unless (@s == 13 &&
	$s[7] == 1_000_003 &&
	defined $s[12] &&
	$BLOCKSIZE * $s[12] < 1_000_003) {
    print "1..0\n# no sparse files?\n";
    bye();
}

# By now we better be sure that we do have sparse files:
# if we are not, the following will hog 5 gigabytes of disk.  Ooops.

sysopen(BIG, "big", O_WRONLY|O_CREAT|O_TRUNC) or
	do { warn "sysopen failed: $!\n"; bye };
sysseek(BIG, 5_000_000_000, SEEK_SET);
# The syswrite will fail if there are are filesize limitations (process or fs).
unless(syswrite(BIG, "big") == 3) {
    $ENV{LC_ALL} = "C";
    if ($! =~/File too large/) {
	print "1..0\n# writing past 2GB failed\n";
	explain();
	bye();
    }
}
close BIG;

@s = stat("big");

print "# @s\n";

sub fail () {
    print "not ";
    $fail++;
}

print "1..8\n";

my $fail = 0;

fail unless $s[7] == 5_000_000_003;	# exercizes pp_stat
print "ok 1\n";

fail unless -s "big" == 5_000_000_003;	# exercizes pp_ftsize
print "ok 2\n";

sysopen(BIG, "big", O_RDONLY) or do { warn "sysopen failed: $!\n"; bye };

sysseek(BIG, 4_500_000_000, SEEK_SET);

fail unless sysseek(BIG, 0, SEEK_CUR) == 4_500_000_000;
print "ok 3\n";

sysseek(BIG, 1, SEEK_CUR);

fail unless sysseek(BIG, 0, SEEK_CUR) == 4_500_000_001;
print "ok 4\n";

sysseek(BIG, -1, SEEK_CUR);

fail unless sysseek(BIG, 0, SEEK_CUR) == 4_500_000_000;
print "ok 5\n";

sysseek(BIG, -3, SEEK_END);

fail unless sysseek(BIG, 0, SEEK_CUR) == 5_000_000_000;
print "ok 6\n";

my $big;

fail unless sysread(BIG, $big, 3) == 3;
print "ok 7\n";

fail unless $big eq "big";
print "ok 8\n";

explain if $fail;

bye();

# eof

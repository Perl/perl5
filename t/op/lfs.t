# NOTE: this file tests how large files (>2GB) work with perlio (stdio/sfio).
# sysopen(), sysseek(), syswrite(), sysread() are tested in t/lib/syslfs.t.
# If you modify/add tests here, remember to update also t/lib/syslfs.t.

BEGIN {
	# Don't bother if there are no quads.
	eval { my $q = pack "q", 0 };
	if ($@) {
		print "1..0\n# no 64-bit types\n";
		bye();
	}
	chdir 't' if -d 't';
	unshift @INC, '../lib';
}

sub bye {
    close(BIG);
    unlink "big";
    exit(0);
}

# Known have-nots.
if ($^O eq 'win32' || $^O eq 'vms') {
    print "1..0\n# no sparse files\n";
    bye();
}

# Then try to deduce whether we have sparse files.

my ($SEEK_SET, $SEEK_CUR, $SEEK_END) = (0, 1, 2);

# We'll start off by creating a one megabyte file which has
# only three "true" bytes.  If we have sparseness, we should
# consume less blocks than one megabyte (assuming nobody has
# one megabyte blocks...)

open(BIG, ">big") or do { warn "open failed: $!\n"; bye };
binmode BIG;
seek(BIG, 1_000_000, $SEEK_SET);
print BIG "big";
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

my $fail = 0;

open(BIG, ">big") or do { warn "open failed: $!\n"; bye };
binmode BIG;
seek(BIG, 5_000_000_000, $SEEK_SET);
print BIG "big";
close BIG;

@s = stat("big");

print "# @s\n";

sub fail () {
    print " not ";
    $fail++;
}

fail unless $s[7] == 5_000_000_003;
print "ok 1\n";

fail unless -s "big" == 5_000_000_003;
print "ok 2\n";

open(BIG, "big") or do { warn "open failed: $!\n"; bye };
binmode BIG;

seek(BIG, 4_500_000_000, $SEEK_SET);

fail unless tell(BIG) == 4_500_000_000;
print "ok 3\n";

seek(BIG, 1, $SEEK_CUR);

fail unless tell(BIG) == 4_500_000_001;
print "ok 4\n";

seek(BIG, -1, $SEEK_CUR);

fail unless tell(BIG) == 4_500_000_000;
print "ok 5\n";

seek(BIG, -3, $SEEK_END);

fail unless tell(BIG) == 5_000_000_000;
print "ok 6\n";

my $big;

fail unless read(BIG, $big, 3) == 3;
print "ok 7\n";

fail unless $big eq "big";
print "ok 8\n";

bye();

if ($fail) {
    print STDERR <<EOM;
#
# If the lfs (large file support) tests fail, it means that
# the *file system* you are running the tests on doesn't support
# large files (files larger than two gigabytes).  Perl may still
# be able to support such files, once you have such a file system.
#
EOM
}

# eof

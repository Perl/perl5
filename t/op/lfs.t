BEGIN {
	eval { pack "q", 0 };
	if ($@) {
		print "1..0\n# no 64-bit types\n";
		bitedust();
	}
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

my $SEEK_SET;
my $SEEK_CUR;
my $SEEK_END;

# We probe for the constants 'manually' because
# we do not want to be dependent on any extensions.

sub seek_it {
    my ($set, $cur, $end) = @_; 

    my $test = 0;

    open(BIG, ">big") || do { warn "open failed: $!\n"; bye };
    binmode BIG;
    seek(BIG, 49, $set);
    print BIG "X";
    close(BIG);
    open(BIG, "big")  || do { warn "open failed: $!\n"; bye };
    seek(BIG, 50, $set);
    if (tell(BIG) == 50) {
	seek(BIG, -10, $cur);
	if (tell(BIG) == 40) {
	    seek(BIG, -20, $end);
	    if (tell(BIG) == 30) {
		$test = 1;
	    }
	}
    }
    close(BIG);

    return $test;
}

if (seek_it(0, 1, 2)) {
    ($SEEK_SET, $SEEK_CUR, $SEEK_END) = (0, 1, 2);
} elsif (seek_it(1, 2, 3)) {
    ($SEEK_SET, $SEEK_CUR, $SEEK_END) = (1, 2, 3);
} else {
    print "1..0\n# no way to seek\n";
    bye;
}

print "# SEEK_SET = $SEEK_SET, SEEK_CUR = $SEEK_CUR, SEEK_END = $SEEK_END\n";

open(BIG, ">big") || do { warn "open failed: $!\n"; bye };
binmode BIG;
seek(BIG, 100_000, $SEEK_SET);
print BIG "big";
close(BIG);

my @s;

@s = stat("big");

unless (@s == 13 &&
	$s[7] == 100_003 &&
	defined $s[11] &&
	defined $s[12] &&
       $s[11] * $s[12] < 100_003) {
    print "1..0\n# no sparse files\n";
    bye();
}

# By now we better be sure that we do have sparse files:
# if we are not, the following will hog 5 gigabytes of disk.  Ooops.

print "1..8\n";

open(BIG, ">big") || do { warn "open failed: $!\n"; bye };
binmode BIG;
seek(BIG, 5_000_000_000, $SEEK_SET);
print BIG "big";
close BIG;

@s = stat("big");

print "not " unless $s[7] == 5_000_000_003;
print "ok 1\n";

print "not " unless -s "big" == 5_000_000_003;
print "ok 2\n";

open(BIG, "big") || do { warn "open failed: $!\n"; bye };
binmode BIG;

seek(BIG, 4_500_000_000, $SEEK_SET);

print "not " unless tell(BIG) == 4_500_000_000;
print "ok 3\n";

seek(BIG, 1, $SEEK_CUR);

print "not " unless tell(BIG) == 4_500_000_001;
print "ok 4\n";

seek(BIG, -1, $SEEK_CUR);

print "not " unless tell(BIG) == 4_500_000_000;
print "ok 5\n";

seek(BIG, -3, $SEEK_END);

print "not " unless tell(BIG) == 5_000_000_000;
print "ok 6\n";

my $big;

print "not " unless read(BIG, $big, 3) == 3;
print "ok 7\n";

print "not " unless $big eq "big";
print "ok 8\n";

bye();

# eof



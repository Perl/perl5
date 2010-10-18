#!./perl -w

use Test::More;

use File::Temp;
use File::Spec;

use Fcntl qw(:mode);

my $tmpfile = File::Temp->new;
my @tests = (
	     ['REG', 'tmpfile', (stat "$tmpfile")[2]],
	     ['DIR', 'dir', (stat '.')[2]]
	    );

$devnull = File::Spec->devnull();
if (-c $devnull) {
    push @tests, ['CHR', $devnull, (stat $devnull)[2]];
}

plan(tests => 9 * @tests);
foreach (@tests) {
    my ($type, $name, $mode) = @$_;

    if ($type eq 'REG') {
	ok( S_ISREG($mode), " S_ISREG $name");
    } else {
	ok(!S_ISREG($mode), "!S_ISREG $name");
    }

    if ($type eq 'DIR') {
	ok( S_ISDIR($mode), " S_ISDIR $name");
    } else {
	ok(!S_ISDIR($mode), "!S_ISDIR $name");
    }

 SKIP: {
	skip 'No S_IFCHR', 1 unless defined eval {S_IFCHR};
	if ($type eq 'CHR') {
	    ok( S_ISCHR($mode), " S_ISCHR $name");
	} else {
	    ok(!S_ISCHR($mode), "!S_ISCHR $name");
	}
    }

 SKIP: {
	skip 'No S_IFLNK', 1 unless defined eval {S_IFLNK};
	ok(!S_ISLNK($mode), "!S_ISLNK $name");
    }
 SKIP: {
	skip 'No S_IFSOCK', 1 unless defined eval {S_IFSOCK};
	ok(!S_ISSOCK($mode), "!S_ISSOCK $name");
    }
 SKIP: {
	skip 'No S_IFBLK', 1 unless defined eval {S_IFBLK};
	ok(!S_ISBLK($mode), "!S_ISBLK $name");
    }
 SKIP: {
	skip 'No S_IFFIFO', 1 unless defined eval {S_IFFIFO};
	ok(!S_ISFIFO($mode), "!S_ISFIFO $name");
    }
 SKIP: {
	skip 'No S_IFWHT', 1 unless defined eval {S_IFWHT};
	ok(!S_ISWHT($mode), "!S_ISWHT $name");
    }
 SKIP: {
	skip 'No S_ENFMT', 1 unless defined eval {S_ENFMT};
	ok(!S_ISENFMT($mode), "!S_ISENFMT $name");
    }
}
	

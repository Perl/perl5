use HTTP::Date;

require Time::Local if $^O eq "MacOS";
my $offset = ($^O eq "MacOS") ? Time::Local::timegm(0,0,0,1,0,70) : 0;

print "1..58\n";

$no = 1;
$| = 1;
sub ok {
   print "not " if $_[0];
   print "ok $no\n";
   $no++;
}

# test str2time for supported dates.  Test cases with 2 digit year
# will probably break in year 2044.
my(@tests) =
(
 'Thu Feb  3 00:00:00 GMT 1994',        # ctime format
 'Thu Feb  3 00:00:00 1994',            # same as ctime, except no TZ

 'Thu, 03 Feb 1994 00:00:00 GMT',       # proposed new HTTP format
 'Thursday, 03-Feb-94 00:00:00 GMT',    # old rfc850 HTTP format
 'Thursday, 03-Feb-1994 00:00:00 GMT',  # broken rfc850 HTTP format

 '03/Feb/1994:00:00:00 0000',   # common logfile format
 '03/Feb/1994:01:00:00 +0100',  # common logfile format
 '02/Feb/1994:23:00:00 -0100',  # common logfile format

 '03 Feb 1994 00:00:00 GMT',    # HTTP format (no weekday)
 '03-Feb-94 00:00:00 GMT',      # old rfc850 (no weekday)
 '03-Feb-1994 00:00:00 GMT',    # broken rfc850 (no weekday)
 '03-Feb-1994 00:00 GMT',       # broken rfc850 (no weekday, no seconds)
 '03-Feb-1994 00:00',           # VMS dir listing format

 '03-Feb-94',    # old rfc850 HTTP format    (no weekday, no time)
 '03-Feb-1994',  # broken rfc850 HTTP format (no weekday, no time)
 '03 Feb 1994',  # proposed new HTTP format  (no weekday, no time)
 '03/Feb/1994',  # common logfile format     (no time, no offset)

 #'Feb  3 00:00',     # Unix 'ls -l' format (can't really test it here)
 'Feb  3 1994',       # Unix 'ls -l' format

 "02-03-94  12:00AM", # Windows 'dir' format

 # ISO 8601 formats
 '1994-02-03 00:00:00 +0000',
 '1994-02-03',
 '19940203',
 '1994-02-03T00:00:00+0000',
 '1994-02-02T23:00:00-0100',
 '1994-02-02T23:00:00-01:00',
 '1994-02-03T00:00:00 Z',
 '19940203T000000Z',
 '199402030000',

 # A few tests with extra space at various places
 '  03/Feb/1994      ',
 '  03   Feb   1994  0:00  ',
);

my $time = (760233600 + $offset);  # assume broken POSIX counting of seconds
for (@tests) {
    my $t;
    if (/GMT/i) {
	$t = str2time($_);
    } else {
	$t = str2time($_, "GMT");
    }
    my $t2 = str2time(lc($_), "GMT");
    my $t3 = str2time(uc($_), "GMT");

    $t = "UNDEF" unless defined $t;
    print "'$_'  =>  $t\n";
    print $@ if $@;
    print "not " if $t eq 'UNDEF' || $t  != $time
	                          || $t2 != $time
	                          || $t3 != $time;
    ok;
}

# test time2str
die "time2str failed"
    unless time2str($time) eq 'Thu, 03 Feb 1994 00:00:00 GMT';

# test the 'ls -l' format with missing year$
# round to nearest minute 3 days ago.
$time = int((time - 3 * 24*60*60) /60)*60;
($min, $hr, $mday, $mon) = (localtime $time)[1,2,3,4];
$mon = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon];
$str = sprintf("$mon %02d %02d:%02d", $mday, $hr, $min);
$t = str2time($str);
$t = "UNDEF" unless defined $t;
print "'$str'  =>  $t ($time)\n";
print "not " if $t != $time;
ok;

# try some garbage.
for (undef, '', 'Garbage',
     'Mandag 16. September 1996',
#     'Thu Feb  3 00:00:00 CET 1994',
#     'Thu, 03 Feb 1994 00:00:00 CET',
#     'Wednesday, 31-Dec-69 23:59:59 GMT',

     '1980-00-01',
     '1980-13-01',
     '1980-01-00',
     '1980-01-32',
     '1980-01-01 25:00:00',
     '1980-01-01 00:61:00',
     '1980-01-01 00:00:61',
    )
{
    my $bad = 0;
    eval {
	if (defined str2time $_) {
	    print "str2time($_) is not undefined\n";
	    $bad++;
	}
    };
    print defined($_) ? "'$_'\n" : "undef\n";
    print $@ if $@;
    print "not " if $bad;
    ok;
}

print "Testing AM/PM gruff...\n";

# Test the str2iso routines
use HTTP::Date qw(time2iso time2isoz);

print "Testing time2iso functions\n";

$t = time2iso(str2time("11-12-96  0:00AM"));print "$t\n";
ok($t ne "1996-11-12 00:00:00");

$t = time2iso(str2time("11-12-96 12:00AM"));print "$t\n";
ok($t ne "1996-11-12 00:00:00");

$t = time2iso(str2time("11-12-96  0:00PM"));print "$t\n";
ok($t ne "1996-11-12 12:00:00");

$t = time2iso(str2time("11-12-96 12:00PM"));print "$t\n";
ok($t ne "1996-11-12 12:00:00");


$t = time2iso(str2time("11-12-96  1:05AM"));print "$t\n";
ok($t ne "1996-11-12 01:05:00");

$t = time2iso(str2time("11-12-96 12:05AM"));print "$t\n";
ok($t ne "1996-11-12 00:05:00");

$t = time2iso(str2time("11-12-96  1:05PM"));print "$t\n";
ok($t ne "1996-11-12 13:05:00");

$t = time2iso(str2time("11-12-96 12:05PM"));print "$t\n";
ok($t ne "1996-11-12 12:05:00");

$t = str2time("2000-01-01 00:00:01.234");
print "FRAC $t = ", time2iso($t), "\n";
ok(abs(($t - int($t)) - 0.234) > 0.000001);

$a = time2iso;
$b = time2iso(500000);
print "LOCAL $a  $b\n";
$az = time2isoz;
$bz = time2isoz(500000);
print "GMT   $az $bz\n";

for ($a,  $b)  { ok if /^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d$/;  }
for ($az, $bz) { ok if /^\d{4}-\d\d-\d\d \d\d:\d\d:\d\dZ$/; }

# Test the parse_date interface
use HTTP::Date qw(parse_date);

@d = parse_date("Jan 1 2001");

print "not " if defined(pop(@d)) ||
                "@d" ne "2001 1 1 0 0 0";
ok;

# This test will break around year 2070
print "not " unless parse_date("03-Feb-20") eq "2020-02-03 00:00:00";
ok;

# This test will break around year 2048
print "not " unless parse_date("03-Feb-98") eq "1998-02-03 00:00:00";
ok;

print "HTTP::Date $HTTP::Date::VERSION\n";

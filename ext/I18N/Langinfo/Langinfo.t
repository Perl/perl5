#!./perl

BEGIN {
    chdir 't' if -d 't';
    require Config; import Config;
    if ($Config{'extensions'} !~ m!\bI18N/Langinfo\b! &&
	$Config{'extensions'} !~ m!\bPOSIX\b!) {
	print "1..0\n";
	exit 0;
    }
}

use I18N::Langinfo qw(langinfo ABDAY_1 DAY_1 ABMON_1 MON_1 RADIXCHAR);
use POSIX qw(setlocale LC_ALL);

setlocale(LC_ALL, "C");

print "1..5\n";

print "not " unless langinfo(ABDAY_1)   eq "Sun";
print "ok 1\n";

print "not " unless langinfo(DAY_1)     eq "Sunday";
print "ok 2\n";

print "not " unless langinfo(ABMON_1)   eq "Jan";
print "ok 3\n";

print "not " unless langinfo(MON_1)     eq "January";
print "ok 4\n";

print "not " unless langinfo(RADIXCHAR) eq ".";
print "ok 5\n";


#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require Config; import Config;
    if ($Config{'extensions'} !~ m!\bI18N/Langinfo\b! ||
	$Config{'extensions'} !~ m!\bPOSIX\b!)
    {
	print "1..0 # skip: I18N::Langinfo or POSIX unavailable\n";
	exit 0;
    }
}

use I18N::Langinfo qw(langinfo ABDAY_1 DAY_1 ABMON_1 MON_1 RADIXCHAR);
use POSIX qw(setlocale LC_ALL);
use Config;

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

unless (eval { langinfo(RADIXCHAR) } eq ".") {
    print "not ok 5 - RADIXCHAR undefined\n";
    if ($Config{d_gnulibc} || $Config{cppsymbols} =~ /__GNU_LIBRARY_/) {
	print <<EOM;
#
# You are probably using GNU libc. The RADIXCHAR not getting defined
# by I18N::Langinfo is a known problem in some older versions of the
# GNU libc (caused by the combination of using only enums, not cpp
# definitions, and of hiding the definitions behind rather obscure
# feature tests).  Upgrading your libc is strongly suggested. 
#
EOM
    }
} else {
    print "ok 5\n";
}


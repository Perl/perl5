BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

BEGIN {
    require Config; import Config;

    if ($Config{extensions} !~ m!\bTime/Piece\b!) {
	print "1..0 # Time::Piece not built\n";
	exit 0;
    }
}

print "1..75\n";

use Time::Piece;

print "ok 1\n";

my $t = gmtime(951827696); # 2001-02-29T12:34:56

print "not " unless $t->sec == 56;
print "ok 2\n";

print "not " unless $t->second == 56;
print "ok 3\n";

print "not " unless $t->min == 34;
print "ok 4\n";

#print "not " unless $t->minute == 34;
print "ok 5\n";

print "not " unless $t->hour == 12;
print "ok 6\n";

print "not " unless $t->mday == 29;
print "ok 7\n";

print "not " unless $t->day_of_month == 29;
print "ok 8\n";

print "not " unless $t->mon == 2;
print "ok 9\n";

print "not " unless $t->_mon == 1;
print "ok 10\n";

#print "not " unless $t->monname eq 'Feb';
print "ok 11\n";

print "not " unless $t->month eq 'Feb';
print "ok 12\n";

print "not " unless $t->year == 2000;
print "ok 13\n";

print "not " unless $t->_year == 100;
print "ok 14\n";

print "not " unless $t->wday == 3;
print "ok 15\n";

print "not " unless $t->_wday == 2;
print "ok 16\n";

print "not " unless $t->day_of_week == 2;
print "ok 17\n";

print "not " unless $t->wdayname eq 'Tue';
print "ok 18\n";

print "not " unless $t->day eq 'Tue';
print "ok 19\n";

print "not " unless $t->yday == 59;
print "ok 20\n";

print "not " unless $t->day_of_year == 59;
print "ok 21\n";

# In GMT there should be no daylight savings ever.

print "not " unless $t->isdst == 0;
print "ok 22\n";

print "not " unless $t->daylight_savings == 0;
print "ok 23\n";

print "not " unless $t->hms eq '12:34:56';
print "ok 24\n";

print "not " unless $t->time eq '12:34:56';
print "ok 25\n";

print "not " unless $t->ymd eq '2000-02-29';
print "ok 26\n";

print "not " unless $t->date eq '2000-02-29';
print "ok 27\n";

print "not " unless $t->mdy eq '02-29-2000';
print "ok 28\n";

print "not " unless $t->dmy eq '29-02-2000';
print "ok 29\n";

print "not " unless $t->cdate eq 'Tue Feb 29 12:34:56 2000';
print "ok 30\n";

print "not " unless "$t" eq 'Tue Feb 29 12:34:56 2000';
print "ok 31\n";

print "not " unless $t->datetime eq '2000-02-29T12:34:56';
print "ok 32\n";

print "not " unless $t->epoch == 951827696;
print "ok 33\n";

# ->tzoffset?

print "not " unless ($t->julian_day / 2451604.0075) - 1 < 0.001;
print "ok 34\n";

print "not " unless ($t->mjd        /   51603.5075) - 1 < 0.001;
print "ok 35\n";

print "not " unless $t->week == 9;
print "ok 36\n";

if ($Config{d_strftime}) {

    # %a, %A, %b, %B, %c are locale-dependent

    # %C is unportable: sometimes its like asctime(3) or date(1),
    # sometimes it's the century (and whether for 2000 the century is
    # 20 or 19, is fun, too..as far as I can read SUSv2 it should be 20.)

    print "not " unless $t->strftime('%d') == 29;
    print "ok 37\n";

    print "not " unless $t->strftime('%D') eq '02/29/00'; # Yech!
    print "ok 38\n";

    print "not " unless $t->strftime('%e') eq '29'; # should test with < 10
    print "ok 39\n";

    print "not " unless $t->strftime('%H') eq '12'; # should test with < 10
    print "ok 40\n";

     # %h is locale-dependent

    print "not " unless $t->strftime('%I') eq '12'; # should test with < 10
    print "ok 41\n";

    print "not " unless $t->strftime('%j') == 60; # why ->yday+1 ?
    print "ok 42\n";

    print "not " unless $t->strftime('%M') eq '34'; # should test with < 10
    print "ok 43\n";

    # %p, %P, and %r are not widely implemented,
    # and are possibly unportable (am or AM or a.m., and so on)

    print "not " unless $t->strftime('%R') eq '12:34'; # should test with > 12
    print "ok 44\n";

    print "not " unless $t->strftime('%S') eq '56'; # should test with < 10
    print "ok 45\n";

    print "not " unless $t->strftime('%T') eq '12:34:56'; # < 12 and > 12
    print "ok 46\n";

    # There are bugs in the implementation of %u in many platforms.
    # (e.g. Linux seems to think, despite the man page, that %u
    # 1-based on Sunday...)

    print "not " unless $t->strftime('%U') eq '09'; # Sun cmp Mon
    print "ok 47\n";

    print "not " unless $t->strftime('%V') eq '09'; # Sun cmp Mon
    print "ok 48\n";

    print "not " unless $t->strftime('%w') == 2;
    print "ok 49\n";

    print "not " unless $t->strftime('%W') eq '09'; # Sun cmp Mon
    print "ok 50\n";

    # %x is locale and implementation dependent.

    print "not " unless $t->strftime('%y') == 0; # should test with 1999
    print "ok 51\n";

    print "not " unless $t->strftime('%Y') eq '2000';
    print "ok 52\n";

    # %Z is locale and implementation dependent
    # (there is NO standard for timezone names)

} else {
    for (38...52) {
	print "ok $_ # Skip: no strftime\n";
    }
}

print "not " unless $t->date("") eq '20000229';
print "ok 53\n";

print "not " unless $t->ymd("") eq '20000229';
print "ok 54\n";
print "not " unless $t->mdy("/") eq '02/29/2000';
print "ok 55\n";

print "not " unless $t->dmy(".") eq '29.02.2000';
print "ok 56\n";

print "not " unless $t->date_separator() eq '-';
print "ok 57\n";

$t->date_separator("/");

print "not " unless $t->ymd eq '2000/02/29';
print "ok 58\n";

print "not " unless $t->date_separator() eq '/';
print "ok 59\n";

$t->date_separator("-");

print "not " unless $t->hms(".") eq '12.34.56';
print "ok 60\n";

print "not " unless $t->time_separator() eq ':';
print "ok 61\n";

$t->time_separator(".");

print "not " unless $t->hms eq '12.34.56';
print "ok 62\n";

print "not " unless $t->time_separator() eq '.';
print "ok 63\n";

$t->time_separator(":");

my @fidays = qw( sunnuntai maanantai tiistai keskiviikko torstai
	         perjantai lauantai );
my @frdays = qw( Dimanche Lundi Merdi Mercredi Jeudi Vendredi Samedi );

print "not " unless $t->day(@fidays) eq "tiistai";
print "ok 64\n";

my @days = $t->day_list();

$t->day_list(@frdays);

print "not " unless $t->day eq "Merdi";
print "ok 65\n";

$t->day_list(@days);

print "not " unless $t->day eq "Tue";
print "ok 66\n";

my @months = $t->mon_list();

my @dumonths = qw(januari februari maart april mei juni
	          juli augustus september oktober november december);

print "not " unless $t->month(@dumonths) eq "februari";
print "ok 67\n";

$t->mon_list(@dumonths);

print "not " unless $t->month eq "februari";
print "ok 68\n";

$t->mon_list(@months);

print "not " unless $t->month eq "Feb";
print "ok 69\n";

print "not " unless
    $t->datetime(date => '/', T => ' ', time => '-') eq "2000/02/29 12-34-56";
print "ok 70\n";

print "not " unless $t->is_leap_year; # should test more with different dates
print "ok 71\n";

print "not " unless $t->month_last_day == 29; # test more
print "ok 72\n";

print "not " if Time::Piece::_is_leap_year(1900);
print "ok 73\n";

print "not " if Time::Piece::_is_leap_year(1901);
print "ok 74\n";

print "not " unless Time::Piece::_is_leap_year(1904);
print "ok 75\n";


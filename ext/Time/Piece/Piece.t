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

print "1..86\n";

use Time::Piece;

print "ok 1\n";

my $t = gmtime(951827696); # 2001-02-29T12:34:56

print "not " unless $t->sec == 56;
print "ok 2\n";

print "not " unless $t->second == 56;
print "ok 3\n";

print "not " unless $t->min == 34;
print "ok 4\n";

print "not " unless $t->minute == 34;
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

print "not " unless $t->monname eq 'Feb';
print "ok 11\n";

print "not " unless $t->month eq 'February';
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

print "not " unless $t->weekday eq 'Tuesday';
print "ok 19\n";

print "not " unless $t->yday == 59;
print "ok 20\n";

print "not " unless $t->day_of_year == 59;
print "ok 21\n";

# In GMT there should be no daylight savings ever.

my $dst      = 0;;
my $dst_mess = '';
if ($^O eq 'os2') {
    # OS/2 EMX bug
    $dst      = CORE::gmtime(0))[8];
    $dst_mess = ' # skipped: gmtime(0) thinks DST gmtime 0 == -1';
	     
} 	
print "not " unless $t->isdst == $dst;
print "ok 22$dst_mess\n";

print "not " unless $t->daylight_savings == $dst;
print "ok 23$dst_mess\n";

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

    print "not " unless $t->strftime('%a') eq 'Tue';
    print "ok 37\n";

    print "not " unless $t->strftime('%A') eq 'Tuesday';
    print "ok 38\n";

    print "not " unless $t->strftime('%b') eq 'Feb';
    print "ok 39\n";

    print "not " unless $t->strftime('%B') eq 'February';
    print "ok 40\n";

    print "not " unless $t->strftime('%c') eq 'Tue Feb 29 12:34:56 2000';
    print "ok 41\n";

    print "not " unless $t->strftime('%C') == 20;
    print "ok 42\n";

    print "not " unless $t->strftime('%d') == 29;
    print "ok 43\n";

    print "not " unless $t->strftime('%D') eq '02/29/00'; # Yech!
    print "ok 44\n";

    print "not " unless $t->strftime('%e') eq '29'; # should test with < 10
    print "ok 45\n";

    print "not " unless $t->strftime('%H') eq '12'; # should test with < 10
    print "ok 46\n";

    print "not " unless $t->strftime('%b') eq 'Feb';
    print "ok 47\n";

    print "not " unless $t->strftime('%I') eq '12'; # should test with < 10
    print "ok 48\n";

    print "not " unless $t->strftime('%j') eq '059';
    print "ok 49\n";

    print "not " unless $t->strftime('%M') eq '34'; # should test with < 10
    print "ok 50\n";

    print "not " unless $t->strftime('%p') eq 'am';
    print "ok 51\n";

    print "not " unless $t->strftime('%r') eq '12:34:56 am';
    print "ok 52\n";

    print "not " unless $t->strftime('%R') eq '12:34'; # should test with > 12
    print "ok 53\n";

    print "not " unless $t->strftime('%S') eq '56'; # should test with < 10
    print "ok 54\n";

    print "not " unless $t->strftime('%T') eq '12:34:56'; # < 12 and > 12
    print "ok 55\n";

    print "not " unless $t->strftime('%u') == 2;
    print "ok 56\n";

    print "not " unless $t->strftime('%U') eq '09'; # Sun cmp Mon
    print "ok 57\n";

    print "not " unless $t->strftime('%V') eq '09'; # Sun cmp Mon
    print "ok 58\n";

    print "not " unless $t->strftime('%w') == 2;
    print "ok 59\n";

    print "not " unless $t->strftime('%W') eq '09'; # Sun cmp Mon
    print "ok 60\n";

    print "not " unless $t->strftime('%x') eq '02/29/00'; # Yech!
    print "ok 61\n";

    print "not " unless $t->strftime('%y') == 0; # should test with 1999
    print "ok 62\n";

    print "not " unless $t->strftime('%Y') eq '2000';
    print "ok 63\n";

    # %Z can't be tested, too unportable

} else {
    for (38...63) {
	print "ok $_ # Skip: no strftime\n";
    }
}

print "not " unless $t->ymd("") eq '20000229';
print "ok 64\n";

print "not " unless $t->mdy("/") eq '02/29/2000';
print "ok 65\n";

print "not " unless $t->dmy(".") eq '29.02.2000';
print "ok 66\n";

print "not " unless $t->date_separator() eq '-';
print "ok 67\n";

$t->date_separator("/");

print "not " unless $t->ymd eq '2000/02/29';
print "ok 68\n";

print "not " unless $t->date_separator() eq '/';
print "ok 69\n";

$t->date_separator("-");

print "not " unless $t->hms(".") eq '12.34.56';
print "ok 70\n";

print "not " unless $t->time_separator() eq ':';
print "ok 71\n";

$t->time_separator(".");

print "not " unless $t->hms eq '12.34.56';
print "ok 72\n";

print "not " unless $t->time_separator() eq '.';
print "ok 73\n";

$t->time_separator(":");

my @fidays = qw( sunnuntai maanantai tiistai keskiviikko torstai
	         perjantai lauantai );
my @frdays = qw( Dimanche Lundi Merdi Mercredi Jeudi Vendredi Samedi );

print "not " unless $t->weekday(@fidays) eq "tiistai";
print "ok 74\n";

my @days = $t->weekday_names();

Time::Piece::weekday_names(@frdays);

print "not " unless $t->weekday eq "Merdi";
print "ok 75\n";

Time::Piece::weekday_names(@days);

print "not " unless $t->weekday eq "Tuesday";
print "ok 76\n";

my @months = $t->mon_names();

my @dumonths = qw(januari februari maart april mei juni
	          juli augustus september oktober november december);

print "not " unless $t->month(@dumonths) eq "februari";
print "ok 77\n";

Time::Piece::month_names(@dumonths);

print "not " unless $t->month eq "februari";
print "ok 78\n";

Time::Piece::mon_names(@months);

print "not " unless $t->monname eq "Feb";
print "ok 79\n";

print "not " unless
    $t->datetime(date => '/', T => ' ', time => '-') eq "2000/02/29 12-34-56";
print "ok 80\n";

print "not " unless $t->is_leap_year;
print "ok 81\n";

print "not " unless $t->month_last_day == 29; # test more
print "ok 82\n";

print "not " if Time::Piece::_is_leap_year(1900);
print "ok 83\n";

print "not " if Time::Piece::_is_leap_year(1901);
print "ok 84\n";

print "not " unless Time::Piece::_is_leap_year(1904);
print "ok 85\n";

use Time::Piece 'strptime';

my %T = strptime("%T", "12:34:56");

print "not " unless keys %T == 3 && $T{H} == 12 && $T{M} == 34 && $T{S} == 56;
print "ok 86\n";


package Time::Piece;

use strict;
use vars qw($VERSION @ISA @EXPORT %EXPORT_TAGS);

require Exporter;
require DynaLoader;
use Time::Seconds;
use Carp;
use UNIVERSAL;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(
    localtime
    gmtime
);

%EXPORT_TAGS = ( 
        ':override' => 'internal',
        );

$VERSION = '0.13';

bootstrap Time::Piece $VERSION;

my $DATE_SEP = '-';
my $TIME_SEP = ':';
my @MON_NAMES = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @WDAY_NAMES = qw(Sun Mon Tue Wed Thu Fri Sat);
my @MONTH_NAMES = qw(January February March April May June
		     July August September October Novemeber December);
my @WEEKDAY_NAMES = qw(Sunday Monday Tuesday Wednesday
		       Thursday Friday Saturday);

use constant 'c_sec' => 0;
use constant 'c_min' => 1;
use constant 'c_hour' => 2;
use constant 'c_mday' => 3;
use constant 'c_mon' => 4;
use constant 'c_year' => 5;
use constant 'c_wday' => 6;
use constant 'c_yday' => 7;
use constant 'c_isdst' => 8;
use constant 'c_epoch' => 9;
use constant 'c_islocal' => 10;

sub localtime {
    my $time = shift;
    $time = time if (!defined $time);
    _mktime($time, 1);
}

sub gmtime {
    my $time = shift;
    $time = time if (!defined $time);
    _mktime($time, 0);
}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $time = shift;
    
    my $self;
    
    if (defined($time)) {
        $self = &localtime($time);
    }
    elsif (ref($proto) && $proto->isa('Time::Piece')) {
        $self = _mktime($proto->[c_epoch], $proto->[c_islocal]);
    }
    else {
        $self = &localtime();
    }
    
    return bless $self, $class;
}

sub _mktime {
    my ($time, $islocal) = @_;
    my @time = $islocal ? 
            CORE::localtime($time)
            :
            CORE::gmtime($time);
    wantarray ? @time : bless [@time, $time, $islocal], 'Time::Piece';
}

sub import {
    # replace CORE::GLOBAL localtime and gmtime if required
    my $class = shift;
    my %params;
    map($params{$_}++,@_,@EXPORT);
    if (delete $params{':override'}) {
        $class->export('CORE::GLOBAL', keys %params);
    }
    else {
        $class->export((caller)[0], keys %params);
    }
}

## Methods ##

sub s {
    my $time = shift;
    $time->[c_sec];
}

*sec = \&s;
*second = \&s;

sub min {
    my $time = shift;
    $time->[c_min];
}

*minute = \&min;

sub h {
    my $time = shift;
    $time->[c_hour];
}

*hour = \&h;

sub d {
    my $time = shift;
    $time->[c_mday];
}

*mday = \&d;
*day_of_month = \&d;

sub mon {
    my $time = shift;
    $time->[c_mon] + 1;
}

sub _mon {
    my $time = shift;
    $time->[c_mon];
}

sub monname {
    my $time = shift;
    if (@_) {
        return $_[$time->[c_mon]];
    }
    elsif (@MON_NAMES) {
        return $MON_NAMES[$time->[c_mon]];
    }
    else {
        return $time->strftime('%b');
    }
}

sub monthname {
    my $time = shift;
    if (@_) {
        return $_[$time->[c_mon]];
    }
    elsif (@MONTH_NAMES) {
        return $MONTH_NAMES[$time->[c_mon]];
    }
    else {
        return $time->strftime('%B');
    }
}

*month = \&monthname;

sub y {
    my $time = shift;
    $time->[c_year] + 1900;
}

*year = \&y;

sub _year {
    my $time = shift;
    $time->[c_year];
}

sub wday {
    my $time = shift;
    $time->[c_wday] + 1;
}

sub _wday {
    my $time = shift;
    $time->[c_wday];
}

*day_of_week = \&_wday;

sub wdayname {
    my $time = shift;
    if (@_) {
        return $_[$time->[c_wday]];
    }
    elsif (@WDAY_NAMES) {
        return $WDAY_NAMES[$time->[c_wday]];
    }
    else {
        return $time->strftime('%a');
    }
}

sub weekdayname {
    my $time = shift;
    if (@_) {
        return $_[$time->[c_wday]];
    }
    elsif (@WEEKDAY_NAMES) {
        return $WEEKDAY_NAMES[$time->[c_wday]];
    }
    else {
        return $time->strftime('%A');
    }
}

*weekdayname = \&weekdayname;
*weekday = \&weekdayname;

sub yday {
    my $time = shift;
    $time->[c_yday];
}

*day_of_year = \&yday;

sub isdst {
    my $time = shift;
    $time->[c_isdst];
}

*daylight_savings = \&isdst;

# Thanks to Tony Olekshy <olekshy@cs.ualberta.ca> for this algorithm
sub tzoffset {
    my $time = shift;

    my $epoch = $time->[c_epoch];

    my $j = sub { # Tweaked Julian day number algorithm.

        my ($s,$n,$h,$d,$m,$y) = @_; $m += 1; $y += 1900;

        # Standard Julian day number algorithm without constant.
        #
        my $y1 = $m > 2 ? $y : $y - 1;

        my $m1 = $m > 2 ? $m + 1 : $m + 13;

        my $day = int(365.25 * $y1) + int(30.6001 * $m1) + $d;

        # Modify to include hours/mins/secs in floating portion.
        #
        return $day + ($h + ($n + $s / 60) / 60) / 24;
    };

    # Compute floating offset in hours.
    #
    my $delta = 24 * (&$j(CORE::localtime $epoch) - &$j(CORE::gmtime $epoch));

    # Return value in seconds rounded to nearest minute.
    return Time::Seconds->new( int($delta * 60 + ($delta >= 0 ? 0.5 : -0.5)) * 60);
}

sub epoch {
    my $time = shift;
    $time->[c_epoch];
}

sub hms {
    my $time = shift;
    my $sep = @_ ? shift(@_) : $TIME_SEP;
    sprintf("%02d$sep%02d$sep%02d", $time->[c_hour], $time->[c_min], $time->[c_sec]);
}

*time = \&hms;

sub ymd {
    my $time = shift;
    my $sep = @_ ? shift(@_) : $DATE_SEP;
    sprintf("%d$sep%02d$sep%02d", $time->year, $time->mon, $time->[c_mday]);
}

*date = \&ymd;

sub mdy {
    my $time = shift;
    my $sep = @_ ? shift(@_) : $DATE_SEP;
    sprintf("%02d$sep%02d$sep%d", $time->mon, $time->[c_mday], $time->year);
}

sub dmy {
    my $time = shift;
    my $sep = @_ ? shift(@_) : $DATE_SEP;
    sprintf("%02d$sep%02d$sep%d", $time->[c_mday], $time->mon, $time->year);
}

sub datetime {
    my $time = shift;
    my %seps = (date => $DATE_SEP, T => 'T', time => $TIME_SEP, @_);
    return join($seps{T}, $time->date($seps{date}), $time->time($seps{time}));
}

# taken from Time::JulianDay
sub julian_day {
    my $time = shift;
    my ($year, $month, $day) = ($time->year, $time->mon, $time->mday);
    my ($tmp, $secs);

    $tmp = $day - 32075
      + 1461 * ( $year + 4800 - ( 14 - $month ) / 12 )/4
      + 367 * ( $month - 2 + ( ( 14 - $month ) / 12 ) * 12 ) / 12
      - 3 * ( ( $year + 4900 - ( 14 - $month ) / 12 ) / 100 ) / 4
      ;

    return $tmp;
}

# Hi Mark-Jason!
sub mjd {
    return shift->julian_day - 2_400_000.5;
}

sub week {
    # taken from the Calendar FAQ
    use integer;
    my $J  = shift->julian_day;
    my $d4 = ((($J + 31741 - ($J % 7)) % 146097) % 36524) % 1461;
    my $L  = $d4 / 1460;
    my $d1 = (($d4 - $L) % 365) + $L;
    return $d1 / 7 + 1;
}

sub _is_leap_year {
    my $year = shift;
    return (($year %4 == 0) && !($year % 100 == 0)) || ($year % 400 == 0)
               ? 1 : 0;
}

sub is_leap_year {
    my $time = shift;
    my $year = $time->year;
    return _is_leap_year($year);
}

my @MON_LAST = qw(31 28 31 30 31 30 31 31 30 31 30 31);

sub month_last_day {
    my $time = shift;
    my $year = $time->year;
    my $_mon = $time->_mon;
    return $MON_LAST[$_mon] + ($_mon == 1 ? _is_leap_year($year) : 0);
}

use vars qw($_ftime);

$_ftime =
{
 '%' => sub {
     return "%";
 }, 
 'a' => sub {
     my ($format, $time, @rest) = @_;
     $time->wdayname(@rest);
 }, 
 'A' => sub {
     my ($format, $time, @rest) = @_;
     $time->weekdayname(@rest);
 }, 
 'b' => sub {
     my ($format, $time, @rest) = @_;
     $time->monname(@rest);
 }, 
 'B' => sub {
     my ($format, $time, @rest) = @_;
     $time->monthname(@rest);
 }, 
 'c' => sub {
     my ($format, $time, @rest) = @_;
     $time->cdate(@rest);
 }, 
 'C' => sub {
     my ($format, $time, @rest) = @_;
     sprintf("%02d", int($time->y(@rest) / 100));
 }, 
 'd' => sub {
     my ($format, $time, @rest) = @_;
     sprintf("%02d", $time->d(@rest));
 }, 
 'D' => sub {
     my ($format, $time, @rest) = @_;
     join("/",
	  $_ftime->{'m'}->('m', $time, @rest),
	  $_ftime->{'d'}->('d', $time, @rest),
	  $_ftime->{'y'}->('y', $time, @rest));
 }, 
 'e' => sub {
     my ($format, $time, @rest) = @_;
     sprintf("%2d", $time->d(@rest));
 }, 
 'f' => sub {
     my ($format, $time, @rest) = @_;
     $time->monname(@rest);
 }, 
 'H' => sub {
     my ($format, $time, @rest) = @_;
     sprintf("%02d", $time->h(@rest));
 }, 
 'I' => sub {
     my ($format, $time, @rest) = @_;
     my $h = $time->h(@rest);
     sprintf("%02d", $h == 0 ? 12 : ($h < 13 ? $h : $h % 12));
 }, 
 'j' => sub {
     my ($format, $time, @rest) = @_;
     sprintf("%03d", $time->yday(@rest));
 }, 
 'm' => sub {
     my ($format, $time, @rest) = @_;
     sprintf("%02d", $time->mon(@rest));
 }, 
 'M' => sub {
     my ($format, $time, @rest) = @_;
     sprintf("%02d", $time->min(@rest));
 }, 
 'n' => sub {
     return "\n";
 }, 
 'p' => sub {
     my ($format, $time, @rest) = @_;
     my $h = $time->h(@rest);
     $h == 0 ? 'pm' : ($h < 13 ? 'am' : 'pm');
 }, 
 'r' => sub {
     my ($format, $time, @rest) = @_;
     join(":",
	  $_ftime->{'I'}->('I', $time, @rest),
	  $_ftime->{'M'}->('M', $time, @rest),
	  $_ftime->{'S'}->('S', $time, @rest)) .
	      " " . $_ftime->{'p'}->('p', $time, @rest);
 }, 
 'R' => sub {
     my ($format, $time, @rest) = @_;
     join(":",
	  $_ftime->{'H'}->('H', $time, @rest),
	  $_ftime->{'M'}->('M', $time, @rest));
 }, 
 'S' => sub {
     my ($format, $time, @rest) = @_;
     sprintf("%02d", $time->s(@rest));
 }, 
 't' => sub {
     return "\t";
 }, 
 'T' => sub {
     my ($format, $time, @rest) = @_;
     join(":",
	  $_ftime->{'H'}->('H', $time, @rest),
	  $_ftime->{'M'}->('M', $time, @rest),
	  $_ftime->{'S'}->('S', $time, @rest));
 }, 
 'u' => sub {
     my ($format, $time, @rest) = @_;
     ($time->wday(@rest) + 5) % 7 + 1;
 }, 
 'V' => sub {
     my ($format, $time, @rest) = @_;
     sprintf("%02d", $time->week(@rest));
 }, 
 'w' => sub {
     my ($format, $time, @rest) = @_;
     $time->_wday(@rest);
 }, 
 'x' => sub {
     my ($format, $time, @rest) = @_;
     join("/",
	  $_ftime->{'m'}->('m', $time, @rest),
	  $_ftime->{'d'}->('d', $time, @rest),
	  $_ftime->{'y'}->('y', $time, @rest));
 },
 'y' => sub {
     my ($format, $time, @rest) = @_;
     sprintf("%02d", $time->y(@rest) % 100);
 }, 
 'Y' => sub {
     my ($format, $time, @rest) = @_;
     sprintf("%4d", $time->y(@rest));
 }, 
};

sub _ftime {
    my ($format, $time, @rest) = @_;
    if (exists $_ftime->{$format}) {
	# We are passing format to the anonsubs so that
	# one can share the same sub among several formats.
	return $_ftime->{$format}->($format, $time, @rest);
    }
    return $time->_strftime("%$format"); # cheat
}

sub strftime {
    my $time = shift;
    my $format = @_ ? shift(@_) : "%a, %d %b %Y %H:%M:%S %Z";
    $format =~ s/%(.)/_ftime($1, $time, @_)/ge;
    return $format;
}

sub _strftime {
    my $time = shift;
    my $format = @_ ? shift(@_) : "%a, %d %b %Y %H:%M:%S %Z";
    return __strftime($format, (@$time)[c_sec..c_isdst]);
}

sub wday_names {
    shift if ref($_[0]) && $_[0]->isa(__PACKAGE__); # strip first if called as a method
    my @old = @WDAY_NAMES;
    if (@_) {
        @WDAY_NAMES = @_;
    }
    return @old;
}

sub weekday_names {
    shift if ref($_[0]) && $_[0]->isa(__PACKAGE__); # strip first if called as a method
    my @old = @WEEKDAY_NAMES;
    if (@_) {
        @WEEKDAY_NAMES = @_;
    }
    return @old;
}

sub mon_names {
    shift if ref($_[0]) && $_[0]->isa(__PACKAGE__); # strip first if called as a method
    my @old = @MON_NAMES;
    if (@_) {
        @MON_NAMES = @_;
    }
    return @old;
}

sub month_names {
    shift if ref($_[0]) && $_[0]->isa(__PACKAGE__); # strip first if called as a method
    my @old = @MONTH_NAMES;
    if (@_) {
        @MONTH_NAMES = @_;
    }
    return @old;
}

sub time_separator {
    shift if ref($_[0]) && $_[0]->isa(__PACKAGE__);
    my $old = $TIME_SEP;
    if (@_) {
        $TIME_SEP = $_[0];
    }
    return $old;
}

sub date_separator {
    shift if ref($_[0]) && $_[0]->isa(__PACKAGE__);
    my $old = $DATE_SEP;
    if (@_) {
        $DATE_SEP = $_[0];
    }
    return $old;
}

use overload '""' => \&cdate;

sub cdate {
    my $time = shift;
    if ($time->[c_islocal]) {
        return scalar(CORE::localtime($time->[c_epoch]));
    }
    else {
        return scalar(CORE::gmtime($time->[c_epoch]));
    }
}

use overload
        '-' => \&subtract,
        '+' => \&add;

sub subtract {
    my $time = shift;
    my $rhs = shift;
    die "Can't subtract a date from something!" if shift;
    
    if (ref($rhs) && $rhs->isa('Time::Piece')) {
        return Time::Seconds->new($time->[c_epoch] - $rhs->epoch);
    }
    else {
        # rhs is seconds.
        return _mktime(($time->[c_epoch] - $rhs), $time->[c_islocal]);
    }
}

sub add {
    warn "add\n";
    my $time = shift;
    my $rhs = shift;
    croak "Invalid rhs of addition: $rhs" if ref($rhs);
    
    return _mktime(($time->[c_epoch] + $rhs), $time->[c_islocal]);
}

use overload
        '<=>' => \&compare;

sub get_epochs {
    my ($time, $rhs, $reverse) = @_;
    $time = $time->epoch;
    if (UNIVERSAL::isa($rhs, 'Time::Piece')) {
        $rhs = $rhs->epoch;
    }
    if ($reverse) {
        return $rhs, $time;
    }
    return $time, $rhs;
}

sub compare {
    my ($lhs, $rhs) = get_epochs(@_);
    return $lhs <=> $rhs;
}

1;
__END__

=head1 NAME

Time::Piece - Object Oriented time objects

=head1 SYNOPSIS

    use Time::Piece;
    
    my $t = localtime;
    print "Time is $t\n";
    print "Year is ", $t->year, "\n";

=head1 DESCRIPTION

This module replaces the standard localtime and gmtime functions with
implementations that return objects. It does so in a backwards
compatible manner, so that using localtime/gmtime in the way documented
in perlfunc will still return what you expect.

The module actually implements most of an interface described by
Larry Wall on the perl5-porters mailing list here:
http://www.xray.mpe.mpg.de/mailing-lists/perl5-porters/2000-01/msg00241.html

=head1 USAGE

After importing this module, when you use localtime or gmtime in a scalar
context, rather than getting an ordinary scalar string representing the
date and time, you get a Time::Piece object, whose stringification happens
to produce the same effect as the localtime and gmtime functions. There is 
also a new() constructor provided, which is the same as localtime(), except
when passed a Time::Piece object, in which case it's a copy constructor. The
following methods are available on the object:

    $t->s                    # 0..61 [1]
                             # and 61: leap second and double leap second
    $t->sec                  # same as $t->s
    $t->second               # same as $t->s
    $t->min                  # 0..59
    $t->h                    # 0..24
    $t->hour                 # same as $t->h
    $t->d                    # 1..31
    $t->mday                 # same as $t->d
    $t->mon                  # 1 = January
    $t->_mon                 # 0 = January
    $t->monname              # Feb
    $t->monthname            # February
    $t->month                # same as $t->monthname
    $t->y                    # based at 0 (year 0 AD is, of course 1 BC)
    $t->year                 # same as $t->y
    $t->_year                # year minus 1900
    $t->wday                 # 1 = Sunday
    $t->day_of_week          # 0 = Sunday
    $t->_wday                # 0 = Sunday
    $t->wdayname             # Tue
    $t->weekdayname          # Tuesday
    $t->weekday              # same as weekdayname
    $t->yday                 # also available as $t->day_of_year, 0 = Jan 01
    $t->isdst                # also available as $t->daylight_savings
    $t->daylight_savings     # same as $t->isdst

    $t->hms                  # 12:34:56
    $t->hms(".")             # 12.34.56
    $t->time                 # same as $t->hms

    $t->ymd                  # 2000-02-29
    $t->date                 # same as $t->ymd
    $t->mdy                  # 02-29-2000
    $t->mdy("/")             # 02/29/2000
    $t->dmy                  # 29-02-2000
    $t->dmy(".")             # 29.02.2000
    $t->datetime             # 2000-02-29T12:34:56 (ISO 8601)
    $t->cdate                # Tue Feb 29 12:34:56 2000
    "$t"                     # same as $t->cdate
   
    $t->epoch                # seconds since the epoch
    $t->tzoffset             # timezone offset in a Time::Seconds object

    $t->julian_day           # number of days since Julian period began
    $t->mjd                  # modified Julian day

    $t->week                 # week number (ISO 8601)

    $t->is_leap_year         # true if it its
    $t->month_last_day       # 28-31

    $t->time_separator($s)   # set the default separator (default ":")
    $t->date_separator($s)   # set the default separator (default "-")
    $t->wday(@days)          # set the default weekdays, abbreviated
    $t->weekday_names(@days) # set the default weekdays
    $t->mon_names(@days)     # set the default months, abbreviated
    $t->month_names(@days)   # set the default months

    $t->strftime($format)    # data and time formatting
    $t->strftime()           # "Tue, 29 Feb 2000 12:34:56 GMT"

    $t->_strftime($format)   # same as POSIX::strftime (without the
                             # overhead of the full POSIX extension),
                             # calls the operating system libraries,
                             # as opposed to $t->strftime()

=head2 Local Locales

Both wdayname (day) and monname (month) allow passing in a list to use
to index the name of the days against. This can be useful if you need
to implement some form of localisation without actually installing or
using locales.

  my @days = qw( Dimanche Lundi Merdi Mercredi Jeudi Vendredi Samedi );
  
  my $french_day = localtime->day(@days);

These settings can be overriden globally too:

  Time::Piece::weekday_names(@days);

Or for months:

  Time::Piece::month_names(@months);

And locally for months:

  print localtime->month(@months);

=head2 Date Calculations

It's possible to use simple addition and subtraction of objects:

    use Time::Seconds;
    
    my $seconds = $t1 - $t2;
    $t1 += ONE_DAY; # add 1 day (constant from Time::Seconds)

The following are valid ($t1 and $t2 are Time::Piece objects):

    $t1 - $t2; # returns Time::Seconds object
    $t1 - 42; # returns Time::Piece object
    $t1 + 533; # returns Time::Piece object

However adding a Time::Piece object to another Time::Piece object
will cause a runtime error.

Note that the first of the above returns a Time::Seconds object, so
while examining the object will print the number of seconds (because
of the overloading), you can also get the number of minutes, hours,
days, weeks and years in that delta, using the Time::Seconds API.

=head2 Date Comparisons

Date comparisons are also possible, using the full suite of "<", ">",
"<=", ">=", "<=>", "==" and "!=".

=head2 YYYY-MM-DDThh:mm:ss

The ISO 8601 standard defines the date format to be YYYY-MM-DD, and
the time format to be hh:mm:ss (24 hour clock), and if combined, they
should be concatenated with date first and with a capital 'T' in front
of the time.

=head2 Week Number

The I<week number> may be an unknown concept to some readers.  The ISO
8601 standard defines that weeks begin on a Monday and week 1 of the
year is the week that includes both January 4th and the first Thursday
of the year.  In other words, if the first Monday of January is the
2nd, 3rd, or 4th, the preceding days of the January are part of the
last week of the preceding year.  Week numbers range from 1 to 53.

=head2 Global Overriding

Finally, it's possible to override localtime and gmtime everywhere, by
including the ':override' tag in the import list:

    use Time::Piece ':override';

=head1 SEE ALSO

The excellent Calendar FAQ at http://www.tondering.dk/claus/calendar.html

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

This module is based on Time::Object, with changes suggested by Jarkko
Hietaniemi before including in core perl.

=head2 License

This module is free software, you may distribute it under the same terms
as Perl.

=head2 Bugs

The test harness leaves much to be desired. Patches welcome.

=cut

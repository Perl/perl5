package Time::Piece;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;
require DynaLoader;
use Time::Seconds;
use Carp;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(
    localtime
    gmtime
);

@EXPORT_OK = qw(
    strptime
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

sub has_mon_names {
    my $time = shift;
    return 0;
}

sub monname {
    my $time = shift;
    if (@_) {
        return $_[$time->[c_mon]];
    }
    elsif ($time->has_mon_names) {
        return $time->mon_name($time->[c_mon]);
    }
    return $MON_NAMES[$time->[c_mon]];
}

sub has_month_names {
    my $time = shift;
    return 0;
}

sub monthname {
    my $time = shift;
    if (@_) {
        return $_[$time->[c_mon]];
    }
    elsif ($time->has_month_names) {
        return $time->month_name($time->[c_mon]);
    }
    return $MONTH_NAMES[$time->[c_mon]];
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

sub has_wday_names {
    my $time = shift;
    return 0;
}

sub wdayname {
    my $time = shift;
    if (@_) {
        return $_[$time->[c_wday]];
    }
    elsif ($time->has_wday_names) {
        return $time->wday_name($time->[c_mon]);
    }
    return $WDAY_NAMES[$time->[c_wday]];
}

sub has_weekday_names {
    my $time = shift;
    return 0;
}

sub weekdayname {
    my $time = shift;
    if (@_) {
        return $_[$time->[c_wday]];
    }
    elsif ($time->has_weekday_names) {
        return $time->weekday_name($time->[c_mon]);
    }
    return $WEEKDAY_NAMES[$time->[c_wday]];
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
     my ($format, $time) = @_;
     $time->wdayname();
 }, 
 'A' => sub {
     my ($format, $time) = @_;
     $time->weekdayname();
 }, 
 'b' => sub {
     my ($format, $time) = @_;
     $time->monname();
 }, 
 'B' => sub {
     my ($format, $time) = @_;
     $time->monthname();
 }, 
 'c' => sub {
     my ($format, $time) = @_;
     $time->cdate();
 }, 
 'C' => sub {
     my ($format, $time) = @_;
     sprintf("%02d", int($time->y() / 100));
 }, 
 'd' => sub {
     my ($format, $time) = @_;
     sprintf("%02d", $time->d());
 }, 
 'D' => sub {
     my ($format, $time) = @_;
     join("/",
	  $_ftime->{'m'}->('m', $time),
	  $_ftime->{'d'}->('d', $time),
	  $_ftime->{'y'}->('y', $time));
 }, 
 'e' => sub {
     my ($format, $time) = @_;
     sprintf("%2d", $time->d());
 }, 
 'h' => sub {
     my ($format, $time, @rest) = @_;
     $time->monname(@rest);
 }, 
 'H' => sub {
     my ($format, $time) = @_;
     sprintf("%02d", $time->h());
 }, 
 'I' => sub {
     my ($format, $time) = @_;
     my $h = $time->h();
     sprintf("%02d", $h == 0 ? 12 : ($h < 13 ? $h : $h % 12));
 }, 
 'j' => sub {
     my ($format, $time) = @_;
     sprintf("%03d", $time->yday());
 }, 
 'm' => sub {
     my ($format, $time) = @_;
     sprintf("%02d", $time->mon());
 }, 
 'M' => sub {
     my ($format, $time) = @_;
     sprintf("%02d", $time->min());
 }, 
 'n' => sub {
     return "\n";
 }, 
 'p' => sub {
     my ($format, $time) = @_;
     my $h = $time->h();
     $h == 0 ? 'pm' : ($h < 13 ? 'am' : 'pm');
 }, 
 'r' => sub {
     my ($format, $time) = @_;
     join(":",
	  $_ftime->{'I'}->('I', $time),
	  $_ftime->{'M'}->('M', $time),
	  $_ftime->{'S'}->('S', $time)) .
	      " " . $_ftime->{'p'}->('p', $time);
 }, 
 'R' => sub {
     my ($format, $time) = @_;
     join(":",
	  $_ftime->{'H'}->('H', $time),
	  $_ftime->{'M'}->('M', $time));
 }, 
 'S' => sub {
     my ($format, $time) = @_;
     sprintf("%02d", $time->s());
 }, 
 't' => sub {
     return "\t";
 }, 
 'T' => sub {
     my ($format, $time) = @_;
     join(":",
	  $_ftime->{'H'}->('H', $time),
	  $_ftime->{'M'}->('M', $time),
	  $_ftime->{'S'}->('S', $time));
 }, 
 'u' => sub {
     my ($format, $time) = @_;
     ($time->wday() + 5) % 7 + 1;
 }, 
 # U taken care by libc
 'V' => sub {
     my ($format, $time) = @_;
     sprintf("%02d", $time->week());
 }, 
 'w' => sub {
     my ($format, $time) = @_;
     $time->_wday();
 }, 
 # W taken care by libc
 'x' => sub {
     my ($format, $time) = @_;
     join("/",
	  $_ftime->{'m'}->('m', $time),
	  $_ftime->{'d'}->('d', $time),
	  $_ftime->{'y'}->('y', $time));
 },
 'y' => sub {
     my ($format, $time) = @_;
     sprintf("%02d", $time->y() % 100);
 }, 
 'Y' => sub {
     my ($format, $time) = @_;
     sprintf("%4d", $time->y());
 }, 
 # Z taken care by libc
};

sub has_ftime {
    my ($format) = @_;
    exists $_ftime->{$format};
}

sub has_ftimes {
    keys %$_ftime;
}

sub delete_ftime {
    delete $_ftime->{@_};
}

sub ftime {
    my ($format) = $_[0];
    if (@_ == 1) {
	return $_ftime->{$format};
    } elsif (@_ == 2) {
	if (ref $_[0] eq 'CODE') {
	    $_ftime->{$format} = $_[1];
	} else {
	    require Carp;
	    Carp::croak "ftime: second argument not a code ref";
	}
    } else {
	require Carp;
	Carp::croak "ftime: want one or two arguments";
    }
}

sub _ftime {
    my ($format, $time, @rest) = @_;
    if (has_ftime($format)) {
	# We are passing format to the anonsubs so that
	# one can share the same sub among several formats.
	return $_ftime->{$format}->($format, $time, @rest);
    }
    # If we don't know it, pass it down to the libc layer.
    # (In other words, cheat.)
    # This pays for for '%Z', though, and for all the
    # locale-specific %Ex and %Oy formats.
    return $time->_strftime("%$format");
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

use vars qw($_ptime);

$_ptime =
{
 '%' => sub {
     $_[1] =~ s/^%//                      && $1;
 },
 # a unimplemented
 # A unimplemented
 # b unimplemented
 # B unimplemented
 # c unimplemented
 'C' => sub {
     $_[1] =~ s/^(0[0-9])//               && $1;
 },
 'd' => sub {
     $_[1] =~ s/^(0[1-9]|2[0-9]|3[01])//  && $1;
 },
 'D' => sub {
     my %D;
     my $D;
     if (defined ($D = $_ptime->{'m'}->($_[0], $_[1]))) {
	 $D{m} = $D;
     } else {
	 return;
     }
     $_[1] =~ s:^/:: || return;
     if (defined ($D = $_ptime->{'d'}->($_[0], $_[1]))) {
	 $D{d} = $D;
     } else {
	 return;
     }
     $_[1] =~ s:^/:: || return;
     if (defined ($D = $_ptime->{'y'}->($_[0], $_[1]))) {
	 $D{y} = $D;
     } else {
	 return;
     }
     return { %D };
 },
 'e' => sub {
     $_[1] =~ s/^( [1-9]|2[0-9]|3[01])//  && $1;
 },
 # h unimplemented
 'H' => sub {
     $_[1] =~ s/^([0-1][0-9]|2[0-3])//    && $1;
 },
 'I' => sub {
     $_[1] =~ s/^(0[1-9]|1[012])//        && $1;
 },
 'j' => sub {
     $_[1] =~ s/^([0-9][0-9][0-9])// && $1 >= 1 && $1 <= 366 && $1;
 },
 'm' => sub {
     $_[1] =~ s/^(0[1-9]|1[012])//        && $1;
 },
 'M' => sub {
     $_[1] =~ s/^([0-5][0-9])//           && $1;
 },
 't' => sub {
     $_[1] =~ s/^\n//                     && $1;
 },
 'p' => sub {
     $_[1] =~ s/^(am|pm)//                && $1;
 },
 'r' => sub {
     my %r;
     my $r;
     if (defined ($r = $_ptime->{'I'}->($_[0], $_[1]))) {
	 $r{I} = $r;
     } else {
	 return;
     }
     $_[1] =~ s/^:// || return;
     if (defined ($r = $_ptime->{'M'}->($_[0], $_[1]))) {
	 $r{M} = $r;
     } else {
	 return;
     }
     $_[1] =~ s/^:// || return;
     if (defined ($r = $_ptime->{'S'}->($_[0], $_[1]))) {
	 $r{S} = $r;
     } else {
	 return;
     }
     $_[1] =~ s/^ // || return;
     if (defined ($r = $_ptime->{'p'}->($_[0], $_[1]))) {
	 $r{p} = $r;
     } else {
	 return;
     }
     return { %r };
 },
 'R' => sub {
     my %R;
     my $R;
     if (defined ($R = $_ptime->{'H'}->($_[0], $_[1]))) {
	 $R{H} = $R;
     } else {
	 return;
     }
     $_[1] =~ s/^:// || return;
     if (defined ($R = $_ptime->{'M'}->($_[0], $_[1]))) {
	 $R{M} = $R;
     } else {
	 return;
     }
     return { %R };
 },
 'S' => sub {
     $_[1] =~ s/^([0-5][0-9])//           && $1;
 },
 't' => sub {
     $_[1] =~ s/^\t//                     && $1;
 },
 'T' => sub {
     my %T;
     my $T;
     if (defined ($T = $_ptime->{'H'}->($_[0], $_[1]))) {
	 $T{H} = $T;
     } else {
	 return;
     }
     $_[1] =~ s/^:// || return;
     if (defined ($T = $_ptime->{'M'}->($_[0], $_[1]))) {
	 $T{M} = $T;
     } else {
	 return;
     }
     $_[1] =~ s/^:// || return;
     if (defined ($T = $_ptime->{'S'}->($_[0], $_[1]))) {
	 $T{S} = $T;
     } else {
	 return;
     }
     return { %T };
 },
 # u unimplemented
 # U unimplemented
 # w unimplemented
 # W unimplemented
 'x' => sub {
     my %x;
     my $x;
     if (defined ($x = $_ptime->{'m'}->($_[0], $_[1]))) {
	 $x{m} = $x;
     } else {
	 return;
     }
     $_[1] =~ s:^/:: || return;
     if (defined ($x = $_ptime->{'d'}->($_[0], $_[1]))) {
	 $x{d} = $x;
     } else {
	 return;
     }
     $_[1] =~ s:^/:: || return;
     if (defined ($x = $_ptime->{'y'}->($_[0], $_[1]))) {
	 $x{y} = $x;
     } else {
	 return;
     }
     return { %x };
 },
 'y' => sub {
     $_[1] =~ s/^([0-9][0-9])//           && $1;
 },
 'Y' => sub {
     $_[1] =~ s/^([1-9][0-9][0-9][0-9])// && $1;
 },
 # Z too unportable
};

sub has_ptime {
    my ($format) = @_;
    exists $_ptime->{$format};
}

sub has_ptimes {
    keys %$_ptime;
}

sub delete_ptime {
    delete $_ptime->{@_};
}

sub ptime {
    my ($format) = $_[0];
    if (@_ == 1) {
	return $_ptime->{$format};
    } elsif (@_ == 2) {
	if (ref $_[0] eq 'CODE') {
	    $_ptime->{$format} = $_[1];
	} else {
	    require Carp;
	    Carp::croak "ptime: second argument not a code ref";
	}
    } else {
	require Carp;
	Carp::croak "ptime: want one or two arguments";
    }
}

sub _ptime {
    my ($format, $stime) = @_;
    if (has_ptime($format)) {
	# We are passing format to the anonsubs so that
	# one can share the same sub among several formats.
	return $_ptime->{$format}->($format, $_[1]);
    }
    die "strptime: unknown format %$format (time '$stime')\n";
}

sub strptime {
    my $format = shift;
    my $stime =  shift;
    my %ptime;

    while ($format ne '') {
	if ($format =~ s/^([^%]+)//) {
	    my $skip = $1;
	    last unless $stime =~ s/^\Q$skip//;
	}
	while ($format =~ s/^%(.)//) {
	    my $f = $1;
	    my $t = _ptime($f, $stime);
	    if (defined $t) {
		if (ref $t eq 'HASH') {
		    @ptime{keys %$t} = values %$t;
		} else {
		    $ptime{$f} = $t;
		}
	    }
	}
    }

    return %ptime;
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

After importing this module, when you use localtime(0 or gmtime() in
scalar context, rather than getting an ordinary scalar string
representing the date and time, you get a Time::Piece object, whose
stringification happens to produce the same effect as the localtime()
and gmtime(0 functions.

There is also a new() constructor provided, which is the same as
localtime(), except when passed a Time::Piece object, in which case
it's a copy constructor.

The following methods are available on the object:

    $t->s                    # 0..61
                             # 60 and 61: leap second and double leap second
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

    $t->is_leap_year                  # true if it its
    Time::Piece::_is_leap_year($year) # true if it its
    $t->month_last_day                # 28..31

    $t->time_separator($s)   # set the default separator (default ":")
    $t->date_separator($s)   # set the default separator (default "-")
    $t->wday_names(@days)    # set the default weekday names, abbreviated
    $t->weekday_names(@days) # set the default weekday names
    $t->mon_names(@days)     # set the default month names, abbreviated
    $t->month_names(@days)   # set the default month names

    $t->strftime($format)    # date and time formatting
    $t->strftime()           # "Tue, 29 Feb 2000 12:34:56 GMT"

    $t->_strftime($format)   # same as POSIX::strftime (without the
                             # overhead of the full POSIX extension),
                             # calls the operating system libraries,
                             # as opposed to $t->strftime()

    use Time::Piece 'strptime'; # date parsing
    my %p = strptime("%H:%M", "12:34"); # $p{H} and ${M} will be set

=head2 Local Locales

Both wdayname (day) and monname (month) allow passing in a list to use
to index the name of the days against. This can be useful if you need
to implement some form of localisation without actually installing or
using the locales provided by the operating system.

  my @weekdays = qw( Dimanche Lundi Merdi Mercredi Jeudi Vendredi Samedi );
  
  my $french_day = localtime->day(@weekdays);

These settings can be overriden globally too:

  Time::Piece::weekday_names(@weekdays);
  Time::Piece::wday_names(@wdays);

Or for months:

  Time::Piece::month_names(@months);
  Time::Piece::mon_names(@mon);

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
should be concatenated with the date first and with a capital 'T' in
front of the time.

=head2 Week Number

The I<week number> may be an unknown concept to some readers.  The ISO
8601 standard defines that weeks begin on a Monday and week 1 of the
year is the week that includes both January the 4th and the first
Thursday of the year.  In other words, if the first Monday of January
is the 2nd, 3rd, or 4th, the preceding days of the January are part of
the last week of the preceding year.  Week numbers range from 1 to 53.

=head2 strftime method

The strftime() method can be used to format Time::Piece objects for output.
The argument to strftime() is the format string to be used, for example:

	$t->strftime("%H:%M");

will output the hours and minutes concatenated with a colon.  The
available format characters are as in the standard strftime() function
(unless otherwise indicated the implementation is in pure Perl,
no operating system strftime() is invoked):

=over 4

=item %%

The percentage character "%".

=item %a

The abbreviated weekday name, e.g. 'Tue'.  Note that the abbreviations
are not necessarily three characters wide in all languages.

=item %A

The weekday name, e.g. 'Tuesday'.

=item %b

The abbreviated month name, e.g. 'Feb'.  Note that the abbreviations
are not necessarily three characters wide in all languages.

=item %B

The month name, e.g. 'February'.

=item %c

The ctime format, or the localtime()/gmtime() format: C<%a %b %m %H:%M:%S %Y>.

(Should be avoided: use $t->timedate instead.)

=item %C

The 'centuries' number, e.g. 19 for the year 1999 and 20 for the year 2000.

=item %d

The zero-filled right-aligned day of the month, e.g. '09' or '10'.

=item %D

C<%m/%d/%d>.

(Should be avoided: use $t->date instead.)

=item %e

The space-filled right-aligned day of the month, e.g. ' 9' or '10'.

=item %h

Same as C<%b>, the abbreviated monthname.

=item %H

The zero-filled right-aligned hours in 24 hour clock, e.g. '09' or '10'.

=item %I

The zero-filled right-aligned hours in 12 hour clock, e.g. '09' or '10'.

=item %j

The zero-filled right-aligned day of the year, e.g. '001' or '365'.

=item %m

The zero-filled right-aligned month number, e.g. '09' or '10'.

=item %M

The zero-filled right-aligned minutes, e.g. '09' or '10'.

=item %n

The newline character "\n".

=item %p

Notice that this is somewhat meaningless in 24 hour clocks.

=item %r

C<%I:%M:%S %p>.

(Should be avoided: use $t->time instead.)

=item %R

C<%H:%M>.

=item %S

The zero-filled right-aligned seconds, e.g. '09' or '10'.

=item %t

The tabulator character "\t".

=item %T

C<%H:%M%S>

(Should be avoided: use $t->time instead.)

=item %u

The day of the week with Monday as 1 (one) and Sunday as 7.

=item %U

The zero-filled right-aligned week number of the year, Sunday as the
first day of the week, from '00' to '53'.

(Currently taken care by the operating system strftime().)

=item %V

The zero-filled right-aligned week of the year, e.g. '01' or '53'.
(ISO 8601)

=item %w

The day of the week with Sunday as 0 (zero) and Monday as 1 (one).

=item %W

The zero-filled right-aligned week number of the year, Monday as the
first day of the week, from '00' to '53'.

(Currently taken care by the operating system strftime().)

=item %x

C<%m/%d/%y>.

(Should be avoided: use $t->date instead.)

=item %y

The zero-filled right-aligned last two numbers of the year, e.g. 99
for 1999 and 01 for 2001.

(Should be avoided: this is the Y2K bug alive and well.)

=item %Y

The year, e.g. 1999 or 2001.

=item %Z

The timezone name, for example "GMT" or "EET".

(Taken care by the operating system strftime().)

=back

The format C<Z> and any of the C<O*> and C<E*> formats are handled by
the operating system, not by Time::Piece, because those formats are
usually rather unportable and non-standard.  (For example 'MST' can
mean almost anything: 'Mountain Standard Time' or 'Moscow Standard Time'.)

=head2 strptime function

You can export the strptime() function and use it to parse date and
time strings back to numbers.  For example the following will return
the hours, minutes, and seconds as $parse{H}, $parse{M}, and $parse{S}.

    use Time::Piece 'strptime';
    my %parse = strptime('%H:%M:S', '12:34:56');

For 'compound' formats like for example 'T' strptime() will return
the 'components'.

strptime() does not perform overly strict checks on the dates and
times, it will be perfectly happy with the 31st day of February,
for example.  Stricter validation should be performed by other means.

=head2 Global Overriding

Finally, it's possible to override localtime and gmtime everywhere, by
including the ':override' tag in the import list:

    use Time::Piece ':override';

=head1 SEE ALSO

The excellent Calendar FAQ at L<http://www.tondering.dk/claus/calendar.html>

L<strftime(3)>, L<strftime(3)>

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

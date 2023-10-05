package Time::tm 1.01;
use v5.38;

use Class::Struct qw(struct);
struct('Time::tm' => [
     map { $_ => '$' } qw{ sec min hour mday mon year wday yday isdst }
]);

__END__

=head1 NAME

Time::tm - internal object used by Time::gmtime and Time::localtime

=head1 SYNOPSIS

Don't use this module directly.

=head1 DESCRIPTION

This module is used internally as a base class by Time::localtime And
Time::gmtime functions.  It creates a Time::tm struct object which is
addressable just like's C's tm structure from F<time.h>; namely with sec,
min, hour, mday, mon, year, wday, yday, and isdst.

This class is an internal interface only. 

=head1 AUTHOR

Tom Christiansen

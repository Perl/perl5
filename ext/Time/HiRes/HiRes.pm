package Time::HiRes;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK @EXPORT_FAIL);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw( );
@EXPORT_OK = qw (usleep sleep ualarm alarm gettimeofday time tv_interval);

$VERSION = do{my@r=q$Revision: 1.20 $=~/\d+/g;sprintf '%02d.'.'%02d'x$#r,@r};

bootstrap Time::HiRes $VERSION;

@EXPORT_FAIL = grep { ! defined &$_ } @EXPORT_OK;

# Preloaded methods go here.

sub tv_interval {
    # probably could have been done in C
    my ($a, $b) = @_;
    $b = [gettimeofday()] unless defined($b);
    (${$b}[0] - ${$a}[0]) + ((${$b}[1] - ${$a}[1]) / 1_000_000);
}

# I'm only supplying this because the version of it in 5.003's Export.pm
# is buggy (it doesn't shift off the class name).

sub export_fail {
    my $self = shift;
    @_;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Time::HiRes - High resolution ualarm, usleep, and gettimeofday

=head1 SYNOPSIS

  use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );

  usleep ($microseconds);

  ualarm ($microseconds);
  ualarm ($microseconds, $interval_microseconds);

  $t0 = [gettimeofday];
  ($seconds, $microseconds) = gettimeofday;

  $elapsed = tv_interval ( $t0, [$seconds, $microseconds]);
  $elapsed = tv_interval ( $t0, [gettimeofday]);
  $elapsed = tv_interval ( $t0 );

  use Time::HiRes qw ( time alarm sleep );
  $now_fractions = time;
  sleep ($floating_seconds);
  alarm ($floating_seconds);
  alarm ($floating_seconds, $floating_interval);

=head1 DESCRIPTION

The C<Time::HiRes> module implements a Perl interface to the usleep, ualarm,
and gettimeofday system calls. See the EXAMPLES section below and the test
scripts for usage; see your system documentation for the description of
the underlying gettimeofday, usleep, and ualarm calls.

If your system lacks gettimeofday(2) you don't get gettimeofday() or the
one-arg form of tv_interval().  If you don't have usleep(3) or select(2)
you don't get usleep() or sleep().  If your system don't have ualarm(3)
or setitimer(2) you don't
get ualarm() or alarm().  If you try to import an unimplemented function
in the C<use> statement it will fail at compile time.

The following functions can be imported from this module.  No
functions are exported by default.

=over 4

=item gettimeofday ()

In array context it returns a 2 element array with the seconds and
microseconds since the epoch.  In scalar context it returns floating
seconds like Time::HiRes::time() (see below).

=item usleep ( $useconds )

Issues a usleep for the number of microseconds specified. See also 
Time::HiRes::sleep() below.

=item ualarm ( $useconds [, $interval_useconds ] )

Issues a ualarm call; interval_useconds is optional and will be 0 if 
unspecified, resulting in alarm-like behaviour.

=item tv_interval ( $ref_to_gettimeofday [, $ref_to_later_gettimeofday] )

Returns the floating seconds between the two times, which should have been 
returned by gettimeofday(). If the second argument is omitted, then the
current time is used.

=item time ()

Returns a floating seconds since the epoch. This function can be imported,
resulting in a nice drop-in replacement for the C<time> provided with perl,
see the EXAMPLES below.

=item sleep ( $floating_seconds )

Converts $floating_seconds to microseconds and issues a usleep for the 
result.  This function can be imported, resulting in a nice drop-in 
replacement for the C<sleep> provided with perl, see the EXAMPLES below.

=item alarm ( $floating_seconds [, $interval_floating_seconds ] )

Converts $floating_seconds and $interval_floating_seconds and issues
a ualarm for the results.  The $interval_floating_seconds argument
is optional and will be 0 if unspecified, resulting in alarm-like
behaviour.  This function can be imported, resulting in a nice drop-in
replacement for the C<alarm> provided with perl, see the EXAMPLES below.

=back

=head1 EXAMPLES

  use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);

  $microseconds = 750_000;
  usleep $microseconds;

  # signal alarm in 2.5s & every .1s thereafter
  ualarm 2_500_000, 100_000;	

  # get seconds and microseconds since the epoch
  ($s, $usec) = gettimeofday;

  # measure elapsed time 
  # (could also do by subtracting 2 gettimeofday return values)
  $t0 = [gettimeofday];
  # do bunch of stuff here
  $t1 = [gettimeofday];
  # do more stuff here
  $t0_t1 = tv_interval $t0, $t1;
  
  $elapsed = tv_interval ($t0, [gettimeofday]);
  $elapsed = tv_interval ($t0);	# equivalent code

  #
  # replacements for time, alarm and sleep that know about
  # floating seconds
  #
  use Time::HiRes;
  $now_fractions = Time::HiRes::time;
  Time::HiRes::sleep (2.5);
  Time::HiRes::alarm (10.6666666);
 
  use Time::HiRes qw ( time alarm sleep );
  $now_fractions = time;
  sleep (2.5);
  alarm (10.6666666);

=head1 C API

In addition to the perl API described above, a C API is available for
extension writers.  The following C functions are available in the
modglobal hash:

  name             C prototype
  ---------------  ----------------------
  Time::NVtime     double (*)()
  Time::U2time     void (*)(UV ret[2])

Both functions return equivalent information (like C<gettimeofday>)
but with different representations.  The names C<NVtime> and C<U2time>
were selected mainly because they are operating system independent.
(C<gettimeofday> is Un*x-centric.)

Here is an example of using NVtime from C:

  double (*myNVtime)();
  SV **svp = hv_fetch(PL_modglobal, "Time::NVtime", 12, 0);
  if (!svp)         croak("Time::HiRes is required");
  if (!SvIOK(*svp)) croak("Time::NVtime isn't a function pointer");
  myNVtime = (double(*)()) SvIV(*svp);
  printf("The current time is: %f\n", (*myNVtime)());

=head1 AUTHORS

D. Wegscheid <wegscd@whirlpool.com>
R. Schertler <roderick@argon.org>
J. Hietaniemi <jhi@iki.fi>
G. Aas <gisle@aas.no>

=head1 REVISION

$Id: HiRes.pm,v 1.20 1999/03/16 02:26:13 wegscd Exp $

$Log: HiRes.pm,v $
Revision 1.20  1999/03/16 02:26:13  wegscd
Add documentation for NVTime and U2Time.

Revision 1.19  1998/09/30 02:34:42  wegscd
No changes, bump version.

Revision 1.18  1998/07/07 02:41:35  wegscd
No changes, bump version.

Revision 1.17  1998/07/02 01:45:13  wegscd
Bump version to 1.17

Revision 1.16  1997/11/13 02:06:36  wegscd
version bump to accomodate HiRes.xs fix.

Revision 1.15  1997/11/11 02:17:59  wegscd
POD editing, courtesy of Gisle Aas.

Revision 1.14  1997/11/06 03:14:35  wegscd
Update version # for Makefile.PL and HiRes.xs changes.

Revision 1.13  1997/11/05 05:36:25  wegscd
change version # for Makefile.pl and HiRes.xs changes.

Revision 1.12  1997/10/13 20:55:33  wegscd
Force a new version for Makefile.PL changes.

Revision 1.11  1997/09/05 19:59:33  wegscd
New version to bump version for README and Makefile.PL fixes.
Fix bad RCS log.

Revision 1.10  1997/05/23 01:11:38  wegscd
Conditional compilation; EXPORT_FAIL fixes.

Revision 1.2  1996/12/30 13:28:40  wegscd
Update documentation for what to do when missing ualarm() and friends.

Revision 1.1  1996/10/17 20:53:31  wegscd
Fix =head1 being next to __END__ so pod2man works

Revision 1.0  1996/09/03 18:25:15  wegscd
Initial revision

=head1 COPYRIGHT

Copyright (c) 1996-1997 Douglas E. Wegscheid.
All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require Config; import Config;
    if ($^O ne 'VMS' and $Config{'extensions'} !~ /\bPOSIX\b/) {
	print "1..0\n";
	exit 0;
    }
}

use POSIX qw(fcntl_h signal_h limits_h _exit getcwd open read strftime write
	     errno);
use strict subs;

$| = 1;
print "1..29\n";

$Is_W32 = $^O eq 'MSWin32';
$Is_NetWare = $^O eq 'NetWare';
$Is_Dos = $^O eq 'dos';
$Is_MPE = $^O eq 'mpeix';

$testfd = open("TEST", O_RDONLY, 0) and print "ok 1\n";
read($testfd, $buffer, 9) if $testfd > 2;
print $buffer eq "#!./perl\n" ? "ok 2\n" : "not ok 2\n";

write(1,"ok 3\nnot ok 3\n", 5);

if ($Is_Dos) {
    for (4..5) {
        print "ok $_ # skipped, no pipe() support on dos\n";
    }
} else {
@fds = POSIX::pipe();
print $fds[0] > $testfd ? "ok 4\n" : "not ok 4\n";
CORE::open($reader = \*READER, "<&=".$fds[0]);
CORE::open($writer = \*WRITER, ">&=".$fds[1]);
print $writer "ok 5\n";
close $writer;
print <$reader>;
close $reader;
}

if ($Is_W32 || $Is_Dos) {
    for (6..11) {
	print "ok $_ # skipped, no sigaction support on win32/dos\n";
    }
}
else {
$sigset = new POSIX::SigSet 1,3;
delset $sigset 1;
if (!ismember $sigset 1) { print "ok 6\n" }
if (ismember $sigset 3) { print "ok 7\n" }
$mask = new POSIX::SigSet &SIGINT;
$action = new POSIX::SigAction 'main::SigHUP', $mask, 0;
sigaction(&SIGHUP, $action);
$SIG{'INT'} = 'SigINT';
kill 'HUP', $$;
sleep 1;
print "ok 11\n";

sub SigHUP {
    print "ok 8\n";
    kill 'INT', $$;
    sleep 2;
    print "ok 9\n";
}

sub SigINT {
    print "ok 10\n";
}
}

if ($Is_MPE) {
    print "ok 12 # skipped, _POSIX_OPEN_MAX is inaccurate on MPE\n"
} else {
    print &_POSIX_OPEN_MAX > $fds[1] ? "ok 12\n" : "not ok 12\n"
}

print getcwd() =~ m#[/\\]t$# ? "ok 13\n" : "not ok 13\n";

# Check string conversion functions.

if ($Config{d_strtod}) {
    $lc = &POSIX::setlocale(&POSIX::LC_NUMERIC, 'C') if $Config{d_setlocale};
    ($n, $x) = &POSIX::strtod('3.14159_OR_SO');
# we're just checking that strtod works, not how accurate it is
    print ((abs("3.14159" - $n) < 1e-6) && ($x == 6) ?
          "ok 14\n" : "not ok 14\n");
    &POSIX::setlocale(&POSIX::LC_NUMERIC, $lc) if $Config{d_setlocale};
} else { print "# strtod not present\n", "ok 14\n"; }

if ($Config{d_strtol}) {
    ($n, $x) = &POSIX::strtol('21_PENGUINS');
    print (($n == 21) && ($x == 9) ? "ok 15\n" : "not ok 15\n");
} else { print "# strtol not present\n", "ok 15\n"; }

if ($Config{d_strtoul}) {
    ($n, $x) = &POSIX::strtoul('88_TEARS');
    print (($n == 88) && ($x == 6) ? "ok 16\n" : "not ok 16\n");
} else { print "# strtoul not present\n", "ok 16\n"; }

# Pick up whether we're really able to dynamically load everything.
print &POSIX::acos(1.0) == 0.0 ? "ok 17\n" : "not ok 17\n";

# This can coredump if struct tm has a timezone field and we
# didn't detect it.  If this fails, try adding
# -DSTRUCT_TM_HASZONE to your cflags when compiling ext/POSIX/POSIX.c.
# See ext/POSIX/hints/sunos_4.pl and ext/POSIX/hints/linux.pl 
print POSIX::strftime("ok 18 # %H:%M, on %D\n", localtime());

# If that worked, validate the mini_mktime() routine's normalisation of
# input fields to strftime().
sub try_strftime {
    my $num = shift;
    my $expect = shift;
    my $got = POSIX::strftime("%a %b %d %H:%M:%S %Y %j", @_);
    if ($got eq $expect) {
	print "ok $num\n";
    }
    else {
	print "# expected: $expect\n# got: $got\nnot ok $num\n";
    }
}

$lc = &POSIX::setlocale(&POSIX::LC_TIME, 'C') if $Config{d_setlocale};
try_strftime(19, "Wed Feb 28 00:00:00 1996 059", 0,0,0, 28,1,96);
try_strftime(20, "Thu Feb 29 00:00:60 1996 060", 60,0,-24, 30,1,96);
try_strftime(21, "Fri Mar 01 00:00:00 1996 061", 0,0,-24, 31,1,96);
try_strftime(22, "Sun Feb 28 00:00:00 1999 059", 0,0,0, 28,1,99);
try_strftime(23, "Mon Mar 01 00:00:00 1999 060", 0,0,24, 28,1,99);
try_strftime(24, "Mon Feb 28 00:00:00 2000 059", 0,0,0, 28,1,100);
try_strftime(25, "Tue Feb 29 00:00:00 2000 060", 0,0,0, 0,2,100);
try_strftime(26, "Wed Mar 01 00:00:00 2000 061", 0,0,0, 1,2,100);
try_strftime(27, "Fri Mar 31 00:00:00 2000 091", 0,0,0, 31,2,100);
&POSIX::setlocale(&POSIX::LC_TIME, $lc) if $Config{d_setlocale};

{
    for my $test (0, 1) {
	$! = 0;
	# POSIX::errno is autoloaded. 
	# Autoloading requires many system calls.
	# errno() looks at $! to generate its result.
	# Autoloading should not munge the value.
	my $foo  = $!;
	my $errno = POSIX::errno();
	print "not " unless $errno == $foo;
	print "ok ", 28 + $test, "\n";
    }
}

$| = 0;
# The following line assumes buffered output, which may be not true with EMX:
print '@#!*$@(!@#$' unless ($^O eq 'os2' || $^O eq 'uwin' || $^O eq 'os390' ||
			    (defined $ENV{PERLIO} &&
			     $ENV{PERLIO} eq 'unix' &&
			     $Config::Config{useperlio}));
_exit(0);

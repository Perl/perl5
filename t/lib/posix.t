#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bPOSIX\b/) {
	print STDERR "1..0\n";
	exit 0;
    }
}
use FileHandle;
use POSIX qw(fcntl_h signal_h limits_h _exit getcwd open read write);
use strict subs;

$mystdout = new_from_fd FileHandle 1,"w";
autoflush STDOUT;
autoflush $mystdout;
print "1..16\n";

print $mystdout "ok ",fileno($mystdout),"\n";
write(1,"ok 2\nnot ok 2\n", 5);

$testfd = open("TEST", O_RDONLY, 0) and print "ok 3\n";
read($testfd, $buffer, 9) if $testfd > 2;
print $buffer eq "#!./perl\n" ? "ok 4\n" : "not ok 4\n";

@fds = POSIX::pipe();
print $fds[0] > $testfd ? "ok 5\n" : "not ok 5\n";
$writer = FileHandle->new_from_fd($fds[1], "w");
$reader = FileHandle->new_from_fd($fds[0], "r");
print $writer "ok 6\n";
close $writer;
print <$reader>;
close $reader;

$sigset = new POSIX::SigSet 1,3;
delset $sigset 1;
if (!ismember $sigset 1) { print "ok 7\n" }
if (ismember $sigset 3) { print "ok 8\n" }
$mask = new POSIX::SigSet &SIGINT;
$action = new POSIX::SigAction 'main::SigHUP', $mask, 0;
sigaction(&SIGHUP, $action);
$SIG{'INT'} = 'SigINT';
kill 'HUP', $$;
sleep 1;
print "ok 12\n";

sub SigHUP {
    print "ok 9\n";
    kill 'INT', $$;
    sleep 2;
    print "ok 10\n";
}

sub SigINT {
    print "ok 11\n";
}

print &_POSIX_OPEN_MAX > $fds[1] ? "ok 13\n" : "not ok 13\n";

print getcwd() =~ m#/t$# ? "ok 14\n" : "not ok 14\n";

# Pick up whether we're really able to dynamically load everything.
print &POSIX::acos(1.0) == 0.0 ? "ok 15\n" : "not ok 15\n";

ungetc STDIN 65;
CORE::read(STDIN, $buf,1);
print $buf eq 'A' ? "ok 16\n" : "not ok 16\n";

flush STDOUT;
autoflush STDOUT 0;
print '@#!*$@(!@#$';
_exit(0);

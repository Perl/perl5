#
# syslog.pl
#
# tom christiansen <tchrist@convex.com>
# modified to use sockets by Larry Wall <lwall@jpl-devvax.jpl.nasa.gov>
# NOTE: openlog now takes three arguments, just like openlog(3)
#
# call syslog() with a string priority and a list of printf() args
# like syslog(3)
#
#  usage: do 'syslog.pl' || die "syslog.pl: $@";
#
#  then (put these all in a script to test function)
#		
#
#	do openlog($program,'cons,pid','user');
#	do syslog('info','this is another test');
#	do syslog('warn','this is a better test: %d', time);
#	do closelog();
#	
#	do syslog('debug','this is the last test');
#	do openlog("$program $$",'ndelay','user');
#	do syslog('notice','fooprogram: this is really done');
#
#	$! = 55;
#	do syslog('info','problem was %m'); # %m == $! in syslog(3)

package syslog;

$host = 'localhost' unless $host;	# set $syslog'host to change

do '/usr/local/lib/perl/syslog.h'
	|| die "syslog: Can't do syslog.h: ",($@||$!),"\n";

sub main'openlog {
    ($ident, $logopt, $facility) = @_;  # package vars
    $lo_pid = $logopt =~ /\bpid\b/;
    $lo_ndelay = $logopt =~ /\bndelay\b/;
    $lo_cons = $logopt =~ /\bncons\b/;
    $lo_nowait = $logopt =~ /\bnowait\b/;
    &connect if $lo_ndelay;
} 

sub main'closelog {
    $facility = $ident = '';
    &disconnect;
} 
 
sub main'syslog {
    local($priority) = shift;
    local($mask) = shift;
    local($message, $whoami);

    &connect unless $connected;

    $whoami = $ident;

    die "syslog: expected both priority and mask" unless $mask && $priority;

    $facility = "user" unless $facility;

    if (!$ident && $mask =~ /^(\S.*):\s?(.*)/) {
	$whoami = $1;
	$mask = $2;
    } 
    $whoami .= " [$$]" if $lo_pid;

    $mask =~ s/%m/$!/g;
    $mask .= "\n" unless $mask =~ /\n$/;
    $message = sprintf ($mask, @_);

    $whoami = sprintf ("%s %d",$ENV{'USER'}||$ENV{'LOGNAME'},$$) unless $whoami;

    $sum = &xlate($priority) + &xlate($facility);
    unless (send(SYSLOG,"<$sum>$whoami: $message",0)) {
	if ($lo_cons) {
	    if ($pid = fork) {
		unless ($lo_nowait) {
		    do {$died = wait;} until $died == $pid || $died < 0;
		}
	    }
	    else {
		open(CONS,">/dev/console");
		print CONS "$<facility.$priority>$whoami: $message\n";
		exit if defined $pid;		# if fork failed, we're parent
		close CONS;
	    }
	}
    }
}

sub xlate {
    local($name) = @_;
    $name =~ y/a-z/A-Z/;
    $name = "LOG_$name" unless $name =~ /^LOG_/;
    $name = "syslog'$name";
    &$name;
}

sub connect {
    $pat = 'S n C4 x8';

    $af_unix = 1;
    $af_inet = 2;

    $stream = 1;
    $datagram = 2;

    ($name,$aliases,$proto) = getprotobyname('udp');
    $udp = $proto;

    ($name,$aliase,$port,$proto) = getservbyname('syslog','udp');
    $syslog = $port;

    if (chop($myname = `hostname`)) {
	($name,$aliases,$addrtype,$length,@addrs) = gethostbyname($myname);
	die "Can't lookup $myname\n" unless $name;
	@bytes = unpack("C4",$addrs[0]);
    }
    else {
	@bytes = (0,0,0,0);
    }
    $this = pack($pat, $af_inet, 0, @bytes);

    if ($host =~ /^\d+\./) {
	@bytes = split(/\./,$host);
    }
    else {
	($name,$aliases,$addrtype,$length,@addrs) = gethostbyname($host);
	die "Can't lookup $host\n" unless $name;
	@bytes = unpack("C4",$addrs[0]);
    }
    $that = pack($pat,$af_inet,$syslog,@bytes);

    socket(SYSLOG,$af_inet,$datagram,$udp) || die "socket: $!\n";
    bind(SYSLOG,$this) || die "bind: $!\n";
    connect(SYSLOG,$that) || die "connect: $!\n";

    local($old) = select(SYSLOG); $| = 1; select($old);
    $connected = 1;
}

sub disconnect {
    close SYSLOG;
    $connected = 0;
}

1;

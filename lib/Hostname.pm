# by David Sundstrom   sunds@asictest.sc.ti.com
#    Texas Instruments

package Hostname;

require Exporter;
@ISA = (Exporter);
@EXPORT = (hostname);

#
# Try every conceivable way to get hostname.
# 

sub hostname {
    # method 1 - we already know it
    return $host if defined $host;

    # method 2 - syscall is preferred since it avoids tainting problems
    eval {
	require "syscall.ph";
	$host = "\0" x 65; ## preload scalar
	syscall(&SYS_gethostname, $host, 65) == 0;
    }

    # method 3 - sysV uname command
    || eval {
	$host = `uname -n 2>/dev/null`; ## sysVish
    }

    # method 4 - trusty old hostname command
    || eval {
	$host = `hostname 2>/dev/null`; # bsdish
    }

    # method 5 - Apollo pre-SR10
    || eval {
	($host,$a,$b,$c,$d)=split(/[:\. ]/,`/com/host`,6);
    }

    # bummer
    || die "Cannot get host name of local machine\n";  

    # remove garbage 
    $host =~ tr/\0\r\n//d;
    $host;
}

1;

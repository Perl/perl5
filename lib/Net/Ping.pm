package Net::Ping;

# Authors: karrer@bernina.ethz.ch (Andreas Karrer)
#          pmarquess@bfsec.bt.co.uk (Paul Marquess)

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(ping pingecho);

use Socket;
use Carp ;

$tcp_proto = (getprotobyname('tcp'))[2];
$echo_port = (getservbyname('echo', 'tcp'))[2];

sub ping {
    croak "ping not implemented yet. Use pingecho()";
}


sub pingecho {

    croak "usage: pingecho host [timeout]" 
        unless @_ == 1 || @_ == 2 ;

    local ($host, $timeout) = @_;
    local (*PINGSOCK);
    local ($saddr, $ip);
    local ($ret) ;

    # check if $host is alive by connecting to its echo port, within $timeout
    # (default 5) seconds. returns 1 if OK, 0 if no answer, 0 if host not found

    $timeout = 5 unless $timeout;

    if ($host =~ /^\s*((\d+\.){3}\d+)\s*$/)
      { $ip = pack ('C4', split (/\./, $1)) }
    else
      { $ip = (gethostbyname($host))[4] }

    return 0 unless $ip;		# "no such host"

    $saddr = pack('S n a4 x8', AF_INET, $echo_port, $ip);
    $SIG{'ALRM'} = sub { die } ;
    alarm($timeout);

    $ret = eval <<'EOM' ;

        return 0 
            unless socket(PINGSOCK, PF_INET, SOCK_STREAM, $tcp_proto) ;

        return 0 
            unless connect(PINGSOCK, $saddr) ;

        return 1 ;
EOM

    alarm(0);
    close(PINGSOCK);
    $ret == 1 ? 1 : 0 ;
}   

1;

package Net::Ping;

# Authors: karrer@bernina.ethz.ch (Andreas Karrer)
#          pmarquess@bfsec.bt.co.uk (Paul Marquess)

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(ping pingecho);
$VERSION = 1.00;

use Socket 'PF_INET', 'AF_INET', 'SOCK_STREAM';
require Carp ;

use strict ;

$Net::Ping::tcp_proto = (getprotobyname('tcp'))[2];
$Net::Ping::echo_port = (getservbyname('echo', 'tcp'))[2];

# keep -w happy
$Net::Ping::tcp_proto = $Net::Ping::tcp_proto ;
$Net::Ping::echo_port = $Net::Ping::echo_port ;

sub ping {
    Carp::croak "ping not implemented yet. Use pingecho()";
}


sub pingecho {

    Carp::croak "usage: pingecho host [timeout]" 
        unless @_ == 1 || @_ == 2 ;

    my ($host, $timeout) = @_;
    my ($saddr, $ip);
    my ($ret) ;
    local (*PINGSOCK);

    # check if $host is alive by connecting to its echo port, within $timeout
    # (default 5) seconds. returns 1 if OK, 0 if no answer, 0 if host not found

    $timeout = 5 unless $timeout;

    if ($host =~ /^\s*((\d+\.){3}\d+)\s*$/)
      { $ip = pack ('C4', split (/\./, $1)) }
    else
      { $ip = (gethostbyname($host))[4] }

    return 0 unless $ip;		# "no such host"

    $saddr = pack('S n a4 x8', AF_INET, $Net::Ping::echo_port, $ip);
    $SIG{'ALRM'} = sub { die } ;
    alarm($timeout);
    
    $ret = 0;
    eval <<'EOM' ;
    return unless socket(PINGSOCK, PF_INET, SOCK_STREAM, $Net::Ping::tcp_proto) ;
    return unless connect(PINGSOCK, $saddr) ;
    $ret=1 ;
EOM
    alarm(0);
    close(PINGSOCK);
    $ret;
}   

1;
__END__

=cut

=head1 NAME

Net::Ping, pingecho - check a host for upness

=head1 SYNOPSIS

    use Net::Ping;
    print "'jimmy' is alive and kicking\n" if pingecho('jimmy', 10) ;

=head1 DESCRIPTION

This module contains routines to test for the reachability of remote hosts.
Currently the only routine implemented is pingecho(). 

pingecho() uses a TCP echo (I<not> an ICMP one) to determine if the
remote host is reachable. This is usually adequate to tell that a remote
host is available to rsh(1), ftp(1), or telnet(1) onto.

=head2 Parameters

=over 5

=item hostname

The remote host to check, specified either as a hostname or as an IP address.

=item timeout

The timeout in seconds. If not specified it will default to 5 seconds.

=back

=head1 WARNING

pingecho() uses alarm to implement the timeout, so don't set another alarm
while you are using it.



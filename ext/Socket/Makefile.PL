use ExtUtils::MakeMaker;
use ExtUtils::Constant 0.07 'WriteConstants';
use Config;
WriteMakefile(
    NAME	 => 'Socket',
    VERSION_FROM => 'Socket.pm',
   ($Config{libs} =~ /(-lsocks\S*)/ ? (LIBS => [ "$1" ] ) : ()),
    MAN3PODS  	 => {}, 	# Pods will be built by installman.
    XSPROTOARG   => '-noprototypes', 		# XXX remove later?
    realclean => {FILES=> 'constants.c constants.xs'},
);
my @names = (qw(AF_802 AF_APPLETALK AF_CCITT AF_CHAOS AF_DATAKIT AF_DECnet
	       AF_DLI AF_ECMA AF_GOSIP AF_HYLINK AF_IMPLINK AF_INET AF_LAT
	       AF_MAX AF_NBS AF_NIT AF_NS AF_OSI AF_OSINET AF_PUP AF_SNA
	       AF_UNIX AF_UNSPEC AF_X25 IOV_MAX IPPROTO_TCP MSG_BCAST
	       MSG_CTLFLAGS MSG_CTLIGNORE MSG_DONTWAIT MSG_EOF MSG_EOR
	       MSG_ERRQUEUE MSG_FIN MSG_MAXIOVLEN MSG_MCAST MSG_NOSIGNAL
	       MSG_RST MSG_SYN MSG_TRUNC MSG_WAITALL PF_802 PF_APPLETALK
	       PF_CCITT PF_CHAOS PF_DATAKIT PF_DECnet PF_DLI PF_ECMA PF_GOSIP
	       PF_HYLINK PF_IMPLINK PF_INET PF_LAT PF_MAX PF_NBS PF_NIT PF_NS
	       PF_OSI PF_OSINET PF_PUP PF_SNA PF_UNIX PF_UNSPEC PF_X25
	       SCM_CONNECT SCM_CREDENTIALS SCM_CREDS SCM_TIMESTAMP SOCK_DGRAM
	       SOCK_RAW SOCK_RDM SOCK_SEQPACKET SOCK_STREAM SOL_SOCKET
	       SOMAXCONN SO_ACCEPTCONN SO_BROADCAST SO_DEBUG SO_DONTLINGER
	       SO_DONTROUTE SO_ERROR SO_KEEPALIVE SO_LINGER SO_OOBINLINE
	       SO_RCVBUF SO_RCVLOWAT SO_RCVTIMEO SO_REUSEADDR SO_REUSEPORT
	       SO_SNDBUF SO_SNDLOWAT SO_SNDTIMEO SO_TYPE SO_USELOOPBACK
	       TCP_KEEPALIVE TCP_MAXRT TCP_MAXSEG TCP_NODELAY TCP_STDURG
	       UIO_MAXIOV MSG_URG),
            {name=>"SHUT_RD", type=>"IV", default=>["IV", "0"]},
            {name=>"SHUT_WR", type=>"IV", default=>["IV", "1"]},
            {name=>"SHUT_RDWR", type=>"IV", default=>["IV", "2"]},
);

push @names,
  {name=>$_, type=>"IV",
   macro=>["#if defined($_) || defined(HAS_$_) /* might be an enum */\n",
           "#endif\n"]}
foreach qw (MSG_CTRUNC MSG_DONTROUTE MSG_OOB MSG_PEEK MSG_PROXY SCM_RIGHTS);

push @names, 
{name => $_, type => "SV",
 pre=>"struct in_addr ip_address; ip_address.s_addr = htonl($_);",
 value => "sv_2mortal(newSVpvn((char *)&ip_address,sizeof ip_address ))",}
         foreach qw(INADDR_ANY INADDR_LOOPBACK INADDR_NONE INADDR_BROADCAST);

WriteConstants(
    NAME => 'Socket',
    NAMES => \@names,
);

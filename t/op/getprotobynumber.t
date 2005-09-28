#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

my (%default_test, %protos, %test);
    
%default_test = map { $_ => 1 } sort keys %protos;
      
if ($^O eq 'MacOS') {
    %test = %default_test;
} elsif ($^O eq 'MSWin32') {
    %test = map { $_ => 1 } (0,1,3,6,8,12,17,20,22,27,66);
    $protos{0}[1] = 'IP';
} elsif ($^O eq 'NetWare') {
    %test = %default_test;
} elsif ($^O eq 'VMS') {
    %test = %default_test;
} else {
    %test = %default_test;
}

plan tests => scalar (keys %test) * 2;

for my $number (sort {$a <=> $b} keys %protos) {
    next unless exists $test{$number};
    my ($name, $alias) = getprotobynumber($number);
    is($name, $protos{$number}[0], "getprotobynumber($number) returned name  ($name)");
    is($alias, $protos{$number}[1], "getprotobynumber($number) returned alias ($alias)");
}
    
BEGIN {
    %protos = (
        0 => ['ip', 'IP HOPOPT'],
        1 => [qw(icmp ICMP)],
        2 => [qw(igmp IGMP)],
        3 => [qw(ggp GGP)],
        4 => [qw(ipencap IP-ENCAP)],
        5 => [qw(st ST)],
        6 => [qw(tcp TCP)],
        7 => ['ucl', 'UCL CBT'],
        8 => [qw(egp EGP)],
        9 => [qw(igp IGP)],
       10 => [qw(bbn-rcc-mon BBN-RCC-MON)],
       11 => [qw(nvp-ii NVP-II)],
       12 => [qw(pup PUP)], 
       13 => [qw(argus ARGUS)], 
       14 => [qw(emcon EMCON)],
       15 => [qw(xnet XNET)], 
       16 => [qw(chaos CHAOS)], 
       17 => [qw(udp UDP)],
       18 => [qw(mux MUX)],
       19 => [qw(dcn-meas DCN-MEAS)],
       20 => [qw(hmp HMP)],
       21 => [qw(prm PRM)],
       22 => [qw(xns-idp XNS-IDP)],
       23 => [qw(trunk-1 TRUNK-1)],
       24 => [qw(trunk-2 TRUNK-2)],
       25 => [qw(leaf-1 LEAF-1)],
       26 => [qw(leaf-2 LEAF-2)],
       27 => [qw(rdp RDP)],
       28 => [qw(irtp IRTP)],
       29 => [qw(iso-tp4 ISO-TP4)],
       30 => [qw(netblt NETBLT)],
       31 => [qw(mfe-nsp MFE-NSP)],
       32 => [qw(merit-inp MERIT-INP)],
       33 => [qw(sep SEP)],
       34 => [qw(3pc 3PC)],
       35 => [qw(idpr IDPR)],
       36 => [qw(xtp XTP)],
       37 => [qw(ddp DDP)],
       38 => [qw(idpr-cmtp IDPR-CMTP)],
       39 => [qw(tp++ TP++)],
       40 => [qw(il IL)],
       41 => [qw(ipv6 IPv6)],
       42 => [qw(sdrp SDRP)],
       43 => [qw(sip-sr SIP-SR)],
       44 => [qw(sip-frag SIP-FRAG)],
       45 => [qw(idrp IDRP)],
       46 => [qw(rsvp RSVP)],
       47 => [qw(gre GRE)],
       48 => [qw(mhrp MHRP)],
       49 => [qw(bna BNA)],
       50 => ['esp', 'IPSEC-ESP ESP'],
       51 => ['ah', 'IPSEC-AH AH'],
       52 => [qw(i-nlsp I-NLSP)],
       53 => [qw(swipe SWIPE)],
       54 => ['nhrp', 'NHRP NARP'],
       55 => ['mobileip', 'MOBILEIP MOBILE'],
       57 => [qw(skip SKIP)],
       58 => ['ipv6-icmp', 'IPv6-ICMP icmp6'],
       59 => [qw(ipv6-nonxt IPv6-NoNxt)],
       60 => [qw(ipv6-opts IPv6-Opts)],
       61 => [qw(any any)],
       62 => [qw(cftp CFTP)],
       63 => [qw(any any)],
       64 => [qw(sat-expak SAT-EXPAK)],
       65 => [qw(kryptolan KRYPTOLAN)],
       66 => [qw(rvd RVD)],
       67 => [qw(ippc IPPC)],
       68 => [qw(any any)],
       69 => [qw(sat-mon SAT-MON)],
       70 => [qw(visa VISA)],
       71 => [qw(ipcv IPCV)],
       72 => [qw(cpnx CPNX)],
       73 => [qw(cphb CPHB)],
       74 => [qw(wsn WSN)],
       75 => [qw(pvp PVP)],
       76 => [qw(br-sat-mon BR-SAT-MON)],
       77 => [qw(sun-nd SUN-ND)],
       78 => [qw(wb-mon WB-MON)],
       79 => [qw(wb-expak WB-EXPAK)],
       80 => [qw(iso-ip ISO-IP)],
       81 => [qw(vmtp VMTP)],
       82 => [qw(secure-vmtp SECURE-VMTP)],
       83 => [qw(vines VINES)],
       84 => [qw(ttp TTP)],
       85 => [qw(nsfnet-igp NSFNET-IGP)],
       86 => [qw(dgp DGP)],
       87 => [qw(tcf TCF)],
       88 => ['igrp', 'IGRP EIGRP'],
       89 => [qw(ospf OSPFIGP)],
       90 => [qw(sprite-rpc Sprite-RPC)],
       91 => [qw(larp LARP)],
       92 => [qw(mtp MTP)],
       93 => [qw(ax.25 AX.25)],
       94 => [qw(ipip IPIP)],
       95 => [qw(micp MICP)],
       96 => [qw(scc-sp SCC-SP)],
       97 => [qw(etherip ETHERIP)],
       98 => [qw(encap ENCAP)],
       99 => [qw(any any)],
      100 => [qw(gmtp GMTP)],
      101 => [qw(ifmp IFMP)],
      102 => [qw(pnni PNNI)],
      103 => [qw(pim PIM)],
      104 => [qw(aris ARIS)],
      105 => [qw(scps SCPS)],
      106 => [qw(qnx QNX)],
      107 => [qw(a/n A/N)],
      108 => [qw(ipcomp IPComp)],
      109 => [qw(snp SNP)],
      110 => [qw(compaq-peer Compaq-Peer)],
      111 => [qw(ipx-in-ip IPX-in-IP)],
      112 => ['carp', 'CARP vrrp'],
      113 => [qw(pgm PGM)],
      115 => [qw(l2tp L2TP)],
      116 => [qw(ddx DDX)],
      117 => [qw(iatp IATP)],
      118 => [qw(stp STP)],
      119 => [qw(srp SRP)],
      120 => [qw(uti UTI)],
      121 => [qw(smp SMP)],
      122 => [qw(sm SM)],
      123 => [qw(ptp PTP)],
      124 => [qw(isis ISIS)],
      125 => [qw(fire FIRE)],
      126 => [qw(crtp CRTP)],
      127 => [qw(crudp CRUDP)],
      128 => [qw(sscopmce SSCOPMCE)],
      129 => [qw(iplt IPLT)],
      130 => [qw(sps SPS)],
      131 => [qw(pipe PIPE)],
      132 => [qw(sctp SCTP)],
      133 => [qw(fc FC)],
      134 => [qw(rsvp-e2e-ignore RSVP-E2E-IGNORE)],
      240 => [qw(pfsync PFSYNC)],
      255 => [qw(reserved Reserved)]);
}

#!/usr/bin/perl
use strict;
use Test::More;
eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD spell" if $@;
set_spell_cmd('aspell -l --lang=en');
add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__END__

SAPER
Sébastien
Aperghis
Tramoni
Christiansen
AnnoCPAN
CPAN
README
TODO
AUTOLOADER
API
arrayref
arrayrefs
hashref
hashrefs
lookup
hostname
loopback
netmask
timestamp
INET
BPF
IP
TCP
tcp
UDP
udp
UUCP
FDDI
Firewire
HDLC
IEEE
IrDA
LocalTalk
PPP
unix
Solaris
IRIX
endianness
failover
Failover
logopts
pathname
syslogd
logmask

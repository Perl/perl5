#!/usr/bin/perl -w

use strict;
use Test::More tests => 26;

use IO::Socket::IP;

use IO::Socket::INET;
use Socket qw( unpack_sockaddr_in );

foreach my $socktype (qw( SOCK_STREAM SOCK_DGRAM )) {
   my $testserver = IO::Socket::IP->new(
      ( $socktype eq "SOCK_STREAM" ? ( Listen => 1 ) : () ),
      LocalHost => "127.0.0.1",
      Type      => Socket->$socktype,
   );

   ok( defined $testserver, "IO::Socket::IP->new constructs a $socktype socket" ) or
      diag( "  error was $@" );

   is( $testserver->sockdomain, AF_INET,           "\$testserver->sockdomain for $socktype" );
   is( $testserver->socktype,   Socket->$socktype, "\$testserver->socktype for $socktype" );

   is( $testserver->sockhost, "127.0.0.1", "\$testserver->sockhost for $socktype" );
   like( $testserver->sockport, qr/^\d+$/, "\$testserver->sockport for $socktype" );

   my $socket = IO::Socket::INET->new(
      PeerHost => "127.0.0.1",
      PeerPort => $testserver->sockport,
      Type     => Socket->$socktype,
      Proto    => ( $socktype eq "SOCK_STREAM" ? "tcp" : "udp" ), # Because IO::Socket::INET is stupid and always presumes tcp
   ) or die "Cannot connect to PF_INET - $@";

   my $testclient = ( $socktype eq "SOCK_STREAM" ) ? 
      $testserver->accept : 
      do { $testserver->connect( $socket->sockname ); $testserver };

   ok( defined $testclient, "accepted test $socktype client" );
   isa_ok( $testclient, "IO::Socket::IP", "\$testclient for $socktype" );

   is( $testclient->sockdomain, AF_INET,           "\$testclient->sockdomain for $socktype" );
   is( $testclient->socktype,   Socket->$socktype, "\$testclient->socktype for $socktype" );

   is_deeply( [ unpack_sockaddr_in $socket->sockname ],
              [ unpack_sockaddr_in $testclient->peername ],
              "\$socket->sockname for $socktype" );

   is_deeply( [ unpack_sockaddr_in $socket->peername ],
              [ unpack_sockaddr_in $testclient->sockname ],
              "\$socket->peername for $socktype" );

   is( $testclient->sockport, $socket->peerport, "\$testclient->sockport for $socktype" );
   is( $testclient->peerport, $socket->sockport, "\$testclient->peerport for $socktype" );
}

#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Socket::IP;
use Socket;

my $AF_INET6 = eval { require Socket and Socket::AF_INET6() } or
   plan skip_all => "No AF_INET6";

eval { IO::Socket::IP->new( LocalHost => "::1" ) } or
   plan skip_all => "Unable to bind to ::1";

# Unpack just ip6_addr and port because other fields might not match end to end
sub unpack_sockaddr_in6_addrport { 
   return ( Socket::unpack_sockaddr_in6( shift ) )[0,1];
}

foreach my $socktype (qw( SOCK_STREAM SOCK_DGRAM )) {
   my $testserver = IO::Socket::IP->new(
      ( $socktype eq "SOCK_STREAM" ? ( Listen => 1 ) : () ),
      LocalHost => "::1",
      Type      => Socket->$socktype,
   );

   ok( defined $testserver, "IO::Socket::IP->new constructs a $socktype socket" ) or
      diag( "  error was $@" );

   is( $testserver->sockdomain, $AF_INET6,         "\$testserver->sockdomain for $socktype" );
   is( $testserver->socktype,   Socket->$socktype, "\$testserver->socktype for $socktype" );

   is( $testserver->sockhost, "::1",       "\$testserver->sockhost for $socktype" );
   like( $testserver->sockport, qr/^\d+$/, "\$testserver->sockport for $socktype" );

   my $socket = IO::Socket->new;
   $socket->socket( $AF_INET6, Socket->$socktype, 0 )
      or die "Cannot socket() - $!";

   my ( $err, $ai ) = Socket::getaddrinfo( "::1", $testserver->sockport, { family => $AF_INET6, socktype => Socket->$socktype } );
   die "getaddrinfo() - $err" if $err;

   $socket->connect( $ai->{addr} ) or die "Cannot connect() - $!";

   my $testclient = ( $socktype eq "SOCK_STREAM" ) ? 
      $testserver->accept : 
      do { $testserver->connect( $socket->sockname ); $testserver };

   ok( defined $testclient, "accepted test $socktype client" );
   isa_ok( $testclient, "IO::Socket::IP", "\$testclient for $socktype" );

   is( $testclient->sockdomain, $AF_INET6,         "\$testclient->sockdomain for $socktype" );
   is( $testclient->socktype,   Socket->$socktype, "\$testclient->socktype for $socktype" );

   is_deeply( [ unpack_sockaddr_in6_addrport( $socket->sockname ) ],
              [ unpack_sockaddr_in6_addrport( $testclient->peername ) ],
              "\$socket->sockname for $socktype" );

   is_deeply( [ unpack_sockaddr_in6_addrport( $socket->peername ) ],
              [ unpack_sockaddr_in6_addrport( $testclient->sockname ) ],
              "\$socket->peername for $socktype" );

   my $peerport = ( Socket::unpack_sockaddr_in6 $socket->peername )[0];
   my $sockport = ( Socket::unpack_sockaddr_in6 $socket->sockname )[0];

   is( $testclient->sockport, $peerport, "\$testclient->sockport for $socktype" );
   is( $testclient->peerport, $sockport, "\$testclient->peerport for $socktype" );

   # Unpack just so it pretty prints without wrecking the terminal if it fails
   is( unpack("H*", $testclient->peeraddr), "0000"x7 . "0001", "\$testclient->peeraddr for $socktype" );
   if( $socktype eq "SOCK_STREAM" ) {
      # Some OSes don't update sockaddr with a local bind() on SOCK_DGRAM sockets
      is( unpack("H*", $testclient->sockaddr), "0000"x7 . "0001", "\$testclient->sockaddr for $socktype" );
   }
}

done_testing;

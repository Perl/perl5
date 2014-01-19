#!/usr/bin/perl

use strict;
use warnings;

use Errno qw( EINPROGRESS );
use IO::Poll;
use IO::Socket::IP;
use Net::LibAsyncNS;
use Socket qw( SOCK_STREAM );

my $host    = shift @ARGV or die "Need HOST\n";
my $service = shift @ARGV or die "Need SERVICE\n";

my $poll = IO::Poll->new;

my $asyncns = Net::LibAsyncNS->new( 1 );
my $asyncns_fh = $asyncns->new_handle_for_fd;

my $q = $asyncns->getaddrinfo( $host, $service, { socktype => SOCK_STREAM } );

$poll->mask( $asyncns_fh => POLLIN );

while( !$q->isdone ) {
   $poll->poll( undef );

   if( $poll->events( $asyncns_fh ) ) {
      $asyncns->wait( 0 );
   }
}

$poll->mask( $asyncns_fh => 0 );

my ( $err, @peeraddrinfo ) = $asyncns->getaddrinfo_done( $q );
$err and die "getaddrinfo() - $!";

my $socket = IO::Socket::IP->new(
   PeerAddrInfo => \@peeraddrinfo,
   Blocking     => 0,
) or die "Cannot construct socket - $@";

$poll->mask( $socket => POLLOUT );

while(1) {
   $poll->poll( undef );

   if( $poll->events( $socket ) & POLLOUT ) {
      last if $socket->connect;
      die "Cannot connect - $!" unless $! == EINPROGRESS;
   }
}

printf STDERR "Connected to %s:%s\n", $socket->peerhost_service;

$poll->mask( \*STDIN => POLLIN );
$poll->mask( $socket => POLLIN );

while(1) {
   $poll->poll( undef );

   if( $poll->events( \*STDIN ) ) {
      my $ret = STDIN->sysread( my $buffer, 8192 );
      defined $ret or die "Cannot read STDIN - $!\n";
      $ret or last;
      $socket->syswrite( $buffer );
   }
   if( $poll->events( $socket ) ) {
      my $ret = $socket->sysread( my $buffer, 8192 );
      defined $ret or die "Cannot read socket - $!\n";
      $ret or last;
      STDOUT->syswrite( $buffer );
   }
}

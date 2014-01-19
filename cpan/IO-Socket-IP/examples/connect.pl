#!/usr/bin/perl

use strict;
use warnings;

use IO::Poll;
use IO::Socket::IP;
use Socket qw( SOCK_STREAM );

my $host    = shift @ARGV or die "Need HOST\n";
my $service = shift @ARGV or die "Need SERVICE\n";

my $socket = IO::Socket::IP->new(
   PeerHost    => $host,
   PeerService => $service,
   Type        => SOCK_STREAM,
) or die "Cannot connect to $host:$service - $@";

printf STDERR "Connected to %s:%s\n", $socket->peerhost_service;

my $poll = IO::Poll->new;

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

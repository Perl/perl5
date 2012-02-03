#!/usr/bin/perl -w

use strict;
use Test::More tests => 10;

use IO::Socket::IP;

use IO::Socket::INET;
use Errno qw( EINPROGRESS EWOULDBLOCK ECONNREFUSED );

# Chris Williams (BINGOS) has offered cpanidx.org as a TCP testing server here
my $test_host = "cpanidx.org";
my $test_good_port = 80;
my $test_bad_port = 6666;

SKIP: {
   IO::Socket::INET->new(
      PeerHost => $test_host,
      PeerPort => $test_good_port,
      Type     => SOCK_STREAM,
   ) or skip "Can't connect to $test_host:$test_good_port", 5;

   my $socket = IO::Socket::IP->new(
      PeerHost    => $test_host,
      PeerService => $test_good_port,
      Type        => SOCK_STREAM,
      Blocking    => 0,
   );

   ok( defined $socket, "defined \$socket for $test_host:$test_good_port" ) or
      diag( "  error was $@" );

   # This and test is required to placate a warning IO::Socket would otherwise
   # throw; https://rt.cpan.org/Ticket/Display.html?id=63052
   ok( not( $socket->opened and $socket->connected ), '$socket not yet connected' );

   my $selectcount = 0;

   while( !$socket->connect and ( $! == EINPROGRESS || $! == EWOULDBLOCK ) ) {
      my $wvec = '';
      vec( $wvec, fileno $socket, 1 ) = 1;
      my $evec = '';
      vec( $evec, fileno $socket, 1 ) = 1;

      $selectcount++;
      my $ret = select( undef, $wvec, $evec, 60 );
      defined $ret or die "Cannot select() - $!";
      $ret or die "select() timed out";
   }

   ok( !$!, '->connect eventually succeeds' );
   ok( $selectcount > 0, '->connect had to select() at least once' );

   ok( $socket->connected, '$socket now connected' );
}

SKIP: {
   IO::Socket::INET->new(
      PeerHost => $test_host,
      PeerPort => $test_bad_port,
      Type     => SOCK_STREAM,
   ) and skip "Connecting to $test_host:$test_bad_port succeeds", 5;
   $! == ECONNREFUSED or skip "Connecting to $test_host:$test_bad_port doesn't give ECONNREFUSED", 5;

   my $socket = IO::Socket::IP->new(
      PeerHost    => $test_host,
      PeerService => $test_bad_port,
      Type        => SOCK_STREAM,
      Blocking    => 0,
   );

   ok( defined $socket, "defined \$socket for $test_host:$test_bad_port" ) or
      diag( "  error was $@" );

   ok( not( $socket->opened and $socket->connected ), '$socket not yet connected' );

   my $selectcount = 0;

   while( !$socket->connect and ( $! == EINPROGRESS || $! == EWOULDBLOCK ) ) {
      my $wvec = '';
      vec( $wvec, fileno $socket, 1 ) = 1;
      my $evec = '';
      vec( $evec, fileno $socket, 1 ) = 1;

      $selectcount++;
      my $ret = select( undef, $wvec, $evec, 60 );
      defined $ret or die "Cannot select() - $!";
      $ret or die "select() timed out";
   }

   my $dollarbang = $!;

   ok( $dollarbang == ECONNREFUSED, '->connect eventually fails with ECONNREFUSED' ) or
      diag( "  dollarbang = $dollarbang" );

   ok( $selectcount > 0, '->connect had to select() at least once' );

   ok( !$socket->opened, '$socket is not even opened' );
}

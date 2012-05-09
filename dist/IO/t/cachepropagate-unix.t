#!/usr/bin/perl

use warnings;
use strict;

use File::Temp qw(tempdir);
use File::Spec::Functions;
use IO::Socket;
use IO::Socket::UNIX;
use Socket;
use Config;
use Test::More;

plan tests => 15;

SKIP: {
  skip "UNIX domain sockets not implemented on $^O", 15 if ($^O =~ m/^(?:qnx|nto|vos|MSWin32)$/);

  my $socketpath = catfile(tempdir( CLEANUP => 1 ), 'testsock');

  # start testing stream sockets:

  my $listener = IO::Socket::UNIX->new(Type => SOCK_STREAM,
				       Listen => 1,
				       Local => $socketpath);
  ok(defined($listener), 'stream socket created');

  my $p = $listener->protocol();
  ok(defined($p), 'protocol defined');
  my $d = $listener->sockdomain();
  ok(defined($d), 'domain defined');
  my $s = $listener->socktype();
  ok(defined($s), 'type defined');

  SKIP: {
    $Config{d_pseudofork} || $Config{d_fork}
      or skip("no fork", 4);
    my $cpid = fork();
    if (0 == $cpid) {
      # the child:
      sleep(1);
      my $connector = IO::Socket::UNIX->new(Peer => $socketpath);
      exit(0);
    } else {
      ok(defined($cpid), 'spawned a child');
    }

    my $new = $listener->accept();

    is($new->sockdomain(), $d, 'domain match');
    SKIP: {
      skip "no Socket::SO_PROTOCOL", 1 if !defined(eval { Socket::SO_PROTOCOL });
      is($new->protocol(), $p, 'protocol match');
    }
    SKIP: {
      skip "no Socket::SO_TYPE", 1 if !defined(eval { Socket::SO_TYPE });
      is($new->socktype(), $s, 'type match');
    }

    unlink($socketpath);
    wait();
  }

  # now test datagram sockets:
  $listener = IO::Socket::UNIX->new(Type => SOCK_DGRAM,
		      Local => $socketpath);
  ok(defined($listener), 'datagram socket created');

  $p = $listener->protocol();
  ok(defined($p), 'protocol defined');
  $d = $listener->sockdomain();
  ok(defined($d), 'domain defined');
  $s = $listener->socktype();
  ok(defined($s), 'type defined');

  my $new = IO::Socket::UNIX->new_from_fd($listener->fileno(), 'r+');

  is($new->sockdomain(), $d, 'domain match');
  SKIP: {
    skip "no Socket::SO_PROTOCOL", 1 if !defined(eval { Socket::SO_PROTOCOL });
    is($new->protocol(), $p, 'protocol match');
  }
  SKIP: {
    skip "no Socket::SO_TYPE", 1 if !defined(eval { Socket::SO_TYPE });
    is($new->socktype(), $s, 'type match');
  }
  unlink($socketpath);
}

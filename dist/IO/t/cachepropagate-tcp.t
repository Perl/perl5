#!/usr/bin/perl

use warnings;
use strict;

use IO::Socket;
use IO::Socket::INET;
use Socket;
use Config;
use Test::More;

plan tests => 8;

my $listener = IO::Socket::INET->new(Listen => 1,
                                     LocalAddr => '127.0.0.1',
                                     Proto => 'tcp');
ok(defined($listener), 'socket created');

my $port = $listener->sockport();

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
    my $connector = IO::Socket::INET->new(PeerAddr => '127.0.0.1',
                                          PeerPort => $port,
                                          Proto => 'tcp');
    exit(0);
  } else {;
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

  wait();
}

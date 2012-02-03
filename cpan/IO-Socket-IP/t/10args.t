#!/usr/bin/perl -w

use strict;
use Test::More;

use IO::Socket::IP;

sub arguments_is {
   my ($arg, $exp, $name) = @_;

   $arg = [$arg]
   unless ref $arg;

   $name ||= join ' ', map { defined $_ ? $_ : 'undef' } @$arg;

   my $got = do {
      no warnings 'redefine';
      my $args;

      local *IO::Socket::IP::_configure = sub {
         $args = $_[1];
         return $_[0];
      };

      IO::Socket::IP->new(@$arg);

      $args;
   };

   is_deeply($got, $exp, $name);
}

my @tests = (
   [ [ '[::1]:80'               ], { PeerHost  => '::1',           PeerService => '80'    } ],
   [ [ '[::1]:http'             ], { PeerHost  => '::1',           PeerService => 'http'  } ],
   [ [ '[::1]'                  ], { PeerHost  => '::1',                                  } ],
   [ [ '[::1]:'                 ], { PeerHost  => '::1',                                  } ],
   [ [ '127.0.0.1:80'           ], { PeerHost  => '127.0.0.1',     PeerService => '80'    } ],
   [ [ '127.0.0.1:http'         ], { PeerHost  => '127.0.0.1',     PeerService => 'http'  } ],
   [ [ '127.0.0.1'              ], { PeerHost  => '127.0.0.1',                            } ],
   [ [ '127.0.0.1:'             ], { PeerHost  => '127.0.0.1',                            } ],
   [ [ 'localhost:80'           ], { PeerHost  => 'localhost',     PeerService => '80'    } ],
   [ [ 'localhost:http'         ], { PeerHost  => 'localhost',     PeerService => 'http'  } ],
   [ [ PeerHost  => '[::1]:80'  ], { PeerHost  => '::1',           PeerService => '80'    } ],
   [ [ PeerHost  => '[::1]'     ], { PeerHost  => '::1'                                   } ],
   [ [ LocalHost => '[::1]:80'  ], { LocalHost => '::1',           LocalService => '80'   } ],
   [ [ LocalHost => undef       ], { LocalHost => undef                                   } ],
);

plan tests => scalar(@tests);

arguments_is(@$_) for @tests;

BEGIN {
  if ($ENV{PERL_CORE}) {
    unless ($ENV{PERL_TEST_Net_Ping}) {
      print "1..0 # Skip: network dependent test\n";
        exit;
    }
    chdir 't' if -d 't';
    @INC = qw(../lib);
  }
  unless (eval "require Socket") {
    print "1..0 \# Skip: no Socket\n";
    exit;
  }
  unless (getservbyname('echo', 'tcp')) {
    print "1..0 \# Skip: no echo port\n";
    exit;
  }
  unless (getservbyname('http', 'tcp')) {
    print "1..0 \# Skip: no http port\n";
    exit;
  }
}

# Remote network test using syn protocol.
#
# NOTE:
#   Network connectivity will be required for all tests to pass.
#   Firewalls may also cause some tests to fail, so test it
#   on a clear network.  If you know you do not have a direct
#   connection to remote networks, but you still want the tests
#   to pass, use the following:
#
# $ PERL_CORE=1 make test

# Try a few remote servers
my $webs = {
  # Hopefully this is never a routeable host
  "172.29.249.249" => 0,

  # Hopefully all these web servers are on
  "www.geocities.com." => 1,
  "www.freeservers.com." => 1,
  "yahoo.com." => 1,
  "www.yahoo.com." => 1,
  "www.about.com." => 1,
  "www.microsoft.com." => 1,
};

use strict;
use Test;
use Net::Ping;
plan tests => ((keys %{ $webs }) * 2 + 3);

# Everything loaded fine
ok 1;

my $p = new Net::Ping "syn", 10;

# new() worked?
ok !!$p;

# Change to use the more common web port.
# (Make sure getservbyname works in scalar context.)
ok ($p -> {port_num} = getservbyname("http", "tcp"));

foreach my $host (keys %{ $webs }) {
  # ping() does dns resolution and
  # only sends the SYN at this point
  if ($p -> ping($host)) {
    ok 1;
  } else {
    print STDERR "CANNOT RESOLVE $host\n";
    ok 0;
  }
}

while (my $host = $p->ack()) {
  if ($webs->{$host}) {
    ok 1;
  } else {
    print STDERR "SUPPOSED TO BE DOWN: http://$host/\n";
    ok 0;
  }
  delete $webs->{$host};
}

foreach my $host (keys %{ $webs }) {
  if ($webs->{$host}) {
    print STDERR "DOWN: http://$host/\n";
    ok 0;
  } else {
    ok 1;
  }
}

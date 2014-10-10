#!perl

use 5.008001;

use strict;
use warnings;

use Net::POP3;
use Test::More;

my $host = 'pop.gmx.net';
my $debug = 0;

plan skip_all => "no SSL support" if ! Net::POP3->can_ssl;
{
no warnings 'once';
plan skip_all => "no verified SSL connection to $host:995 - $@" if ! eval {
  IO::Socket::SSL->new(PeerAddr => "$host:995", Timeout => 10)
    || die($IO::Socket::SSL::SSL_ERROR||$!);
};
}

plan tests => 2;

SKIP: {
  diag( "connect inet to $host:110" );
  skip "no inet connect to $host:110",1 
    if ! IO::Socket::INET->new(PeerAddr => "$host:110", Timeout => 10);
  my $pop3 = Net::POP3->new($host, Debug => $debug, Timeout => 10)
    or skip "normal POP3 failed: $@",1;
  skip "no STARTTLS support",1 if $pop3->message !~/STARTTLS/;

  if (!$pop3->starttls) {
    fail("starttls failed: ".$pop3->code." $@")
  } else {
    # we now should have access to SSL stuff
    my $cipher = eval { $pop3->get_cipher };
    if (!$cipher) {
      fail("after starttls: not an SSL object");
    } elsif ( $pop3->quit ) {
      pass("starttls + quit ok, cipher=$cipher");
    } else {
      fail("quit after starttls failed: ".$pop3->code);
    }
  }
}


my $pop3 = Net::POP3->new($host, SSL => 1, Timeout => 10, Debug => $debug);
# we now should have access to SSL stuff
my $cipher = eval { $pop3->get_cipher };
if (!$cipher) {
  fail("after ssl connect: not an SSL object");
} elsif ( $pop3->quit ) {
  pass("ssl connect ok, cipher=$cipher");
} else {
  fail("quit after direct ssl failed: ".$pop3->code);
}

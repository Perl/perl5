#!perl

use 5.008001;

use strict;
use warnings;

use Net::SMTP;
use Test::More;

my $host = 'mail.gmx.net';
my $debug = 0;

plan skip_all => "no SSL support" if ! Net::SMTP->can_ssl;
{
no warnings 'once';
plan skip_all => "no verified SSL connection to $host:465 - $@" if ! eval {
  IO::Socket::SSL->new("$host:465")
    || die($IO::Socket::SSL::SSL_ERROR||$!);
};
}

plan tests => 2;

SKIP: {
  diag( "connect inet to $host:25" );
  skip "no inet connect to $host:25",1 if ! IO::Socket::INET->new("$host:25");
  my $smtp = Net::SMTP->new($host, Debug => $debug)
    or skip "normal SMTP failed: $@",1;
  skip "no STARTTLS support",1 if $smtp->message !~/STARTTLS/;

  if (!$smtp->starttls) {
    fail("starttls failed: ".$smtp->code." $@")
  } else {
    # we now should have access to SSL stuff
    my $cipher = eval { $smtp->get_cipher };
    if (!$cipher) {
      fail("after starttls: not an SSL object");
    } elsif ( $smtp->quit ) {
      pass("starttls + quit ok, cipher=$cipher");
    } else {
      fail("quit after starttls failed: ".$smtp->code);
    }
  }
}


my $smtp = Net::SMTP->new($host, SSL => 1, Debug => $debug);
# we now should have access to SSL stuff
my $cipher = eval { $smtp->get_cipher };
if (!$cipher) {
  fail("after ssl connect: not an SSL object");
} elsif ( $smtp->quit ) {
  pass("ssl connect ok, cipher=$cipher");
} else {
  fail("quit after direct ssl failed: ".$smtp->code);
}

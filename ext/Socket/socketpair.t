#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bSocket\b/ && 
        !(($^O eq 'VMS') && $Config{d_socket})) {
	print "1..0\n";
	exit 0;
    }
}
	
use Socket;
use Test::More;
use strict;
use warnings;
use Errno;

my $skip_reason;

if( !$Config{d_alarm} ) {
  plan skip_all => "alarm() not implemented on this platform";
} else {
  # This should fail but not die if there is real socketpair
  eval {socketpair LEFT, RIGHT, -1, -1, -1};
  if ($@ =~ /^Unsupported socket function "socketpair" called/) {
    plan skip_all => 'No socketpair (real or emulated)';
  } else {
    eval {AF_UNIX};
    if ($@ =~ /^Your vendor has not defined Socket macro AF_UNIX/) {
      plan skip_all => 'No AF_UNIX';
    } else {
      plan tests => 45;
    }
  }
}

# Too many things in this test will hang forever if something is wrong, so
# we need a self destruct timer.
$SIG{ALRM} = sub {die "Something unexpectedly hung during testing"};
alarm(60);

ok (socketpair (LEFT, RIGHT, AF_UNIX, SOCK_STREAM, PF_UNSPEC),
    "socketpair (LEFT, RIGHT, AF_UNIX, SOCK_STREAM, PF_UNSPEC)")
  or print "# \$\! = $!\n";

my @left = ("hello ", "world\n");
my @right = ("perl ", "rules!"); # Not like I'm trying to bias any survey here.

foreach (@left) {
  # is (syswrite (LEFT, $_), length $_, "write " . _qq ($_) . " to left");
  is (syswrite (LEFT, $_), length $_, "syswrite to left");
}
foreach (@right) {
  # is (syswrite (RIGHT, $_), length $_, "write " . _qq ($_) . " to right");
  is (syswrite (RIGHT, $_), length $_, "syswrite to right");
}

# stream socket, so our writes will become joined:
my ($buffer, $expect);
$expect = join '', @right;
undef $buffer;
is (read (LEFT, $buffer, length $expect), length $expect, "read on left");
is ($buffer, $expect, "content what we expected?");
$expect = join '', @left;
undef $buffer;
is (read (RIGHT, $buffer, length $expect), length $expect, "read on right");
is ($buffer, $expect, "content what we expected?");

ok (shutdown(LEFT, SHUT_WR), "shutdown left for writing");
# This will hang forever if eof is buggy.
{
  local $SIG{ALRM} = sub { warn "EOF on right took over 3 seconds" };
  alarm 3;
  $! = 0;
  ok (eof RIGHT, "right is at EOF");
  is ($!, '', 'and $! should report no error');
  alarm 60;
}

$SIG{PIPE} = 'IGNORE';
{
  local $SIG{ALRM}
    = sub { warn "syswrite to left didn't fail within 3 seconds" };
  alarm 3;
  is (syswrite (LEFT, "void"), undef, "syswrite to shutdown left should fail");
  alarm 60;
}
SKIP: {
  # This may need skipping on some OSes
  ok (($!{EPIPE} or $!{ESHUTDOWN}), '$! should be EPIPE or ESHUTDOWN')
    or printf "\$\!=%d(%s)\n", $!, $!;
}

my @gripping = (chr 255, chr 127);
foreach (@gripping) {
  is (syswrite (RIGHT, $_), length $_, "syswrite to right");
}

ok (!eof LEFT, "left is not at EOF");

$expect = join '', @gripping;
undef $buffer;
is (read (LEFT, $buffer, length $expect), length $expect, "read on left");
is ($buffer, $expect, "content what we expected?");

ok (close LEFT, "close left");
ok (close RIGHT, "close right");

# And now datagrams
# I suspect we also need a self destruct time-bomb for these, as I don't see any
# guarantee that the stack won't drop a UDP packet, even if it is for localhost.

ok (socketpair (LEFT, RIGHT, AF_UNIX, SOCK_DGRAM, PF_UNSPEC),
    "socketpair (LEFT, RIGHT, AF_UNIX, SOCK_DGRAM, PF_UNSPEC)")
  or print "# \$\! = $!\n";

foreach (@left) {
  # is (syswrite (LEFT, $_), length $_, "write " . _qq ($_) . " to left");
  is (syswrite (LEFT, $_), length $_, "syswrite to left");
}
foreach (@right) {
  # is (syswrite (RIGHT, $_), length $_, "write " . _qq ($_) . " to right");
  is (syswrite (RIGHT, $_), length $_, "syswrite to right");
}

# stream socket, so our writes will become joined:
my ($total);
$total = join '', @right;
foreach $expect (@right) {
  undef $buffer;
  is (sysread (LEFT, $buffer, length $total), length $expect, "read on left");
  is ($buffer, $expect, "content what we expected?");
}
$total = join '', @left;
foreach $expect (@left) {
  undef $buffer;
  is (sysread (RIGHT, $buffer, length $total), length $expect, "read on right");
  is ($buffer, $expect, "content what we expected?");
}

ok (shutdown(LEFT, 1), "shutdown left for writing");
# eof uses buffering. eof is indicated by a sysread of zero.
# but for a datagram socket there's no way it can know nothing will ever be
# sent
{
  my $alarmed = 0;
  local $SIG{ALRM} = sub { $alarmed = 1; };
  print "# Approximate forever as 3 seconds. Wait 'forever'...\n";
  alarm 3;
  undef $buffer;
  is (sysread (RIGHT, $buffer, 1), undef,
      "read on right should be interrupted");
  is ($alarmed, 1, "alarm should have fired");
}
alarm 30;

#ok (eof RIGHT, "right is at EOF");

foreach (@gripping) {
  is (syswrite (RIGHT, $_), length $_, "syswrite to right");
}

$total = join '', @gripping;
foreach $expect (@gripping) {
  undef $buffer;
  is (sysread (LEFT, $buffer, length $total), length $expect, "read on left");
  is ($buffer, $expect, "content what we expected?");
}

ok (close LEFT, "close left");
ok (close RIGHT, "close right");

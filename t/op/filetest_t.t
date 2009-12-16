#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;

plan 2;

my($dev_tty, $dev_null) = qw(/dev/tty /dev/null);
  ($dev_tty, $dev_null) = qw(con      nul      ) if $^O =~ /^(MSWin32|os2)$/;
  ($dev_tty, $dev_null) = qw(TT:      _NLA0:   ) if $^O eq "VMS";

SKIP: {
    open(my $tty, "<", $dev_tty)
	or skip("Can't open terminal '$dev_tty': $!");
    ok(-t $tty);
}
SKIP: {
    open(my $null, "<", $dev_null)
	or skip("Can't open null device '$dev_null': $!");
    ok(!-t $null);
}

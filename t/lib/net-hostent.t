#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bSocket\b/ && 
        !(($^O eq 'VMS') && $Config{d_socket})) {
	print "1..0 # Test uses Socket, Socket not built\n";
	exit 0;
    }
}

BEGIN { $| = 1; print "1..7\n"; }

END {print "not ok 1\n" unless $loaded;}

use Net::hostent;

$loaded = 1;
print "ok 1\n";

# test basic resolution of localhost <-> 127.0.0.1
use Socket;

my $h = gethost('localhost');
print +(defined $h ? '' : 'not ') . "ok 2\n";
my $i = gethostbyaddr(inet_aton("127.0.0.1"));
print +(!defined $i ? 'not ' : '') . "ok 3\n";

print "not " if inet_ntoa($h->addr) ne "127.0.0.1";
print "ok 4\n";

print "not " if inet_ntoa($i->addr) ne "127.0.0.1";
print "ok 5\n";

# need to skip the name comparisons on Win32 because windows will
# return the name of the machine instead of "localhost" when resolving
# 127.0.0.1 or even "localhost"

# VMS returns "LOCALHOST" under tcp/ip services V4.1 ECO 2, possibly others
# OS/390 returns localhost.YADDA.YADDA

if ($^O eq 'MSWin32' or $^O eq 'NetWare' or $^O eq 'cygwin') {
  print "ok $_ # skipped on win32\n" for (6,7);
} else {
  my $in_alias;
  unless ($h->name =~ /^localhost(?:\..+)?$/i) {
    foreach (@{$h->aliases}) {
      if (/^localhost(?:\..+)?$/i) {
       $in_alias = 1;
       last;
      }
    }
    print "not " unless $in_alias;
  } # Else we found it as the hostname
  print "ok 6 # ",$h->name, " ", join (",", @{$h->aliases}), "\n";

  if ($in_alias) {
    # If we found it in the aliases before, expect to find it there again.
    foreach (@{$h->aliases}) {
      if (/^localhost(?:\..+)?$/i) {
       undef $in_alias; # This time, clear the flag if we see "localhost"
       last;
      }
    }
    print "not " if $in_alias;
  } else {
    print "not " unless $i->name =~ /^localhost(?:\..+)?$/i;
  }
  print "ok 7 # ",$h->name, " ", join (",", @{$h->aliases}), "\n";
}

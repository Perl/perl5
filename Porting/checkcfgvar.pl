#!/usr/bin/perl

# Check that the various config.sh-clones have (at least) all the
# same symbols as the top-level config_h.SH so that the (potentially)
# needed symbols are not lagging after how Configure thinks the world
# is laid out.
#
# VMS is probably not handled properly here, due to their own
# rather elaborate DCL scripting.
#

use strict;
use warnings;
use autodie;

sub usage
{
    my $err = shift and select STDERR;
    print "usage: $0 [--list]\n";
    exit $err;
    } # usage

use Getopt::Long;
my $opt_l = 0;
GetOptions (
    "help|?"	=> sub { usage (0); },
    "l|list!"	=> \$opt_l,
    ) or usage (1);

my $MASTER_CFG = "config_h.SH";

my @CFG = (
	   # we check from MANIFEST whether they are expected to be present.
	   # We can't base our check on $], because that's the version of the
	   # perl that we are running, not the version of the source tree.
	   "Cross/config.sh-arm-linux",
	   "epoc/config.sh",
	   "NetWare/config.wc",
	   "symbian/config.sh",
	   "uconfig.sh",
	   "uconfig64.sh",
	   "plan9/config_sh.sample",
	   "win32/config.bc",
	   "win32/config.gc",
	   "win32/config.gc64",
	   "win32/config.gc64nox",
	   "win32/config.vc",
	   "win32/config.vc64",
	   "win32/config.ce",
	   "configure.com",
	   "Porting/config.sh",
	  );

my @MASTER_CFG;
{
    my %seen;
    open my $fh, '<', $MASTER_CFG;
    while (<$fh>) {
	while (/[^\\]\$([a-z]\w+)/g) {
	    my $v = $1;
	    next if $v =~ /^(CONFIG_H|CONFIG_SH)$/;
	    $seen{$v}++;
	}
    }
    close $fh;
    @MASTER_CFG = sort keys %seen;
}

my %MANIFEST;

{
    open my $fh, '<', 'MANIFEST';
    while (<$fh>) {
	$MANIFEST{$1}++ if /^(.+?)\t/;
    }
    close $fh;
}

for my $cfg (sort @CFG) {
    unless (exists $MANIFEST{$cfg}) {
	print STDERR "[skipping not-expected '$cfg']\n";
	next;
    }
    my %cfg;

    open my $fh, '<', $cfg;
    while (<$fh>) {
	next if /^\#/ || /^\s*$/ || /^\:/;
	if ($cfg eq 'configure.com') {
	    s/(\s*!.*|\s*)$//; # remove trailing comments or whitespace
	    next if ! /^\$\s+WC "(\w+)='(.*)'"$/;
	}
	# foo='bar'
	# foo=bar
	if (/^(\w+)='(.*)'$/) {
	    $cfg{$1}++;
	}
	elsif (/^(\w+)=(.*)$/) {
	    $cfg{$1}++;
	}
	elsif (/^\$\s+WC "(\w+)='(.*)'"$/) {
	    $cfg{$1}++;
	} else {
	    warn "$cfg:$.:$_";
	}
    }
    close $fh;

    if ($cfg eq 'configure.com') {
	$cfg{startperl}++; # Cheat.
    }

    my $problems;
    for my $v (@MASTER_CFG) {
	exists $cfg{$v} and next;
	if ($opt_l) {
	    # print the name once, for the first problem we encounter.
	    print "$cfg\n" unless $problems++;
	}
	else {
	    print "$cfg: missing '$v'\n";
	}
    }
}

# Net::Domain.pm
#
# Copyright (c) 1995 Graham Barr <Graham.Barr@tiuk.ti.com>. All rights
# reserved. This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Net::Domain;

=head1 NAME

Net::Domain - Attempt to evaluate the current host's internet name and domain

=head1 SYNOPSIS

    use Net::Domain qw(hostname hostfqdn hostdomain);

=head1 DESCRIPTION

Using various methods B<attempt> to find the Fully Qualified Domain Name (FQDN)
of the current host. From this determine the host-name and the host-domain.

Each of the functions will return I<undef> if the FQDN cannot be determined.

=over 4

=item hostfqdn ()

Identify and return the FQDN of the current host.

=item hostname ()

Returns the smallest part of the FQDN which can be used to identify the host.

=item hostdomain ()

Returns the remainder of the FQDN after the I<hostname> has been removed.

=back

=head1 AUTHOR

Graham Barr <bodg@tiuk.ti.com>.
Adapted from Sys::Hostname by David Sundstrom <sunds@asictest.sc.ti.com>

=head1 REVISION

$Revision: 2.0 $

=head1 COPYRIGHT

Copyright (c) 1995 Graham Barr. All rights reserved.
This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

require Exporter;

use Carp;
use strict;
use vars qw($VERSION @ISA @EXPORT_OK);

@ISA = qw(Exporter);
@EXPORT_OK = qw(hostname hostdomain hostfqdn domainname);

$VERSION = sprintf("%d.%02d", q$Revision: 2.0 $ =~ /(\d+)\.(\d+)/);

my($host,$domain,$fqdn) = (undef,undef,undef);

# Try every conceivable way to get hostname.

sub _hostname {

    # method 1 - we already know it
    return $host
    	if(defined $host);

    # method 2 - syscall is preferred since it avoids tainting problems
    eval {
    	{
    	    package main;
     	    require "syscall.ph";
    	}
    	my $tmp = "\0" x 65; ## preload scalar
    	$host = (syscall(&main::SYS_gethostname, $tmp, 65) == 0) ? $tmp : undef;
    }


    # method 3 - trusty old hostname command
    || eval {
    	chop($host = `(hostname) 2>/dev/null`); # BSD'ish
    }

    # method 4 - sysV/POSIX uname command (may truncate)
    || eval {
    	chop($host = `uname -n 2>/dev/null`); ## SYSV'ish && POSIX'ish
    }

 
    # method 5 - Apollo pre-SR10
    || eval {
    	$host = (split(/[:\. ]/,`/com/host`,6))[0];
    }

    || eval {
    	$host = "";
    };
 
    # remove garbage 
    $host =~ s/[\0\r\n]+//go;
    $host =~ s/(\A\.+|\.+\Z)//go;
    $host =~ s/\.\.+/\./go;

    $host;
}

sub _hostdomain {

    # method 1 - we already know it
    return $domain
    	if(defined $domain);

    # method 2 - just try hostname and system calls

    my $host = _hostname();
    my($dom,$site,@hosts);
    local($_);

    @hosts = ($host,"localhost");

    unless($host =~ /\./) {
  	chop($dom = `domainname 2>/dev/null`);
    	unshift(@hosts, "$host.$dom")
    	    if (defined $dom && $dom ne "");
    }

    # Attempt to locate FQDN

    foreach (@hosts) {
    	my @info = gethostbyname($_);

    	next unless @info;

    	# look at real name & aliases
    	foreach $site ($info[0], split(/ /,$info[1])) { 
    	    if(rindex($site,".") > 0) {

    	    	# Extract domain from FQDN

     	    	($domain = $site) =~ s/\A[^\.]+\.//; 
     	        return $domain;
    	    }
    	}
    }

    # try looking in /etc/resolv.conf

    local *RES;

    if(open(RES,"/etc/resolv.conf")) {
    	while(<RES>) {
    	    $domain = $1
    	    	if(/\A\s*(?:domain|search)\s+(\S+)/);
    	}
    	close(RES);

    	return $domain
    	    if(defined $domain);
    }

    # Look for environment variable

    $domain ||= $ENV{DOMAIN} || undef;

    if(defined $domain) {
    	$domain =~ s/[\r\n\0]+//g;
    	$domain =~ s/(\A\.+|\.+\Z)//g;
    	$domain =~ s/\.\.+/\./g;
    }

    $domain;
}

sub domainname {

    return $fqdn
    	if(defined $fqdn);

    _hostname();
    _hostdomain();

    my @host   = split(/\./, $host);
    my @domain = split(/\./, $domain);
    my @fqdn   = ();

    # Determine from @host & @domain the FQDN

    my @d = @domain;
 
LOOP:
    while(1) {
    	my @h = @host;
    	while(@h) {
    	    my $tmp = join(".",@h,@d);
    	    if((gethostbyname($tmp))[0]) {
     	        @fqdn = (@h,@d);
     	        $fqdn = $tmp;
     	      last LOOP;
    	    }
    	    pop @h;
    	}
    	last unless shift @d;
    }

    if(@fqdn) {
    	$host = shift @fqdn;
    	until((gethostbyname($host))[0]) {
    	    $host .= "." . shift @fqdn;
    	}
    	$domain = join(".", @fqdn);
    }
    else {
    	undef $host;
    	undef $domain;
    	undef $fqdn;
    }

    $fqdn;
}

sub hostfqdn { domainname() }

sub hostname {
    domainname()
    	unless(defined $host);
    return $host;
}

sub hostdomain {
    domainname()
    	unless(defined $domain);
    return $domain;
}

1; # Keep require happy

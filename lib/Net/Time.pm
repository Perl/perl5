# Net::Time.pm
#
# Copyright (c) 1995 Graham Barr <Graham.Barr@tiuk.ti.com>. All rights
# reserved. This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Net::Time;

=head1 NAME

Net::Time - time and daytime network client interface

=head1 SYNOPSIS

    use Net::Time qw(inet_time inet_daytime);
    
    print inet_time('localhost');
    print inet_time('localhost', 'tcp');
    
    print inet_daytime('localhost');
    print inet_daytime('localhost', 'tcp');

=head1 DESCRIPTION

C<Net::Time> provides subroutines that obtain the time on a remote machine.

=over 4

=item inet_time ( HOST [, PROTOCOL])

Obtain the time on C<HOST> using the protocol as defined in RFC868. The
optional argument C<PROTOCOL> should define the protocol to use, either
C<tcp> or C<udp>. The result will be a unix-like time value or I<undef>
upon failure.

=item inet_daytime ( HOST [, PROTOCOL])

Obtain the time on C<HOST> using the protocol as defined in RFC867. The
optional argument C<PROTOCOL> should define the protocol to use, either
C<tcp> or C<udp>. The result will be an ASCII string or I<undef>
upon failure.

=back

=head1 AUTHOR

Graham Barr <Graham.Barr@tiuk.ti.com>

=head1 REVISION

$Revision: 2.0 $

=head1 COPYRIGHT

Copyright (c) 1995 Graham Barr. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);
use Carp;
use IO::Socket;
require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(inet_time inet_daytime);

$VERSION = sprintf("%d.%02d", q$Revision: 2.0 $ =~ /(\d+)\.(\d+)/);

sub _socket
{
 my($pname,$pnum,$host,$proto) = @_;

 $proto ||= 'udp';

 my $port = (getservbyname($pname, $proto))[2] || $pnum;

 my $me = IO::Socket::INET->new(PeerAddr => $host,
    	    	    	        PeerPort => $port,
    	    	    	        Proto    => $proto
    	    	    	       );

 $me->send("\n")
    if(defined $me && $proto eq 'udp');

 $me;
}

sub inet_time
{
 my $s = _socket('time',37,@_) || return undef;
 my $buf = '';

 # the time protocol return time in seconds since 1900, convert
 # it to a unix time (seconds since 1970)

 $s->recv($buf, length(pack("N",0))) ? (unpack("N",$buf))[0] - 2208988800
    	            	    	     : undef;
}

sub inet_daytime
{
 my $s = _socket('daytime',13,@_) || return undef;
 my $buf = '';

 $s->recv($buf, 1024) ? $buf
    	              : undef;
}

1;

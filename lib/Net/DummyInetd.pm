# Net::DummyInetd.pm
#
# Copyright (c) 1995-1997 Graham Barr <gbarr@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Net::DummyInetd;

require 5.002;

use IO::Handle;
use IO::Socket;
use strict;
use vars qw($VERSION);
use Carp;

$VERSION = do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r};


sub _process
{
 my $listen = shift;
 my @cmd = @_;
 my $vec = '';
 my $r;

 vec($vec,fileno($listen),1) = 1;

 while(select($r=$vec,undef,undef,undef))
  {
   my $sock = $listen->accept;
   my $pid;

   if($pid = fork())
    {
     sleep 1;
     close($sock);
    }
   elsif(defined $pid)
    {
     my $x =  IO::Handle->new_from_fd($sock,"r");
     open(STDIN,"<&=".fileno($x)) || die "$! $@";
     close($x);

     my $y = IO::Handle->new_from_fd($sock,"w");
     open(STDOUT,">&=".fileno($y)) || die "$! $@";
     close($y);

     close($sock);
     exec(@cmd) || carp "$! $@";
    }
   else
    {
     close($sock);
     carp $!;
    }
  }
 exit -1; 
}

sub new
{
 my $self = shift;
 my $type = ref($self) || $self;

 my $listen = IO::Socket::INET->new(Listen => 5, Proto => 'tcp');
 my $pid;

 return bless [ $listen->sockport, $pid ]
	if($pid = fork());

 _process($listen,@_);
}

sub port
{
 my $self = shift;
 $self->[0];
}

sub DESTROY
{
 my $self = shift;
 kill 9, $self->[1];
}

1;

__END__

=head1 NAME

Net::DummyInetd - A dummy Inetd server

=head1 SYNOPSIS

    use Net::DummyInetd;
    use Net::SMTP;
    
    $inetd = new Net::DummyInetd qw(/usr/lib/sendmail -ba -bs);
    
    $smtp  = Net::SMTP->new('localhost', Port => $inetd->port);

=head1 DESCRIPTION

C<Net::DummyInetd> is just what its name says, it is a dummy inetd server.
Creation of a C<Net::DummyInetd> will cause a child process to be spawned off
which will listen to a socket. When a connection arrives on this socket
the specified command is fork'd and exec'd with STDIN and STDOUT file
descriptors duplicated to the new socket.

This package was added as an example of how to use C<Net::SMTP> to connect
to a C<sendmail> process, which is not the default, via SIDIN and STDOUT.
A C<Net::Inetd> package will be available in the next release of C<libnet>

=head1 CONSTRUCTOR

=over 4

=item new ( CMD )

Creates a new object and spawns a child process which listens to a socket.
C<CMD> is a list, which will be passed to C<exec> when a new process needs
to be created.

=back

=head1 METHODS

=over 4

=item port

Returns the port number on which the I<DummyInetd> object is listening

=back

=head1 AUTHOR

Graham Barr <gbarr@pobox.com>

=head1 COPYRIGHT

Copyright (c) 1995-1997 Graham Barr. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

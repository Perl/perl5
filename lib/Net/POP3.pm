# Net::POP3.pm
#
# Copyright (c) 1995 Graham Barr <Graham.Barr@tiuk.ti.com>. All rights
# reserved. This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Net::POP3;

=head1 NAME

Net::POP3 - Post Office Protocol 3 Client class (RFC1081)

=head1 SYNOPSIS

    use Net::POP3;
    
    # Constructors
    $pop = Net::POP3->new('pop3host');
    $pop = Net::POP3->new('pop3host', Timeout => 60);

=head1 DESCRIPTION

This module implements a client interface to the POP3 protocol, enabling
a perl5 application to talk to POP3 servers. This documentation assumes
that you are familiar with the POP3 protocol described in RFC1081.

A new Net::POP3 object must be created with the I<new> method. Once
this has been done, all POP3 commands are accessed via method calls
on the object.

=head1 EXAMPLES

    Need some small examples in here :-)

=head1 CONSTRUCTOR

=over 4

=item new ( HOST, [ OPTIONS ] )

This is the constructor for a new Net::POP3 object. C<HOST> is the
name of the remote host to which a POP3 connection is required.

C<OPTIONS> are passed in a hash like fasion, using key and value pairs.
Possible options are:

B<Timeout> - Maximum time, in seconds, to wait for a response from the
POP3 server (default: 120)

B<Debug> - Enable debugging information

=back

=head1 METHODS

Unless otherwise stated all methods return either a I<true> or I<false>
value, with I<true> meaning that the operation was a success. When a method
states that it returns a value, falure will be returned as I<undef> or an
empty list.

=over 4

=item user ( USER )

Send the USER command.

=item pass ( PASS )

Send the PASS command. Returns the number of messages in the mailbox.

=item login ( [ USER [, PASS ]] )

Send both the the USER and PASS commands. If C<PASS> is not given the
C<Net::POP3> uses C<Net::Netrc> to lookup the password using the host
and username. If the username is not specified then the current user name
will be used.

Returns the number of messages in the mailbox.

=item top ( MSGNUM [, NUMLINES ] )

Get the header and the first C<NUMLINES> of the body for the message
C<MSGNUM>. Returns a reference to an array which contains the lines of text
read from the server.

=item list ( [ MSGNUM ] )

If called with an argument the C<list> returns the size of the messsage
in octets.

If called without arguments the a refererence to a hash is returned. The
keys will be the C<MSGNUM>'s of all undeleted messages and the values will
be their size in octets.

=item get ( MSGNUM )

Get the message C<MSGNUM> from the remote mailbox. Returns a reference to an
array which contains the lines of text read from the server.

=item last ()

Returns the highest C<MSGNUM> of all the messages accessed.

=item popstat ()

Returns an array of two elements. These are the number of undeleted
elements and the size of the mbox in octets.

=item delete ( MSGNUM )

Mark message C<MSGNUM> to be deleted from the remote mailbox. All messages
that are marked to be deleted will be removed from the remote mailbox
when the server connection closed.

=item reset ()

Reset the status of the remote POP3 server. This includes reseting the
status of all messages to not be deleted.

=item quit ()

Quit and close the connection to the remote POP3 server. Any messages marked
as deleted will be deleted from the remote mailbox.

=back

=head1 NOTES

If a C<Net::POP3> object goes out of scope before C<quit> method is called
then the C<reset> method will called before the connection is closed. This
means that any messages marked to be deleted will not be.

=head1 SEE ALSO

L<Net::Netrc>
L<Net::Cmd>

=head1 AUTHOR

Graham Barr <Graham.Barr@tiuk.ti.com>

=head1 REVISION

$Revision: 2.1 $
$Date: 1996/07/26 06:44:44 $

The VERSION is derived from the revision by changing each number after the
first dot into a 2 digit number so

	Revision 1.8   => VERSION 1.08
	Revision 1.2.3 => VERSION 1.0203

=head1 COPYRIGHT

Copyright (c) 1995 Graham Barr. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

use strict;
use IO::Socket;
use vars qw(@ISA $VERSION $debug);
use Net::Cmd;
use Carp;

$VERSION = do{my @r=(q$Revision: 2.1 $=~/(\d+)/g);sprintf "%d."."%02d"x$#r,@r};

@ISA = qw(Net::Cmd IO::Socket::INET);

sub new
{
 my $self = shift;
 my $type = ref($self) || $self;
 my $host = shift;
 my %arg  = @_; 
 my $obj = $type->SUPER::new(PeerAddr => $host, 
			     PeerPort => $arg{Port} || 'pop3(110)',
			     Proto    => 'tcp',
			     Timeout  => defined $arg{Timeout}
						? $arg{Timeout}
						: 120
			    ) or return undef;

 ${*$obj}{'net_pop3_host'} = $host;

 $obj->autoflush(1);
 $obj->debug(exists $arg{Debug} ? $arg{Debug} : undef);

 unless ($obj->response() == CMD_OK)
  {
   $obj->close();
   return undef;
  }

 $obj;
}

##
## We don't want people sending me their passwords when they report problems
## now do we :-)
##

sub debug_text { $_[2] =~ /^(pass|rpop)/i ? "$1 ....\n" : $_[2]; }

sub login
{
 @_ >= 1 && @_ <= 3 or croak 'usage: $pop3->login( USER, PASS )';
 my($me,$user,$pass) = @_;

 if(@_ < 2)
  {
   require Net::Netrc;

   $user ||= (getpwuid($>))[0];

   my $m = Net::Netrc->lookup(${*$me}{'net_pop3_host'},$user);

   $m ||= Net::Netrc->lookup(${*$me}{'net_pop3_host'});

   $pass = $m ? $m->password || ""
              : "";
  }

 $me->user($user) and
    $me->pass($pass);
}

sub user
{
 @_ == 2 or croak 'usage: $pop3->user( USER )';
 $_[0]->_USER($_[1]);
}

sub pass
{
 @_ == 2 or croak 'usage: $pop3->pass( PASS )';

 my($me,$pass) = @_;

 return undef
   unless($me->_PASS($pass));

 $me->message =~ /(\d+)\s+message/io;

 ${*$me}{'net_pop3_count'} = $1 || 0;
}

sub reset
{
 @_ == 1 or croak 'usage: $obj->reset()';

 my $me = shift;

 return 0 
   unless($me->_RSET);
  
 if(defined ${*$me}{'net_pop3_mail'})
  {
   local $_;
   foreach (@{${*$me}{'net_pop3_mail'}})
    {
     delete $_->{'net_pop3_deleted'};
    }
  }
}

sub last
{
 @_ == 1 or croak 'usage: $obj->last()';

 return undef
    unless $_[0]->_LAST && $_[0]->message =~ /(\d+)/;

 return $1;
}

sub top
{
 @_ == 2 || @_ == 3 or croak 'usage: $pop3->top( MSGNUM [, NUMLINES ])';
 my $me = shift;

 return undef
    unless $me->_TOP($_[0], $_[1] || 0);

 $me->read_until_dot;
}

sub popstat
{
 @_ == 1 or croak 'usage: $pop3->popstat()';
 my $me = shift;

 return ()
    unless $me->_STAT && $me->message =~ /(\d+)\D+(\d+)/;

 ($1 || 0, $2 || 0);
}

sub list
{
 @_ == 1 || @_ == 2 or croak 'usage: $pop3->list( [ MSGNUM ] )';
 my $me = shift;

 return undef
    unless $me->_LIST(@_);

 if(@_)
  {
   $me->message =~ /\d+\D+(\d+)/;
   return $1 || undef;
  }
 
 my $info = $me->read_until_dot;
 my %hash = ();
 map { /(\d+)\D+(\d+)/; $hash{$1} = $2; } @$info;

 return \%hash;
}

sub get
{
 @_ == 2 or croak 'usage: $pop3->get( MSGNUM )';
 my $me = shift;

 return undef
    unless $me->_RETR(@_);

 $me->read_until_dot;
}

sub delete
{
 @_ == 2 or croak 'usage: $pop3->delete( MSGNUM )';
 $_[0]->_DELE($_[1]);
}

sub _USER { shift->command('USER',$_[0])->response() == CMD_OK }
sub _PASS { shift->command('PASS',$_[0])->response() == CMD_OK }
sub _RPOP { shift->command('RPOP',$_[0])->response() == CMD_OK }
sub _RETR { shift->command('RETR',$_[0])->response() == CMD_OK }
sub _DELE { shift->command('DELE',$_[0])->response() == CMD_OK }
sub _TOP  { shift->command('TOP', @_)->response() == CMD_OK }
sub _LIST { shift->command('LIST',@_)->response() == CMD_OK }
sub _NOOP { shift->command('NOOP')->response() == CMD_OK }
sub _RSET { shift->command('RSET')->response() == CMD_OK }
sub _LAST { shift->command('LAST')->response() == CMD_OK }
sub _QUIT { shift->command('QUIT')->response() == CMD_OK }
sub _STAT { shift->command('STAT')->response() == CMD_OK }

sub close
{
 my $me = shift;

 return 1
   unless (ref($me) && defined fileno($me));

 $me->_QUIT && $me->SUPER::close;
}

sub quit    { shift->close }

sub DESTROY
{
 my $me = shift;

 if(fileno($me))
  {
   $me->reset;
   $me->quit;
  }
}

##
## POP3 has weird responses, so we emulate them to look the same :-)
##

sub response
{
 my $cmd = shift;
 my $str = $cmd->getline() || return undef;
 my $code = "500";

 $cmd->debug_print(0,$str)
   if ($cmd->debug);

 if($str =~ s/^\+OK\s+//io)
  {
   $code = "200"
  }
 else
  {
   $str =~ s/^\+ERR\s+//io;
  }

 ${*$cmd}{'net_cmd_resp'} = [ $str ];
 ${*$cmd}{'net_cmd_code'} = $code;

 substr($code,0,1);
}

1;

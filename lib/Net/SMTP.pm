# Net::SMTP.pm
#
# Copyright (c) 1995 Graham Barr <Graham.Barr@tiuk.ti.com>. All rights
# reserved. This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Net::SMTP;

=head1 NAME

Net::SMTP - Simple Mail transfer Protocol Client

=head1 SYNOPSIS

    use Net::SMTP;
    
    # Constructors
    $smtp = Net::SMTP->new('mailhost');
    $smtp = Net::SMTP->new('mailhost', Timeout => 60);

=head1 DESCRIPTION

This module implements a client interface to the SMTP protocol, enabling
a perl5 application to talk to SMTP servers. This documentation assumes
that you are familiar with the SMTP protocol described in RFC821.

A new Net::SMTP object must be created with the I<new> method. Once
this has been done, all SMTP commands are accessed through this object.

=head1 EXAMPLES

This example prints the mail domain name of the SMTP server known as mailhost:

    #!/usr/local/bin/perl -w
    
    use Net::SMTP;
    
    $smtp = Net::SMTP->new('mailhost');
    
    print $smtp->domain,"\n";
    
    $smtp->quit;

This example sends a small message to the postmaster at the SMTP server
known as mailhost:

    #!/usr/local/bin/perl -w
    
    use Net::SMTP;
    
    $smtp = Net::SMTP->new('mailhost');
    
    $smtp->mail($ENV{USER});
    
    $smtp->to('postmaster');
    
    $smtp->data();
    
    $smtp->datasend("To: postmaster\n");
    $smtp->datasend("\n");
    $smtp->datasend("A simple test message\n");
    
    $smtp->dataend();
    
    $smtp->quit;

=head1 CONSTRUCTOR

=over 4

=item new ( HOST, [ OPTIONS ] )

This is the constructor for a new Net::SMTP object. C<HOST> is the
name of the remote host to which a SMTP connection is required.

C<OPTIONS> are passed in a hash like fasion, using key and value pairs.
Possible options are:

B<Hello> - SMTP requires that you identify yourself. This option
specifies a string to pass as your mail domain. If not
given a guess will be taken.

B<Timeout> - Maximum time, in seconds, to wait for a response from the
SMTP server (default: 120)

B<Debug> - Enable debugging information


Example:


    $smtp = Net::SMTP->new('mailhost',
			   Hello => 'my.mail.domain'
			  );

=head1 METHODS

Unless otherwise stated all methods return either a I<true> or I<false>
value, with I<true> meaning that the operation was a success. When a method
states that it returns a value, falure will be returned as I<undef> or an
empty list.

=over 4

=item domain ()

Returns the domain that the remote SMTP server identified itself as during
connection.

=item hello ( DOMAIN )

Tell the remote server the mail domain which you are in using the HELO
command.

=item mail ( ADDRESS )

=item send ( ADDRESS )

=item send_or_mail ( ADDRESS )

=item send_and_mail ( ADDRESS )

Send the appropriate command to the server MAIL, SEND, SOML or SAML. C<ADDRESS>
is the address of the sender. This initiates the sending of a message. The
method C<recipient> should be called for each address that the message is to
be sent to.

=item reset ()

Reset the status of the server. This may be called after a message has been 
initiated, but before any data has been sent, to cancel the sending of the
message.

=item recipient ( ADDRESS [, ADDRESS [ ...]] )

Notify the server that the current message should be sent to all of the
addresses given. Each address is sent as a separate command to the server.
Should the sending of any address result in a failure then the
process is aborted and a I<false> value is returned. It is up to the
user to call C<reset> if they so desire.

=item to ()

A synonym for recipient

=item data ( [ DATA ] )

Initiate the sending of the data fro the current message. 

C<DATA> may be a reference to a list or a list. If specified the contents
of C<DATA> and a termination string C<".\r\n"> is sent to the server. And the
result will be true if the data was accepted.

If C<DATA> is not specified then the result will indicate that the server
wishes the data to be sent. The data must then be sent using the C<datasend>
and C<dataend> methods defined in C<Net::Cmd>.

=item expand ( ADDRESS )

Request the server to expand the given address Returns a reference to an array
which contains the text read from the server.

=item verify ( ADDRESS )

Verify that C<ADDRESS> is a legitimate mailing address.

=item help ( [ $subject ] )

Request help text from the server. Returns the text or undef upon failure

=item quit ()

Send the QUIT command to the remote SMTP server and close the socket connection.

=back

=head1 SEE ALSO

L<Net::Cmd>

=head1 AUTHOR

Graham Barr <Graham.Barr@tiuk.ti.com>

=head1 REVISION

$Revision: 2.1 $
$Date: 1996/08/20 20:23:56 $

The VERSION is derived from the revision by changing each number after the
first dot into a 2 digit number so

	Revision 1.8   => VERSION 1.08
	Revision 1.2.3 => VERSION 1.0203

=head1 COPYRIGHT

Copyright (c) 1995 Graham Barr. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

require 5.001;

use strict;
use vars qw($VERSION @ISA);
use Socket 1.3;
use Carp;
use IO::Socket;
use Net::Cmd;

$VERSION = do{my @r=(q$Revision: 2.1 $=~/(\d+)/g);sprintf "%d."."%02d"x$#r,@r};

@ISA = qw(Net::Cmd IO::Socket::INET);

sub new
{
 my $self = shift;
 my $type = ref($self) || $self;
 my $host = shift;
 my %arg  = @_; 
 my $obj = $type->SUPER::new(PeerAddr => $host, 
			     PeerPort => $arg{Port} || 'smtp(25)',
			     Proto    => 'tcp',
			     Timeout  => defined $arg{Timeout}
						? $arg{Timeout}
						: 120
			    ) or return undef;

 $obj->autoflush(1);

 $obj->debug(exists $arg{Debug} ? $arg{Debug} : undef);

 unless ($obj->response() == CMD_OK)
  {
   $obj->SUPER::close();
   return undef;
  }

 ${*$obj}{'net_smtp_host'} = $host;

 (${*$obj}{'net_smtp_domain'}) = $obj->message =~ /\A\s*(\S+)/;

 $obj->hello($arg{Hello} || "");

 $obj;
}

##
## User interface methods
##

sub domain
{
 my $me = shift;

 return ${*$me}{'net_smtp_domain'} || undef;
}

sub hello
{
 my $me = shift;
 my $domain = shift ||
	      eval {
		    require Net::Domain;
		    Net::Domain::hostdomain();
		   } ||
		"";
 my $ok = $me->_EHLO($domain);
 my $msg;

 if($ok)
  {
   $msg = $me->message;

   my $h = ${*$me}{'net_smtp_esmtp'} = {};
   my $ext;
   foreach $ext (qw(8BITMIME CHECKPOINT DSN SIZE))
    {
     $h->{$ext} = 1
	if $msg =~ /\b${ext}\b/;
    }
  }
 else
  {
   $msg = $me->message
	if $me->_HELO($domain);
  }

 $ok && $msg =~ /\A(\S+)/
	? $1
	: undef;
}

sub _addr
{
 my $addr = shift || "";

 return $1
    if $addr =~ /(<[^>]+>)/so;

 $addr =~ s/\n/ /sog;
 $addr =~ s/(\A\s+|\s+\Z)//sog;

 return "<" . $addr . ">";
}


sub mail
{
 my $me = shift;
 my $addr = _addr(shift);
 my $opts = "";

 if(@_)
  {
   my %opt = @_;
   my($k,$v);

   if(exists ${*$me}{'net_smtp_esmtp'})
    {
     my $esmtp = ${*$me}{'net_smtp_esmtp'};

     if(defined($v = delete $opt{Size}))
      {
       if(exists $esmtp->{SIZE})
        {
         $opts .= sprintf " SIZE=%d", $v + 0
        }
       else
        {
	 carp 'Net::SMTP::mail: SIZE option not supported by host';
        }
      }

     if(defined($v = delete $opt{Return}))
      {
       if(exists $esmtp->{DSN})
        {
	 $opts .= " RET=" . uc $v
        }
       else
        {
	 carp 'Net::SMTP::mail: DSN option not supported by host';
        }
      }

     if(defined($v = delete $opt{Bits}))
      {
       if(exists $esmtp->{'8BITMIME'})
        {
	 $opts .= $v == 8 ? " BODY=8BITMIME" : " BODY=7BIT"
        }
       else
        {
	 carp 'Net::SMTP::mail: 8BITMIME option not supported by host';
        }
      }

     if(defined($v = delete $opt{Transaction}))
      {
       if(exists $esmtp->{CHECKPOINT})
        {
	 $opts .= " TRANSID=" . _addr($v);
        }
       else
        {
	 carp 'Net::SMTP::mail: CHECKPOINT option not supported by host';
        }
      }

     if(defined($v = delete $opt{Envelope}))
      {
       if(exists $esmtp->{DSN})
        {
	 $v =~ s/([^\041-\176]|=|\+)/sprintf "+%02x", ord($1)/sge;
	 $opts .= " ENVID=$v"
        }
       else
        {
	 carp 'Net::SMTP::mail: DSN option not supported by host';
        }
      }

     carp 'Net::SMTP::recipient: unknown option(s) '
		. join(" ", keys %opt)
		. ' - ignored'
	if scalar keys %opt;
    }
   else
    {
     carp 'Net::SMTP::mail: ESMTP not supported by host - options discarded :-(';
    }
  }

 $me->_MAIL("FROM:".$addr.$opts);
}

sub send	  { shift->_SEND("FROM:" . _addr($_[0])) }
sub send_or_mail  { shift->_SOML("FROM:" . _addr($_[0])) }
sub send_and_mail { shift->_SAML("FROM:" . _addr($_[0])) }

sub reset
{
 my $me = shift;

 $me->dataend()
	if(exists ${*$me}{'net_smtp_lastch'});

 $me->_RSET();
}


sub recipient
{
 my $smtp = shift;
 my $ok = 1;
 my $opts = "";

 if(@_ && ref($_[-1]))
  {
   my %opt = %{pop(@_)};
   my $v;

   if(exists ${*$smtp}{'net_smtp_esmtp'})
    {
     my $esmtp = ${*$smtp}{'net_smtp_esmtp'};

     if(defined($v = delete $opt{Notify}))
      {
       if(exists $esmtp->{DSN})
        {
	 $opts .= " NOTIFY=" . join(",",map { uc $_ } @$v)
        }
       else
        {
	 carp 'Net::SMTP::recipient: DSN option not supported by host';
        }
      }

     carp 'Net::SMTP::recipient: unknown option(s) '
		. join(" ", keys %opt)
		. ' - ignored'
	if scalar keys %opt;
    }
   else
    {
     carp 'Net::SMTP::recipient: ESMTP not supported by host - options discarded :-(';
    }
  }

 while($ok && scalar(@_))
  {
   $ok = $smtp->_RCPT("TO:" . _addr(shift) . $opts);
  }

 return $ok;
}

*to = \&recipient;

sub data
{
 my $me = shift;

 my $ok = $me->_DATA() && $me->datasend(@_);

 $ok && @_ ? $me->dataend
	   : $ok;
}

sub expand
{
 my $me = shift;

 $me->_EXPN(@_) ? ($me->message)
		: ();
}


sub verify { shift->_VRFY(@_) }

sub help
{
 my $me = shift;

 $me->_HELP(@_) ? scalar $me->message
	        : undef;
}

sub close
{
 my $me = shift;

 return 1
   unless (ref($me) && defined fileno($me));

 $me->_QUIT && $me->SUPER::close;
}

sub DESTROY { shift->close }
sub quit    { shift->close }

##
## RFC821 commands
##

sub _EHLO { shift->command("EHLO", @_)->response()  == CMD_OK }   
sub _HELO { shift->command("HELO", @_)->response()  == CMD_OK }   
sub _MAIL { shift->command("MAIL", @_)->response()  == CMD_OK }   
sub _RCPT { shift->command("RCPT", @_)->response()  == CMD_OK }   
sub _SEND { shift->command("SEND", @_)->response()  == CMD_OK }   
sub _SAML { shift->command("SAML", @_)->response()  == CMD_OK }   
sub _SOML { shift->command("SOML", @_)->response()  == CMD_OK }   
sub _VRFY { shift->command("VRFY", @_)->response()  == CMD_OK }   
sub _EXPN { shift->command("EXPN", @_)->response()  == CMD_OK }   
sub _HELP { shift->command("HELP", @_)->response()  == CMD_OK }   
sub _RSET { shift->command("RSET")->response()	    == CMD_OK }   
sub _NOOP { shift->command("NOOP")->response()	    == CMD_OK }   
sub _QUIT { shift->command("QUIT")->response()	    == CMD_OK }   
sub _DATA { shift->command("DATA")->response()	    == CMD_MORE } 
sub _TURN { shift->unsupported(@_); } 			   	  

1;


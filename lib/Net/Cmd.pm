# Net::Cmd.pm
#
# Copyright (c) 1995 Graham Barr <Graham.Barr@tiuk.ti.com>. All rights
# reserved. This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Net::Cmd;

=head1 NAME

Net::Cmd - Network Command class (as used by FTP, SMTP etc)

=head1 SYNOPSIS

    use Net::Cmd;
    
    @ISA = qw(Net::Cmd);

=head1 DESCRIPTION

C<Net::Cmd> is a collection of methods that can be inherited by a sub class
of C<IO::Handle>. These methods implement the functionality required for a
command based protocol, for example FTP and SMTP.

=head1 USER METHODS

These methods provide a user interface to the C<Net::Cmd> object.

=over 4

=item debug ( VALUE )

Set the level of debug information for this object. If C<VALUE> is not given
then the current state is returned. Otherwise the state is changed to 
C<VALUE> and the previous state returned. If C<VALUE> is C<undef> then
the debug level will be set to the default debug level for the class.

This method can also be called as a I<static> method to set/get the default
debug level for a given class.

=item message ()

Returns the text message returned from the last command

=item code ()

Returns the 3-digit code from the last command. If a command is pending
then the value 0 is returned

=item ok ()

Returns non-zero if the last code value was greater than zero and
less than 400. This holds true for most command servers. Servers
where this does not hold may override this method.

=item status ()

Returns the most significant digit of the current status code. If a command
is pending then C<CMD_PENDING> is returned.

=item datasend ( DATA )

Send data to the remote server, delimiting lines with CRLF. Any lin starting
with a '.' will be prefixed with another '.'.

=item dataend ()

End the sending of data to the remote server. This is done by ensureing that
the data already sent ends with CRLF then sending '.CRLF' to end the
transmission. Once this data has been sent C<dataend> calls C<response> and
returns true if C<response> returns CMD_OK.

=back

=head1 CLASS METHODS

These methods are not intended to be called by the user, but used or 
over-ridden by a sub-class of C<Net::Cmd>

=over 4

=item debug_print ( DIR, TEXT )

Print debugging information. C<DIR> denotes the direction I<true> being
data being sent to the server. Calls C<debug_text> before printing to
STDERR.

=item debug_text ( TEXT )

This method is called to print debugging information. TEXT is
the text being sent. The method should return the text to be printed

This is primarily meant for the use of modules such as FTP where passwords
are sent, but we do not want to display them in the debugging information.

=item command ( CMD [, ARGS, ... ])

Send a command to the command server. All arguments a first joined with
a space character and CRLF is appended, this string is then sent to the
command server.

Returns undef upon failure

=item unsupported ()

Sets the status code to 580 and the response text to 'Unsupported command'.
Returns zero.

=item responce ()

Obtain a responce from the server. Upon success the most significant digit
of the status code is returned. Upon failure, timeout etc., I<undef> is
returned.

=item parse_response ( TEXT )

This method is called by C<response> as a method with one argument. It should
return an array of 2 values, the 3-digit status code and a flag which is true
when this is part of a multi-line response and this line is not the list.

=item getline ()

Retreive one line, delimited by CRLF, from the remote server. Returns I<undef>
upon failure.

B<NOTE>: If you do use this method for any reason, please remember to add
some C<debug_print> calls into your method.

=item ungetline ( TEXT )

Unget a line of text from the server.

=item read_until_dot ()

Read data from the remote server until a line consisting of a single '.'.
Any lines starting with '..' will have one of the '.'s removed.

Returns a reference to a list containing the lines, or I<undef> upon failure.

=back

=head1 EXPORTS

C<Net::Cmd> exports six subroutines, five of these, C<CMD_INFO>, C<CMD_OK>,
C<CMD_MORE>, C<CMD_REJECT> and C<CMD_ERROR> ,correspond to possible results
of C<response> and C<status>. The sixth is C<CMD_PENDING>.

=head1 AUTHOR

Graham Barr <Graham.Barr@tiuk.ti.com>

=head1 REVISION

$Revision: 2.2 $

=head1 COPYRIGHT

Copyright (c) 1995 Graham Barr. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

require 5.001;
require Exporter;

use strict;
use vars qw(@ISA @EXPORT $VERSION);
use Carp;

$VERSION = sprintf("%d.%02d", q$Revision: 2.2 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);
@EXPORT  = qw(CMD_INFO CMD_OK CMD_MORE CMD_REJECT CMD_ERROR CMD_PENDING);

sub CMD_INFO	{ 1 }
sub CMD_OK	{ 2 }
sub CMD_MORE	{ 3 }
sub CMD_REJECT	{ 4 }
sub CMD_ERROR	{ 5 }
sub CMD_PENDING { 0 }

my %debug = ();

sub _print_isa
{
 no strict qw(refs);

 my $pkg = shift;
 my $cmd = $pkg;

 $debug{$pkg} ||= 0;

 my %done = ();
 my @do   = ($pkg);
 my %spc = ( $pkg , "");

 print STDERR "\n";
 while ($pkg = shift @do)
  {
   next if defined $done{$pkg};

   $done{$pkg} = 1;

   my $v = defined ${"${pkg}::VERSION"}
                ? "(" . ${"${pkg}::VERSION"} . ")"
                : "";

   my $spc = $spc{$pkg};
   print STDERR "$cmd: ${spc}${pkg}${v}\n";

   if(defined @{"${pkg}::ISA"})
    {
     @spc{@{"${pkg}::ISA"}} = ("  " . $spc{$pkg}) x @{"${pkg}::ISA"};
     unshift(@do, @{"${pkg}::ISA"});
    }
  }

 print STDERR "\n";
}

sub debug
{
 @_ == 1 or @_ == 2 or croak 'usage: $obj->debug([LEVEL])';

 my($cmd,$level) = @_;
 my $pkg = ref($cmd) || $cmd;
 my $oldval = 0;

 if(ref($cmd))
  {
   $oldval = ${*$cmd}{'net_cmd_debug'} || 0;
  }
 else
  {
   $oldval = $debug{$pkg} || 0;
  }

 return $oldval
    unless @_ == 2;

 $level = $debug{$pkg} || 0
    unless defined $level;

 _print_isa($pkg)
    if($level && !exists $debug{$pkg});

 if(ref($cmd))
  {
   ${*$cmd}{'net_cmd_debug'} = $level;
  }
 else
  {
   $debug{$pkg} = $level;
  }

 $oldval;
}

sub message
{
 @_ == 1 or croak 'usage: $obj->message()';

 my $cmd = shift;

 wantarray ? @{${*$cmd}{'net_cmd_resp'}}
    	   : join("", @{${*$cmd}{'net_cmd_resp'}});
}

sub debug_text { $_[2] }

sub debug_print
{
 my($cmd,$out,$text) = @_;
 print STDERR $cmd,($out ? '>>> ' : '<<< '), $cmd->debug_text($out,$text);
}

sub code
{
 @_ == 1 or croak 'usage: $obj->code()';

 my $cmd = shift;

 ${*$cmd}{'net_cmd_code'};
}

sub status
{
 @_ == 1 or croak 'usage: $obj->code()';

 my $cmd = shift;

 substr(${*$cmd}{'net_cmd_code'},0,1);
}

sub set_status
{
 @_ == 3 or croak 'usage: $obj->set_status( CODE, MESSAGE)';

 my $cmd = shift;

 (${*$cmd}{'net_cmd_code'},${*$cmd}{'net_cmd_resp'}) = @_;

 1;
}

sub command
{
 my $cmd = shift;

 $cmd->dataend()
    if(exists ${*$cmd}{'net_cmd_lastch'});

 if (scalar(@_))
  {
   my $str = join(" ", @_) . "\015\012";

   syswrite($cmd,$str,length $str);

   $cmd->debug_print(1,$str)
	if($cmd->debug);

   ${*$cmd}{'net_cmd_resp'} = [];	# the responce
   ${*$cmd}{'net_cmd_code'} = "000";	# Made this one up :-)
  }

 $cmd;
}

sub ok
{
 @_ == 1 or croak 'usage: $obj->ok()';

 my $code = $_[0]->code;
 0 < $code && $code < 400;
}

sub unsupported
{
 my $cmd = shift;

 ${*$cmd}{'net_cmd_resp'} = [ 'Unsupported command' ];
 ${*$cmd}{'net_cmd_code'} = 580;
 0;
}

sub getline
{
 my $cmd = shift;

 ${*$cmd}{'net_cmd_lines'} ||= [];

 return shift @{${*$cmd}{'net_cmd_lines'}}
    if scalar(@{${*$cmd}{'net_cmd_lines'}});

 my $partial = ${*$cmd}{'net_cmd_partial'} || "";

 my $rin = "";
 vec($rin,fileno($cmd),1) = 1;

 my $buf;

 until(scalar(@{${*$cmd}{'net_cmd_lines'}}))
  {
   my $timeout = $cmd->timeout || undef;
   my $rout;
   if (select($rout=$rin, undef, undef, $timeout))
    {
     unless (sysread($cmd, $buf="", 1024))
      {
       carp ref($cmd) . ": Unexpected EOF on command channel";
       return undef;
      } 

     substr($buf,0,0) = $partial;	## prepend from last sysread

     my @buf = split(/\015?\012/, $buf);	## break into lines

     $partial = length($buf) == 0 || substr($buf, -1, 1) eq "\012"
		? ''
	  	: pop(@buf);

     map { $_ .= "\n" } @buf;

     push(@{${*$cmd}{'net_cmd_lines'}},@buf);

    }
   else
    {
     carp "$cmd: Timeout" if($cmd->debug);
     return undef;
    }
  }

 ${*$cmd}{'net_cmd_partial'} = $partial;

 shift @{${*$cmd}{'net_cmd_lines'}};
}

sub ungetline
{
 my($cmd,$str) = @_;

 ${*$cmd}{'net_cmd_lines'} ||= [];
 unshift(@{${*$cmd}{'net_cmd_lines'}}, $str);
}

sub parse_response
{
 return ()
    unless $_[1] =~ s/^(\d\d\d)(.)//o;
 ($1, $2 eq "-");
}

sub response
{
 my $cmd = shift;
 my($code,$more) = (undef) x 2;

 ${*$cmd}{'net_cmd_resp'} ||= [];

 while(1)
  {
   my $str = $cmd->getline();

   $cmd->debug_print(0,$str)
     if ($cmd->debug);
 
   if($str =~ s/^(\d\d\d)(.?)//o)
    {
     ($code,$more) = ($1,$2 && $2 eq "-");
    }
   elsif(!$more)
    {
     $cmd->ungetline($str);
     last;
    }

   push(@{${*$cmd}{'net_cmd_resp'}},$str);

   last unless($more);
  } 

 ${*$cmd}{'net_cmd_code'} = $code;

 substr($code,0,1);
}

sub read_until_dot
{
 my $cmd = shift;
 my $arr = [];

 while(1)
  {
   my $str = $cmd->getline();

   $cmd->debug_print(0,$str)
     if ($cmd->debug & 4);

   last if($str =~ /^\.\n/o);

   $str =~ s/^\.\././o;

   push(@$arr,$str);
  }

 $arr;
}

sub datasend
{
 my $cmd = shift;
 my $lch = exists ${*$cmd}{'net_cmd_lastch'} ? ${*$cmd}{'net_cmd_lastch'}
                                             : " ";
 my $arr = @_ == 1 && ref($_[0]) ? $_[0] : \@_;
 my $line = $lch . join("" ,@$arr);

 ${*$cmd}{'net_cmd_lastch'} = substr($line,-1,1);

 return 1
    unless length($line) > 1;

 if($cmd->debug)
  {
   my $ln = substr($line,1);
   my $b = "$cmd>>> ";
   print STDERR $b,join("\n$b",split(/\n/,$ln)),"\n";
  }

 $line =~ s/\n/\015\012/sgo;
 $line =~ s/(?=\012\.)/./sgo;
 
 my $len = length($line) - 1;

 return $len < 1 ||
	syswrite($cmd, $line, $len, 1) == $len;
}

sub dataend
{
 my $cmd = shift;

 return 1
    unless(exists ${*$cmd}{'net_cmd_lastch'});

 if(${*$cmd}{'net_cmd_lastch'} eq "\015")
  {
   syswrite($cmd,"\012",1);
   print STDERR "\n"
    if($cmd->debug);
  }
 elsif(${*$cmd}{'net_cmd_lastch'} ne "\012")
  {
   syswrite($cmd,"\015\012",2);
   print STDERR "\n"
    if($cmd->debug);
  }

 print STDERR "$cmd>>> .\n"
    if($cmd->debug);

 syswrite($cmd,".\015\012",3);

 delete ${*$cmd}{'net_cmd_lastch'};

 $cmd->response() == CMD_OK;
}

1;

# Net::FTP.pm
#
# Copyright (c) 1995 Graham Barr <Graham.Barr@tiuk.ti.com>. All rights
# reserved. This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Net::FTP;

=head1 NAME

Net::FTP - FTP Client class

=head1 SYNOPSIS

    use Net::FTP;
    
    $ftp = Net::FTP->new("some.host.name");
    $ftp->login("anonymous","me@here.there");
    $ftp->cwd("/pub");
    $ftp->get("that.file");
    $ftp->quit;

=head1 DESCRIPTION

C<Net::FTP> is a class implementing a simple FTP client in Perl as described
in RFC959

C<Net::FTP> provides methods that will perform various operations. These methods
could be split into groups depending the level of interface the user requires.

=head1 CONSTRUCTOR

=over 4

=item new (HOST [,OPTIONS])

This is the constructor for a new Net::SMTP object. C<HOST> is the
name of the remote host to which a FTP connection is required.

C<OPTIONS> are passed in a hash like fasion, using key and value pairs.
Possible options are:

B<Firewall> - The name of a machine which acts as a FTP firewall. This can be
overridden by an environment variable C<FTP_FIREWALL>. If specified, and the
given host cannot be directly connected to, then the
connection is made to the firwall machine and the string C<@hostname> is
appended to the login identifier.

B<Port> - The port number to connect to on the remote machine for the
FTP connection

B<Timeout> - Set a timeout value (defaults to 120)

B<Debug> - Debug level

B<Passive> - If set to I<true> then all data transfers will be done using 
passive mode. This is required for some I<dumb> servers.

=back

=head1 METHODS

Unless otherwise stated all methods return either a I<true> or I<false>
value, with I<true> meaning that the operation was a success. When a method
states that it returns a value, falure will be returned as I<undef> or an
empty list.

=over 4

=item login ([LOGIN [,PASSWORD [, ACCOUNT] ] ])

Log into the remote FTP server with the given login information. If
no arguments are given then the C<Net::FTP> uses the C<Net::Netrc>
package to lookup the login information for the connected host.
If no information is found then a login of I<anonymous> is used.
If no password is given and the login is I<anonymous> then the users
Email address will be used for a password.

If the connection is via a firewall then the C<authorize> method will
be called with no arguments.

=item authorize ( [AUTH [, RESP]])

This is a protocol used by some firewall ftp proxies. It is used
to authorise the user to send data out.  If both arguments are not specified
then C<authorize> uses C<Net::Netrc> to do a lookup.

=item type (TYPE [, ARGS])

This method will send the TYPE command to the remote FTP server
to change the type of data transfer. The return value is the previous
value.

=item ascii ([ARGS]) binary([ARGS]) ebcdic([ARGS]) byte([ARGS])

Synonyms for C<type> with the first arguments set correctly

B<NOTE> ebcdic and byte are not fully supported.

=item rename ( OLDNAME, NEWNAME )

Rename a file on the remote FTP server from C<OLDNAME> to C<NEWNAME>. This
is done by sending the RNFR and RNTO commands.

=item delete ( FILENAME )

Send a request to the server to delete C<FILENAME>.

=item cwd ( [ DIR ] )

Change the current working directory to C<DIR>, or / if not given.

=item cdup ()

Change directory to the parent of the current directory.

=item pwd ()

Returns the full pathname of the current directory.

=item rmdir ( DIR )

Remove the directory with the name C<DIR>.

=item mkdir ( DIR [, RECURSE ])

Create a new directory with the name C<DIR>. If C<RECURSE> is I<true> then
C<mkdir> will attempt to create all the directories in the given path.

Returns the full pathname to the new directory.

=item ls ( [ DIR ] )

Get a directory listing of C<DIR>, or the current directory.

Returns a reference to a list of lines returned from the server.

=item dir ( [ DIR ] )

Get a directory listing of C<DIR>, or the current directory in long format.

Returns a reference to a list of lines returned from the server.

=item get ( REMOTE_FILE [, LOCAL_FILE ] )

Get C<REMOTE_FILE> from the server and store locally. C<LOCAL_FILE> may be
a filename or a filehandle. If not specified the the file will be stored in
the current directory with the same leafname as the remote file.

Returns C<LOCAL_FILE>, or the generated local file name if C<LOCAL_FILE>
is not given.

=item put ( LOCAL_FILE [, REMOTE_FILE ] )

Put a file on the remote server. C<LOCAL_FILE> may be a name or a filehandle.
If C<LOCAL_FILE> is a filehandle then C<REMOTE_FILE> must be specified. If
C<REMOTE_FILE> is not specified then the file will be stored in the current
directory with the same leafname as C<LOCAL_FILE>.

Returns C<REMOTE_FILE>, or the generated remote filename if C<REMOTE_FILE>
is not given.

=item put_unique ( LOCAL_FILE [, REMOTE_FILE ] )

Same as put but uses the C<STOU> command.

Returns the name of the file on the server.

=item append ( LOCAL_FILE [, REMOTE_FILE ] )

Same as put but appends to the file on the remote server.

Returns C<REMOTE_FILE>, or the generated remote filename if C<REMOTE_FILE>
is not given.

=item unique_name ()

Returns the name of the last file stored on the server using the
C<STOU> command.

=item mdtm ( FILE )

Returns the I<modification time> of the given file

=item size ( FILE )

Returns the size in bytes for the given file.

=back

The following methods can return different results depending on
how they are called. If the user explicitly calls either
of the C<pasv> or C<port> methods then these methods will
return a I<true> or I<false> value. If the user does not
call either of these methods then the result will be a
reference to a C<Net::FTP::dataconn> based object.

=over 4

=item nlst ( [ DIR ] )

Send a C<NLST> command to the server, with an optional parameter.

=item list ( [ DIR ] )

Same as C<nlst> but using the C<LIST> command

=item retr ( FILE )

Begin the retrieval of a file called C<FILE> from the remote server.

=item stor ( FILE )

Tell the server that you wish to store a file. C<FILE> is the
name of the new file that should be created.

=item stou ( FILE )

Same as C<stor> but using the C<STOU> command. The name of the unique
file which was created on the server will be avalaliable via the C<unique_name>
method after the data connection has been closed.

=item appe ( FILE )

Tell the server that we want to append some data to the end of a file
called C<FILE>. If this file does not exist then create it.

=back

If for some reason you want to have complete control over the data connection,
this includes generating it and calling the C<response> method when required,
then the user can use these methods to do so.

However calling these methods only affects the use of the methods above that
can return a data connection. They have no effect on methods C<get>, C<put>,
C<put_unique> and those that do not require data connections.

=over 4

=item port ( [ PORT ] )

Send a C<PORT> command to the server. If C<PORT> is specified then it is sent
to the server. If not the a listen socket is created and the correct information
sent to the server.

=item pasv ()

Tell the server to go into passive mode. Returns the text that represents the
port on which the server is listening, this text is in a suitable form to
sent to another ftp server using the C<port> method.

=back

The following methods can be used to transfer files between two remote
servers, providing that these two servers can connect directly to each other.

=over 4

=item pasv_xfer ( SRC_FILE, DEST_SERVER [, DEST_FILE ] )

This method will do a file transfer between two remote ftp servers. If
C<DEST_FILE> is omitted then the leaf name of C<SRC_FILE> will be used.

=item pasv_wait ( NON_PASV_SERVER )

This method can be used to wait for a transfer to complete between a passive
server and a non-passive server. The method should be called on the passive
server with the C<Net::FTP> object for the non-passive server passed as an
argument.

=item abort ()

Abort the current data transfer.

=item quit ()

Send the QUIT command to the remote FTP server and close the socket connection.

=back

=head2 Methods for the adventurous

C<Net::FTP> inherits from C<Net::Cmd> so methods defined in C<Net::Cmd> may
be used to send commands to the remote FTP server.

=over 4

=item quot (CMD [,ARGS])

Send a command, that Net::FTP does not directly support, to the remote
server and wait for a response.

Returns most significant digit of the response code.

B<WARNING> This call should only be used on commands that do not require
data connections. Misuse of this method can hang the connection.

=back

=head1 THE dataconn CLASS

Some of the methods defined in C<Net::FTP> return an object which will
be derived from this class.The dataconn class itself is derived from
the C<IO::Socket::INET> class, so any normal IO operations can be performed.
However the following methods are defined in the dataconn class and IO should
be performed using these.

=over 4

=item read ( BUFFER, SIZE [, TIMEOUT ] )

Read C<SIZE> bytes of data from the server and place it into C<BUFFER>, also
performing any <CRLF> translation necessary. C<TIMEOUT> is optional, if not
given the the timeout value from the command connection will be used.

Returns the number of bytes read before any <CRLF> translation.

=item write ( BUFFER, SIZE [, TIMEOUT ] )

Write C<SIZE> bytes of data from C<BUFFER> to the server, also
performing any <CRLF> translation necessary. C<TIMEOUT> is optional, if not
given the the timeout value from the command connection will be used.

Returns the number of bytes written before any <CRLF> translation.

=item abort ()

Abort the current data transfer.

=item close ()

Close the data connection and get a response from the FTP server. Returns
I<true> if the connection was closed sucessfully and the first digit of
the response from the server was a '2'.

=back

=head1 AUTHOR

Graham Barr <Graham.Barr@tiuk.ti.com>

=head1 REVISION

$Revision: 2.8 $
$Date: 1996/09/05 06:53:58 $

The VERSION is derived from the revision by changing each number after the
first dot into a 2 digit number so

	Revision 1.8   => VERSION 1.08
	Revision 1.2.3 => VERSION 1.0203

=head1 SEE ALSO

L<Net::Netrc>
L<Net::Cmd>

=head1 CREDITS

Henry Gabryjelski <henryg@WPI.EDU> - for the suggestion of creating directories
recursively.

=head1 COPYRIGHT

Copyright (c) 1995 Graham Barr. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

require 5.001;

use strict;
use vars qw(@ISA $VERSION);
use Carp;

use Socket 1.3;
use IO::Socket;
use Time::Local;
use Net::Cmd;
use Net::Telnet qw(TELNET_IAC TELNET_IP TELNET_DM);

$VERSION = do{my @r=(q$Revision: 2.8 $=~/(\d+)/g);sprintf "%d."."%02d"x$#r,@r};
@ISA     = qw(Exporter Net::Cmd IO::Socket::INET);

sub new
{
 my $pkg  = shift;
 my $peer = shift;
 my %arg  = @_; 

 my $host = $peer;
 my $fire = undef;

 unless(defined inet_aton($peer))
  {
   $fire = $ENV{FTP_FIREWALL} || $arg{Firewall} || undef;
   if(defined $fire)
    {
     $peer = $fire;
     delete $arg{Port};
    }
  }

 my $ftp = $pkg->SUPER::new(PeerAddr => $peer, 
			    PeerPort => $arg{Port} || 'ftp(21)',
			    Proto    => 'tcp',
			    Timeout  => defined $arg{Timeout}
						? $arg{Timeout}
						: 120
			   ) or return undef;

 ${*$ftp}{'net_ftp_passive'} = $arg{Passive} || 0;  # Always use pasv mode
 ${*$ftp}{'net_ftp_host'}    = $host;               # Remote hostname
 ${*$ftp}{'net_ftp_type'}    = 'A';		    # ASCII/binary/etc mode

 ${*$ftp}{'net_ftp_firewall'} = $fire
    if defined $fire;

 $ftp->autoflush(1);

 $ftp->debug(exists $arg{Debug} ? $arg{Debug} : undef);

 unless ($ftp->response() == CMD_OK)
  {
   $ftp->SUPER::close();
   undef $ftp;
  }

 $ftp;
}

##
## User interface methods
##

sub quit
{
 my $ftp = shift;

 $ftp->_QUIT
    && $ftp->SUPER::close;
}

sub close
{
 my $ftp = shift;

 ref($ftp) 
    && defined fileno($ftp)
    && $ftp->quit;
}

sub DESTROY { shift->close }

sub ascii  { shift->type('A',@_); }
sub binary { shift->type('I',@_); }

sub ebcdic
{
 carp "TYPE E is unsupported, shall default to I";
 shift->type('E',@_);
}

sub byte
{
 carp "TYPE L is unsupported, shall default to I";
 shift->type('L',@_);
}

# Allow the user to send a command directly, BE CAREFUL !!

sub quot
{ 
 my $ftp = shift;
 my $cmd = shift;

 $ftp->command( uc $cmd, @_);
 $ftp->response();
}

sub mdtm
{
 my $ftp  = shift;
 my $file = shift;

 return undef
 	unless $ftp->_MDTM($file);

 my @gt = reverse ($ftp->message =~ /(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/);
 $gt[5] -= 1;
 timegm(@gt);
}

sub size
{
 my $ftp  = shift;
 my $file = shift;

 $ftp->_SIZE($file)
	? ($ftp->message =~ /(\d+)/)[0]
	: undef;
}

sub login
{
 my($ftp,$user,$pass,$acct) = @_;
 my($ok,$ruser);

 unless (defined $user)
  {
   require Net::Netrc;

   my $rc = Net::Netrc->lookup(${*$ftp}{'net_ftp_host'});

   ($user,$pass,$acct) = $rc->lpa()
	if ($rc);
  }

 $user ||= "anonymous";
 $ruser = $user;

 if(defined ${*$ftp}{'net_ftp_firewall'})
  {
   $user .= "@" . ${*$ftp}{'net_ftp_host'};
  }

 $ok = $ftp->_USER($user);

 # Some dumb firewall's don't prefix the connection messages
 $ok = $ftp->response()
	if($ok == CMD_OK && $ftp->code == 220 && $user =~ /\@/);

 if ($ok == CMD_MORE)
  {
   unless(defined $pass)
    {
     require Net::Netrc;

     my $rc = Net::Netrc->lookup(${*$ftp}{'net_ftp_host'}, $ruser);

     ($ruser,$pass,$acct) = $rc->lpa()
	if ($rc);

     $pass = "-" . (getpwuid($>))[0] . "@" 
        if (!defined $pass && $ruser =~ /^anonymous/o);
    }

   $ok = $ftp->_PASS($pass || "");
  }

 $ok = $ftp->_ACCT($acct || "")
	if ($ok == CMD_MORE);

 $ftp->authorize()
    if($ok == CMD_OK && defined ${*$ftp}{'net_ftp_firewall'});

 $ok == CMD_OK;
}

sub authorize
{
 @_ >= 1 || @_ <= 3 or croak 'usage: $ftp->authorize( [AUTH [, RESP]])';

 my($ftp,$auth,$resp) = @_;

 unless(defined $resp)
  {
   require Net::Netrc;

   $auth ||= (getpwuid($>))[0];

   my $rc = Net::Netrc->lookup(${*$ftp}{'net_ftp_firewall'}, $auth)
        || Net::Netrc->lookup(${*$ftp}{'net_ftp_firewall'});

   ($auth,$resp) = $rc->lpa()
     if($rc);
  }

 my $ok = $ftp->_AUTH($auth || "");

 $ok = $ftp->_RESP($resp || "")
	if ($ok == CMD_MORE);

 $ok == CMD_OK;
}

sub rename
{
 @_ == 3 or croak 'usage: $ftp->rename(FROM, TO)';

 my($ftp,$from,$to) = @_;

 $ftp->_RNFR($from)
    && $ftp->_RNTO($to);
}

sub type
{
 my $ftp = shift;
 my $type = shift;
 my $oldval = ${*$ftp}{'net_ftp_type'};

 return $oldval
	unless (defined $type);

 return undef
	unless ($ftp->_TYPE($type,@_));

 ${*$ftp}{'net_ftp_type'} = join(" ",$type,@_);

 $oldval;
}

sub abort
{
 my $ftp = shift;

 send($ftp,pack("CC",TELNET_IAC,TELNET_IP),0);
 send($ftp,pack("C", TELNET_IAC),MSG_OOB);
 send($ftp,pack("C", TELNET_DM),0);

 $ftp->command("ABOR");

 defined ${*$ftp}{'net_ftp_dataconn'}
    ? ${*$ftp}{'net_ftp_dataconn'}->close()
    : $ftp->response();

 $ftp->response()
    if $ftp->status == CMD_REJECT;

 $ftp->status == CMD_OK;
}

sub get
{
 my($ftp,$remote,$local,$where) = @_;

 my($loc,$len,$buf,$resp,$localfd,$data);
 local *FD;

 $localfd = ref($local) ? fileno($local)
			: undef;

 ($local = $remote) =~ s#^.*/##
	unless(defined $local);

 ${*$ftp}{'net_ftp_rest'} = $where
	if ($where);

 delete ${*$ftp}{'net_ftp_port'};
 delete ${*$ftp}{'net_ftp_pasv'};

 $data = $ftp->retr($remote) or
	return undef;

 if(defined $localfd)
  {
   $loc = $local;
  }
 else
  {
   $loc = \*FD;

   unless(($where) ? open($loc,">>$local") : open($loc,">$local"))
    {
     carp "Cannot open Local file $local: $!\n";
     $data->abort;
     return undef;
    }
  }
  if ($ftp->binary && !binmode($loc))
   {
    carp "Cannot binmode Local file $local: $!\n";
    return undef;
   }

 $buf = '';

 do
  {
   $len = $data->read($buf,1024);
  }
 while($len > 0 && syswrite($loc,$buf,$len) == $len);

 close($loc)
	unless defined $localfd;
 
 $data->close(); # implied $ftp->response

 return $local;
}

sub cwd
{
 @_ == 2 || @_ == 3 or croak 'usage: $ftp->cwd( [ DIR ] )';

 my($ftp,$dir) = @_;

 $dir ||= "/";

 $dir eq ".."
    ? $ftp->_CDUP()
    : $ftp->_CWD($dir);
}

sub cdup
{
 @_ == 1 or croak 'usage: $ftp->cdup()';
 $_[0]->_CDUP;
}

sub pwd
{
 @_ == 1 || croak 'usage: $ftp->pwd()';
 my $ftp = shift;

 $ftp->_PWD();
 $ftp->_extract_path;
}

sub rmdir
{
 @_ == 2 || croak 'usage: $ftp->rmdir( DIR )';

 $_[0]->_RMD($_[1]);
}

sub mkdir
{
 @_ == 2 || @_ == 3 or croak 'usage: $ftp->mkdir( DIR [, RECURSE ] )';

 my($ftp,$dir,$recurse) = @_;

 $ftp->_MKD($dir) || $recurse or
    return undef;

 my $path = undef;
 unless($ftp->ok)
  {
   my @path = split(m#(?=/+)#, $dir);

   $path = "";

   while(@path)
    {
     $path .= shift @path;

     $ftp->_MKD($path);
     $path = $ftp->_extract_path($path);

     # 521 means directory already exists
     last
        unless $ftp->ok || $ftp->code == 521;
    }
  }

 $ftp->_extract_path($path);
}

sub delete
{
 @_ == 2 || croak 'usage: $ftp->delete( FILENAME )';

 $_[0]->_DELE($_[1]);
}

sub put        { shift->_store_cmd("stor",@_) }
sub put_unique { shift->_store_cmd("stou",@_) }
sub append     { shift->_store_cmd("appe",@_) }

sub nlst { shift->_data_cmd("NLST",@_) }
sub list { shift->_data_cmd("LIST",@_) }
sub retr { shift->_data_cmd("RETR",@_) }
sub stor { shift->_data_cmd("STOR",@_) }
sub stou { shift->_data_cmd("STOU",@_) }
sub appe { shift->_data_cmd("APPE",@_) }

sub _store_cmd 
{
 my($ftp,$cmd,$local,$remote) = @_;
 my($loc,$sock,$len,$buf,$localfd);
 local *FD;

 $localfd = ref($local) ? fileno($local)
			: undef;

 unless(defined $remote)
  {
   croak 'Must specify remote filename with stream input'
	if defined $localfd;

   ($remote = $local) =~ s%.*/%%;
  }

 if(defined $localfd)
  {
   $loc = $local;
  }
 else
  {
   $loc = \*FD;

   unless(open($loc,"<$local"))
    {
     carp "Cannot open Local file $local: $!\n";
     return undef;
    }
   if ($ftp->binary && !binmode($loc))
    {
     carp "Cannot binmode Local file $local: $!\n";
     return undef;
    }
  }

 delete ${*$ftp}{'net_ftp_port'};
 delete ${*$ftp}{'net_ftp_pasv'};

 $sock = $ftp->_data_cmd($cmd, $remote) or 
	return undef;

 do
  {
   $len = sysread($loc,$buf="",1024);
  }
 while($len && $sock->write($buf,$len) == $len);

 close($loc)
	unless defined $localfd;

 $sock->close();

 ($remote) = $ftp->message =~ /unique file name:\s*(\S*)\s*\)/
	if ('STOU' eq uc $cmd);

 return $remote;
}

sub port
{
 @_ == 1 || @_ == 2 or croak 'usage: $ftp->port([PORT])';

 my($ftp,$port) = @_;
 my $ok;

 delete ${*$ftp}{'net_ftp_intern_port'};

 unless(defined $port)
  {
   # create a Listen socket at same address as the command socket

   ${*$ftp}{'net_ftp_listen'} ||= IO::Socket::INET->new(Listen    => 5,
				    	    	        Proto     => 'tcp',
				    	    	        LocalAddr => $ftp->sockhost, 
				    	    	       );
  
   my $listen = ${*$ftp}{'net_ftp_listen'};

   my($myport, @myaddr) = ($listen->sockport, split(/\./,$listen->sockhost));

   $port = join(',', @myaddr, $myport >> 8, $myport & 0xff);

   ${*$ftp}{'net_ftp_intern_port'} = 1;
  }

 $ok = $ftp->_PORT($port);

 ${*$ftp}{'net_ftp_port'} = $port;

 $ok;
}

sub ls  { shift->_list_cmd("NLST",@_); }
sub dir { shift->_list_cmd("LIST",@_); }

sub pasv
{
 @_ == 1 or croak 'usage: $ftp->pasv()';

 my $ftp = shift;

 delete ${*$ftp}{'net_ftp_intern_port'};

 $ftp->_PASV && $ftp->message =~ /(\d+(,\d+)+)/
    ? ${*$ftp}{'net_ftp_pasv'} = $1
    : undef;    
}

sub unique_name
{
 my $ftp = shift;
 ${*$ftp}{'net_ftp_unique'} || undef;
}

##
## Depreciated methods
##

sub lsl
{
 carp "Use of Net::FTP::lsl depreciated, use 'dir'"
    if $^W;
 goto &dir;
}

sub authorise
{
 carp "Use of Net::FTP::authorise depreciated, use 'authorize'"
    if $^W;
 goto &authorize;
}


##
## Private methods
##

sub _extract_path
{
 my($ftp, $path) = @_;

 $ftp->ok &&
    $ftp->message =~ /\s\"(.*)\"\s/o &&
    ($path = $1) =~ s/\"\"/\"/g;

 $path;
}

##
## Communication methods
##

sub _dataconn
{
 my $ftp = shift;
 my $data = undef;
 my $pkg = "Net::FTP::" . $ftp->type;

 $pkg =~ s/ /_/g;

 delete ${*$ftp}{'net_ftp_dataconn'};

 if(defined ${*$ftp}{'net_ftp_pasv'})
  {
   my @port = split(/,/,${*$ftp}{'net_ftp_pasv'});

   $data = $pkg->new(PeerAddr => join(".",@port[0..3]),
    	    	     PeerPort => $port[4] * 256 + $port[5],
    	    	     Proto    => 'tcp'
    	    	    );
  }
 elsif(defined ${*$ftp}{'net_ftp_listen'})
  {
   $data = ${*$ftp}{'net_ftp_listen'}->accept($pkg);
   close(delete ${*$ftp}{'net_ftp_listen'});
  }

 if($data)
  {
   ${*$data} = "";
   $data->timeout($ftp->timeout);
   ${*$ftp}{'net_ftp_dataconn'} = $data;
   ${*$data}{'net_ftp_cmd'} = $ftp;
  }

 $data;
}

sub _list_cmd
{
 my $ftp = shift;
 my $cmd = uc shift;

 delete ${*$ftp}{'net_ftp_port'};
 delete ${*$ftp}{'net_ftp_pasv'};

 my $data = $ftp->_data_cmd($cmd,@_);

 return undef
	unless(defined $data);

 bless $data, "Net::FTP::A"; # Force ASCII mode

 my $databuf = '';
 my $buf = '';

 while($data->read($databuf,1024))
  {
   $buf .= $databuf;
  }

 my $list = [ split(/\n/,$buf) ];

 $data->close();

 wantarray ? @{$list}
           : $list;
}

sub _data_cmd
{
 my $ftp = shift;
 my $cmd = uc shift;
 my $ok = 1;
 my $where = delete ${*$ftp}{'net_ftp_rest'} || 0;

 if(${*$ftp}{'net_ftp_passive'} &&
     !defined ${*$ftp}{'net_ftp_pasv'} &&
     !defined ${*$ftp}{'net_ftp_port'})
  {
   my $data = undef;

   $ok = defined $ftp->pasv;
   $ok = $ftp->_REST($where)
	if $ok && $where;

   if($ok)
    {
     $ftp->command($cmd,@_);
     $data = $ftp->_dataconn();
     $ok = CMD_INFO == $ftp->response();
    }
   return $ok ? $data
    	      : undef;
  }

 $ok = $ftp->port
    unless (defined ${*$ftp}{'net_ftp_port'} ||
            defined ${*$ftp}{'net_ftp_pasv'});

 $ok = $ftp->_REST($where)
    if $ok && $where;

 return undef
    unless $ok;

 $ftp->command($cmd,@_);

 return 1
    if(defined ${*$ftp}{'net_ftp_pasv'});

 $ok = CMD_INFO == $ftp->response();

 return $ok 
    unless exists ${*$ftp}{'net_ftp_intern_port'};

 $ok ? $ftp->_dataconn()
     : undef;
}

##
## Over-ride methods (Net::Cmd)
##

sub debug_text { $_[2] =~ /^(pass|resp)/i ? "$1 ....\n" : $_[2]; }

sub command
{
 my $ftp = shift;

 delete ${*$ftp}{'net_ftp_port'};
 $ftp->SUPER::command(@_);
}

sub response
{
 my $ftp = shift;
 my $code = $ftp->SUPER::response();

 delete ${*$ftp}{'net_ftp_pasv'}
    if ($code != CMD_MORE && $code != CMD_INFO);

 $code;
}

##
## Allow 2 servers to talk directly
##

sub pasv_xfer
{
 my($sftp,$sfile,$dftp,$dfile) = @_;

 ($dfile = $sfile) =~ s#.*/##
    unless(defined $dfile);

 my $port = $sftp->pasv or
    return undef;

 unless($dftp->port($port) && $sftp->retr($sfile) && $dftp->stou($dfile))
  {
   $sftp->abort;
   $dftp->abort;
   return undef;
  }

 $dftp->pasv_wait($sftp);
}

sub pasv_wait
{
 @_ == 2 or croak 'usage: $ftp->pasv_wait(NON_PASV_FTP)';

 my($ftp, $non_pasv) = @_;
 my($file,$rin,$rout);

 vec($rin,fileno($ftp),1) = 1;
 select($rout=$rin, undef, undef, undef);

 $ftp->response();
 $non_pasv->response();

 return undef
	unless $ftp->ok() && $non_pasv->ok();

 return $1
	if $ftp->message =~ /unique file name:\s*(\S*)\s*\)/;

 return $1
	if $non_pasv->message =~ /unique file name:\s*(\S*)\s*\)/;

 return 1;
}

sub cmd { shift->command(@_)->responce() }

########################################
#
# RFC959 commands
#

sub _ABOR { shift->command("ABOR")->response()	 == CMD_OK }
sub _CDUP { shift->command("CDUP")->response()	 == CMD_OK }
sub _NOOP { shift->command("NOOP")->response()	 == CMD_OK }
sub _PASV { shift->command("PASV")->response()	 == CMD_OK }
sub _QUIT { shift->command("QUIT")->response()	 == CMD_OK }
sub _DELE { shift->command("DELE",@_)->response() == CMD_OK }
sub _CWD  { shift->command("CWD", @_)->response() == CMD_OK }
sub _PORT { shift->command("PORT",@_)->response() == CMD_OK }
sub _RMD  { shift->command("RMD", @_)->response() == CMD_OK }
sub _MKD  { shift->command("MKD", @_)->response() == CMD_OK }
sub _PWD  { shift->command("PWD", @_)->response() == CMD_OK }
sub _TYPE { shift->command("TYPE",@_)->response() == CMD_OK }
sub _RNTO { shift->command("RNTO",@_)->response() == CMD_OK }
sub _ACCT { shift->command("ACCT",@_)->response() == CMD_OK }
sub _RESP { shift->command("RESP",@_)->response() == CMD_OK }
sub _MDTM { shift->command("MDTM",@_)->response() == CMD_OK }
sub _SIZE { shift->command("SIZE",@_)->response() == CMD_OK }
sub _APPE { shift->command("APPE",@_)->response() == CMD_INFO }
sub _LIST { shift->command("LIST",@_)->response() == CMD_INFO }
sub _NLST { shift->command("NLST",@_)->response() == CMD_INFO }
sub _RETR { shift->command("RETR",@_)->response() == CMD_INFO }
sub _STOR { shift->command("STOR",@_)->response() == CMD_INFO }
sub _STOU { shift->command("STOU",@_)->response() == CMD_INFO }
sub _RNFR { shift->command("RNFR",@_)->response() == CMD_MORE }
sub _REST { shift->command("REST",@_)->response() == CMD_MORE }
sub _USER { shift->command("user",@_)->response() } # A certain brain dead firewall :-)
sub _PASS { shift->command("PASS",@_)->response() }
sub _AUTH { shift->command("AUTH",@_)->response() }

sub _ALLO { shift->unsupported(@_) }
sub _SMNT { shift->unsupported(@_) }
sub _HELP { shift->unsupported(@_) }
sub _MODE { shift->unsupported(@_) }
sub _SITE { shift->unsupported(@_) }
sub _SYST { shift->unsupported(@_) }
sub _STAT { shift->unsupported(@_) }
sub _STRU { shift->unsupported(@_) }
sub _REIN { shift->unsupported(@_) }

##
## Generic data connection package
##

package Net::FTP::dataconn;

use Carp;
use vars qw(@ISA $timeout);
use Net::Cmd;

@ISA = qw(IO::Socket::INET);

sub abort
{
 my $data = shift;
 my $ftp  = ${*$data}{'net_ftp_cmd'};

 $ftp->abort; # this will close me
}

sub close
{
 my $data = shift;
 my $ftp  = ${*$data}{'net_ftp_cmd'};

 $data->SUPER::close();

 delete ${*$ftp}{'net_ftp_dataconn'}
    if exists ${*$ftp}{'net_ftp_dataconn'} &&
        $data == ${*$ftp}{'net_ftp_dataconn'};

 $ftp->response() == CMD_OK &&
    $ftp->message =~ /unique file name:\s*(\S*)\s*\)/ &&
    (${*$ftp}{'net_ftp_unique'} = $1);

 $ftp->status == CMD_OK;
}

sub _select
{
 my    $data 	= shift;
 local *timeout = \$_[0]; shift;
 my    $rw 	= shift;

 my($rin,$win);

 return 1 unless $timeout;

 $rin = '';
 vec($rin,fileno($data),1) = 1;

 $win = $rw ? undef : $rin;
 $rin = undef unless $rw;

 my $nfound = select($rin, $win, undef, $timeout);

 croak "select: $!"
	if $nfound < 0;

 return $nfound;
}

sub can_read
{
 my    $data    = shift;
 local *timeout = \$_[0];

 $data->_select($timeout,1);
}

sub can_write
{
 my    $data    = shift;
 local *timeout = \$_[0];

 $data->_select($timeout,0);
}

sub cmd
{
 my $ftp = shift;

 ${*$ftp}{'net_ftp_cmd'};
}


@Net::FTP::L::ISA = qw(Net::FTP::I);
@Net::FTP::E::ISA = qw(Net::FTP::I);

##
## Package to read/write on ASCII data connections
##

package Net::FTP::A;

use vars qw(@ISA $buf);
use Carp;

@ISA = qw(Net::FTP::dataconn);

sub read
{
 my    $data 	= shift;
 local *buf 	= \$_[0]; shift;
 my    $size 	= shift || croak 'read($buf,$size,[$offset])';
 my    $offset 	= shift || 0;
 my    $timeout = $data->timeout;

 croak "Bad offset"
	if($offset < 0);

 $offset = length $buf
	if($offset > length $buf);

 ${*$data} ||= "";
 my $l = 0;

 READ:
  {
   $data->can_read($timeout) or
	croak "Timeout";

   my $n = sysread($data, ${*$data}, $size, length ${*$data});

   return $n
	unless($n >= 0);

   ${*$data} =~ s/(\015)?(?!\012)\Z//so;
   my $lf = $1 || "";

   ${*$data} =~ s/\015\012/\n/sgo;

   substr($buf,$offset) = ${*$data};

   $l += length(${*$data});
   $offset += length(${*$data});

   ${*$data} = $lf;
   
   redo READ
     if($l == 0 && $n > 0);

   if($n == 0 && $l == 0)
    {
     substr($buf,$offset) = ${*$data};
     ${*$data} = "";
    }
  }

 return $l;
}

sub write
{
 my    $data 	= shift;
 local *buf 	= \$_[0]; shift;
 my    $size 	= shift || croak 'write($buf,$size,[$timeout])';
 my    $timeout = @_ ? shift : $data->timeout;

 $data->can_write($timeout) or
	croak "Timeout";

 # What is previous pkt ended in \015 or not ??

 my $tmp;
 ($tmp = $buf) =~ s/(?!\015)\012/\015\012/sg;

 my $len = $size + length($tmp) - length($buf);
 my $wrote = syswrite($data, $tmp, $len);

 if($wrote >= 0)
  {
   $wrote = $wrote == $len ? $size
			   : $len - $wrote
  }

 return $wrote;
}

##
## Package to read/write on BINARY data connections
##

package Net::FTP::I;

use vars qw(@ISA $buf);
use Carp;

@ISA = qw(Net::FTP::dataconn);

sub read
{
 my    $data 	= shift;
 local *buf 	= \$_[0]; shift;
 my    $size    = shift || croak 'read($buf,$size,[$timeout])';
 my    $timeout = @_ ? shift : $data->timeout;

 $data->can_read($timeout) or
	croak "Timeout";

 my $n = sysread($data, $buf, $size);

 $n;
}

sub write
{
 my    $data    = shift;
 local *buf     = \$_[0]; shift;
 my    $size    = shift || croak 'write($buf,$size,[$timeout])';
 my    $timeout = @_ ? shift : $data->timeout;

 $data->can_write($timeout) or
	croak "Timeout";

 syswrite($data, $buf, $size);
}


1;


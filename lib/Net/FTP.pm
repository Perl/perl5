;# Net::FTP.pm
;#
;# Copyright (c) 1995 Graham Barr <Graham.Barr@tiuk.ti.com>. All rights
;# reserved. This program is free software; you can redistribute it and/or
;# modify it under the same terms as Perl itself.

;#Notes
;# should I have a dataconn::close sub which calls response ??
;# FTP should hold state reguarding cmds sent
;# A::read needs some more thought
;# A::write What is previous pkt ended in \r or not ??
;# need to do some heavy tidy-ing up !!!!
;# need some documentation

package Net::FTP;

=head1 NAME

Net::FTP - FTP Client class

=head1 SYNOPSIS

 require Net::FTP;

 $ftp = Net::FTP->new("some.host.name");
 $ftp->login("anonymous","me@here.there");
 $ftp->cwd("/pub");
 $ftp->get("that.file");
 $ftp->quit;

=head1 DESCRIPTION

C<Net::FTP> is a class implementing a simple FTP client in Perl as described
in RFC959

=head2 TO BE CONTINUED ...

=cut

require 5.001;
use Socket 1.3;
use Carp;
use Net::Socket;

@ISA = qw(Net::Socket);

$VERSION = sprintf("%d.%02d", q$Revision: 1.18 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION }

use strict;

=head1 METHODS

All methods return 0 or undef upon failure

=head2 * new($host [, option => value [,...]] )

Constructor for the FTP client. It will create the connection to the
remote host. Possible options are:

 Port	 => port to use for FTP connection
 Timeout => set timeout value (defaults to 120)
 Debug	 => debug level

=cut

sub FTP_READY    { 0 } # Ready 
sub FTP_RESPONSE { 1 } # Waiting for a response
sub FTP_XFER     { 2 } # Doing data xfer

sub new {
 my $pkg  = shift;
 my $host = shift;
 my %arg  = @_; 
 my $me = bless Net::Socket->new(Peer	=> $host, 
				Service	=> 'ftp', 
				Port	=> $arg{Port} || 'ftp'
				), $pkg;

 ${*$me} = "";					# partial response text
 @{*$me} = ();					# Last response text

 %{*$me} = (%{*$me},				# Copy current values
	    Code    => 0,			# Last response code
	    Type    => 'A',			# Ascii/Binary/etc mode
	    Timeout => $arg{Timeout} || 120,	# Timeout value
	    Debug   => $arg{Debug}   || 0,	# Output debug information
	    FtpHost => $host,			# Remote hostname
	    State   => FTP_RESPONSE,		# Current state

	    ##############################################################
	    # Other elements used during the lifetime of the object are
	    #
	    # LISTEN  Listen socket
	    # DATA    Data socket
	   );

 $me->autoflush(1);

 $me->debug($arg{Debug})
   if(exists $arg{Debug});

 unless(2 == $me->response())
  {
   $me->close();
   undef $me;
  }

 $me;
}

##
## User interface methods
##

=head2 * debug( $value )

Set the level of debug information for this object. If no argument is given
then the current state is returned. Otherwise the state is changed to 
C<$value>and the previous state returned.

=cut

sub debug {
 my $me = shift;
 my $debug = ${*$me}{Debug};
 
 if(@_)
  {
   ${*$me}{Debug} = 0 + shift;

   printf STDERR "\n$me VERSION %s\n", $Net::FTP::VERSION
     if(${*$me}{Debug});
  }

 $debug;
}

=head2 quit

Send the QUIT command to the remote FTP server and close the socket connection.

=cut

sub quit {
 my $me = shift;

 return undef
	unless $me->QUIT;

 close($me);

 return 1;
}

=head2 ascii/ebcdic/binary/byte

Put the remote FTP server ant the FTP package into the given mode
of data transfer.

=cut

sub ascii  { shift->type('A',@_); }
sub ebcdic { shift->type('E',@_); }
sub binary { shift->type('I',@_); }
sub byte   { shift->type('L',@_); }

# Allow the user to send a command directly, BE CAREFUL !!

sub quot  { 
 my $me = shift;
 my $cmd = shift;

 $me->send_cmd( uc $cmd, @_);

 $me->response();
}

=head2 login([$login [, $password [, $account]]])

Log into the remote FTP server with the given login information. If
no arguments are given then the users $HOME/.netrc file is searched
for the remote server's hostname. If no information is found then
a login of I<anonymous> is used. If no password is given and the login
is anonymous then the users Email address will be used for a password

=cut

sub login {
 my $me = shift;
 my $user = shift;
 my $pass = shift if(defined $user);
 my $acct = shift if(defined $pass);
 my $ok;

 unless(defined $user)
  {
   require Net::Netrc;
   my $rc = Net::Netrc->lookup(${*$me}{FtpHost});

   ($user,$pass,$acct) = $rc->lpa()
	if $rc;
  }

 $user = "anonymous"
	unless defined $user;

 $pass = "-" . (getpwuid($>))[0] . "@" 
	if !defined $pass && $user eq "anonymous";

 $ok = $me->USER($user);

 $ok = $me->PASS($pass)
	if $ok == 3;

 $ok = $me->ACCT($acct || "")
	if $ok == 3;

 $ok == 2;
}

=head2 authorise($auth, $resp)

This is a protocol used by some firewall ftp proxies. It is used
to authorise the user to send data out.

=cut

sub authorise {
 my($me,$auth,$resp) = @_;
 my $ok;

 carp "Net::FTP::authorise <auth> <resp>\n"
	unless defined $auth && defined $resp;

 $ok = $me->AUTH($auth);

 $ok = $me->RESP($resp)
	if $ok == 3;

 $ok == 2;
}

=head2 rename( $oldname, $newname)

Rename a file on the remote FTP server from C<$oldname> to C<$newname>

=cut

sub rename {
 my($me,$from,$to) = @_;

 croak "Net::FTP:rename <from> <to>\n"
	unless defined $from && defined $to;

 $me->RNFR($from) and $me->RNTO($to);
}

sub type {
 my $me	  = shift;
 my $type = shift;
 my $ok	  = 0;

 return ${*$me}{Type}
	unless defined $type;

 return undef
	unless($me->TYPE($type,@_));

 ${*$me}{Type} = join(" ",$type,@_);
}

sub abort {
 my $me = shift;

 ${*$me}{DATA}->abort()
	if defined ${*$me}{DATA};
}

sub get {
 my $me = shift;
 my $remote = shift;
 my $local  = shift;
 my $where  = shift || 0;
 my($loc,$len,$buf,$resp,$localfd,$data);
 local *FD;

 $localfd = ref($local) ? fileno($local)
			: 0;

 ($local = $remote) =~ s#^.*/## unless(defined $local);

 if($localfd)
  {
   $loc = $local;
  }
 else
  {
   $loc = \*FD;

   unless(($where) ? open($loc,">>$local") : open($loc,">$local"))
    {
     carp "Cannot open Local file $local: $!\n";
     return undef;
    }
  }

 if ($where) {   
   $data = $me->rest_cmd($where,$remote) or
	return undef; 
 }
 else {
   $data = $me->retr($remote) or
     return undef;
 }

 $buf = '';

 do
  {
   $len = $data->read($buf,1024);
  }
 while($len > 0 && syswrite($loc,$buf,$len) == $len);

 close($loc)
	unless $localfd;
 
 $data->close() == 2; # implied $me->response
}

sub cwd {
 my $me = shift;
 my $dir = shift || "/";

 return $dir eq ".." ? $me->CDUP()
		     : $me->CWD($dir);
}

sub pwd {
 my $me = shift;

 $me->PWD() ? ($me->message =~ /\"([^\"]+)/)[0]
            : undef;
}

sub put	       { shift->send("stor",@_) }
sub put_unique { shift->send("stou",@_) }
sub append     { shift->send("appe",@_) }

sub nlst { shift->data_cmd("NLST",@_) }
sub list { shift->data_cmd("LIST",@_) }
sub retr { shift->data_cmd("RETR",@_) }
sub stor { shift->data_cmd("STOR",@_) }
sub stou { shift->data_cmd("STOU",@_) }
sub appe { shift->data_cmd("APPE",@_) }

sub send {
 my $me	    = shift;
 my $cmd    = shift;
 my $local  = shift;
 my $remote = shift;
 my($loc,$sock,$len,$buf,$localfd);
 local *FD;

 $localfd = ref($local) ? fileno($local)
			: 0;

 unless(defined $remote)
  {
   croak "Must specify remote filename with stream input\n"
	if $localfd;

   ($remote = $local) =~ s%.*/%%;
  }

 if($localfd)
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
  }

 $cmd = lc $cmd;

 $sock = $me->$cmd($remote) or
	return undef;

 do
  {
   $len = sysread($loc,$buf,1024);
  }
 while($len && $sock->write($buf,$len) == $len);

 close($loc)
	unless $localfd;

 $sock->close();

 ($remote) = $me->message =~ /unique file name:\s*(\S*)\s*\)/
	if $cmd eq 'stou' ;

 return $remote;
}

sub port {
 my $me = shift;
 my $port = shift;
 my $ok;

 unless(defined $port)
  {
   my $listen;

   if(defined ${*$me}{LISTEN})
    {
     ${*$me}{LISTEN}->close();
     delete ${*$me}{LISTEN};
    }

   # create a Listen socket at same address as the command socket

   $listen = Net::Socket->new(Listen  => 5,
			     Service => 'ftp',
			     Addr    => $me->sockhost, 
			    );
  
   ${*$me}{LISTEN} = $listen;

   my($myport, @myaddr) = ($listen->sockport, split(/\./,$listen->sockhost));

   $port = join(',', @myaddr, $myport >> 8, $myport & 0xff);
  }

 $ok = $me->PORT($port);

 ${*$me}{Port} = $port;

 $ok;
}

sub ls	{ shift->list_cmd("NLST",@_); }
sub lsl { shift->list_cmd("LIST",@_); }

sub pasv {
 my $me = shift;
 my $hostport;

 return undef
	unless $me->PASV();

 ($hostport) = $me->message =~ /(\d+(,\d+)+)/;

 ${*$me}{Pasv} = $hostport;
}

##
## Communication methods
##

sub timeout {
 my $me = shift;
 my $timeout = ${*$me}{Timeout};

 ${*$me}{Timeout} = 0 + shift if(@_);

 $timeout;
}

sub accept {
 my $me = shift;

 return undef unless defined ${*$me}{LISTEN};

 my $data = ${*$me}{LISTEN}->accept;

 ${*$me}{LISTEN}->close();
 delete ${*$me}{LISTEN};

 ${*$data}{Timeout} = ${*$me}{Timeout};
 ${*$data}{Cmd} = $me;
 ${*$data} = "";

 ${*$me}{State} = FTP_XFER;
 ${*$me}{DATA}  = bless $data, "Net::FTP::" . ${*$me}{Type};
}

sub message {
 my $me = shift;
 join("\n", @{*$me});
}

sub ok {
 my $me = shift;
 my $code = ${*$me}{Code} || 0;

 0 < $code && $code < 400;
}

sub code {
 my $me = shift;

 ${*$me}{Code};
}

sub list_cmd {
 my $me = shift;
 my $cmd = lc shift;
 my $data = $me->$cmd(@_);

 return undef
	unless(defined $data);

 bless $data, "Net::FTP::A"; # Force ASCII mode

 my $databuf = '';
 my $buf = '';

 while($data->read($databuf,1024)) {
   $buf .= $databuf;
 }

 my $list = [ split(/\n/,$buf) ];

 $data->close();

 wantarray ? @{$list} : $list;
}

sub data_cmd {
 my $me = shift;
 my $cmd = uc shift;
 my $ok = 1;
 my $pasv = defined ${*$me}{Pasv} ? 1 : 0;

 $ok = $me->port
	unless $pasv || defined ${*$me}{Port};

 $ok = $me->$cmd(@_)
	if $ok;

 return $pasv ? $ok
	      : $ok ? $me->accept()
		    : undef;
}

sub rest_cmd {
 my $me = shift;
 my $ok = 1;
 my $pasv = defined ${*$me}{Pasv} ? 1 : 0;
 my $where = shift;
 my $file = shift;

 $ok = $me->port
	unless $pasv || defined ${*$me}{Port};

 $ok = $me->REST($where)
	if $ok;

 $ok = $me->RETR($file)
	if $ok;

 return $pasv ? $ok
	      : $ok ? $me->accept()
		    : undef;
}

sub cmd {
 my $me = shift;

 $me->send_cmd(@_);
 $me->response();
}

sub send_cmd {
 my $me = shift;

 if(scalar(@_)) {     
  my $cmd = join(" ", @_) . "\r\n";

  delete ${*$me}{Pasv};
  delete ${*$me}{Port};

  syswrite($me,$cmd,length $cmd);

  ${*$me}{State} = FTP_RESPONSE;

  printf STDERR "\n$me>> %s", $cmd=~/^(pass|resp)/i ? "$1 ....\n" : $cmd
	if $me->debug;
 }

 $me;
}

sub pasv_wait {
 my $me = shift;
 my $non_pasv = shift;
 my $file;

 my($rin,$rout);
 vec($rin,fileno($me),1) = 1;
 select($rout=$rin, undef, undef, undef);

 $me->response();
 $non_pasv->response();

 return undef
	unless $me->ok() && $non_pasv->ok();

 return $1
	if $me->message =~ /unique file name:\s*(\S*)\s*\)/;

 return $1
	if $non_pasv->message =~ /unique file name:\s*(\S*)\s*\)/;

 return 1;
}

sub response {
 my $me = shift;
 my $timeout = ${*$me}{Timeout};
 my($code,$more,$rin,$rout,$partial,$buf) = (undef,0,'','','','');

 @{*$me} = (); # the responce
 $buf = ${*$me};
 my @buf = ();

 vec($rin,fileno($me),1) = 1;

 do
  {
   if(length($buf) || ($timeout==0) || select($rout=$rin, undef, undef, $timeout))
    {
     unless(length($buf) || sysread($me, $buf, 1024))
      {
       carp "Unexpected EOF on command channel";
       return undef;
      } 

     substr($buf,0,0) = $partial;    ## prepend from last sysread

     @buf = split(/\r?\n/, $buf);  ## break into lines

     $partial = (substr($buf, -1, 1) eq "\n") ? ''
					      : pop(@buf); 

     $buf = "";

     while (@buf)
      {
       my $cmd = shift @buf;
       print STDERR "$me<< $cmd\n"
	 if $me->debug;
 
       ($code,$more) = ($1,$2)
	if $cmd =~ /^(\d\d\d)(.)/;

       push(@{*$me},$');

       last unless(defined $more && $more eq "-");
      } 
    }
   else
    {
     carp "$me: Timeout" if($me->debug);
     return undef;
    }
  }
 while((scalar(@{*$me}) == 0) || (defined $more && $more eq "-"));

 ${*$me} = @buf ? join("\n",@buf,"") : "";
 ${*$me} .= $partial;

 ${*$me}{Code} = $code;
 ${*$me}{State} = FTP_READY;

 substr($code,0,1);
}

;########################################
;#
;# RFC959 commands
;#

sub no_imp { croak "Not implemented\n"; }

sub ABOR { shift->send_cmd("ABOR")->response()	== 2}
sub CDUP { shift->send_cmd("CDUP")->response()	== 2}
sub NOOP { shift->send_cmd("NOOP")->response()	== 2}
sub PASV { shift->send_cmd("PASV")->response()	== 2}
sub QUIT { shift->send_cmd("QUIT")->response()	== 2}
sub DELE { shift->send_cmd("DELE",@_)->response() == 2}
sub CWD  { shift->send_cmd("CWD", @_)->response() == 2}
sub PORT { shift->send_cmd("PORT",@_)->response() == 2}
sub RMD  { shift->send_cmd("RMD", @_)->response() == 2}
sub MKD  { shift->send_cmd("MKD", @_)->response() == 2}
sub PWD  { shift->send_cmd("PWD", @_)->response() == 2}
sub TYPE { shift->send_cmd("TYPE",@_)->response() == 2}
sub APPE { shift->send_cmd("APPE",@_)->response() == 1}
sub LIST { shift->send_cmd("LIST",@_)->response() == 1}
sub NLST { shift->send_cmd("NLST",@_)->response() == 1}
sub RETR { shift->send_cmd("RETR",@_)->response() == 1}
sub STOR { shift->send_cmd("STOR",@_)->response() == 1}
sub STOU { shift->send_cmd("STOU",@_)->response() == 1}
sub RNFR { shift->send_cmd("RNFR",@_)->response() == 3}
sub RNTO { shift->send_cmd("RNTO",@_)->response() == 2}
sub ACCT { shift->send_cmd("ACCT",@_)->response() == 2}
sub RESP { shift->send_cmd("RESP",@_)->response() == 2}
sub REST { shift->send_cmd("REST",@_)->response() == 3}
sub USER { my $ok = shift->send_cmd("USER",@_)->response();($ok == 2 || $ok == 3) ? $ok : 0;}
sub PASS { my $ok = shift->send_cmd("PASS",@_)->response();($ok == 2 || $ok == 3) ? $ok : 0;}
sub AUTH { my $ok = shift->send_cmd("AUTH",@_)->response();($ok == 2 || $ok == 3) ? $ok : 0;}

sub ALLO { no_imp; }
sub SMNT { no_imp; }
sub HELP { no_imp; }
sub MODE { no_imp; }
sub SITE { no_imp; }
sub SYST { no_imp; }
sub STAT { no_imp; }
sub STRU { no_imp; }
sub REIN { no_imp; }

package Net::FTP::dataconn;
use Carp;
no strict 'vars';

sub abort {
 my $fd = shift;
 my $ftp = ${*$fd}{Cmd};

 $ftp->send_cmd("ABOR");
 $fd->close();
}

sub close {
 my $fd = shift;
 my $ftp = ${*$fd}{Cmd};

 $fd->Net::Socket::close();
 delete ${*$ftp}{DATA};

 $ftp->response();
}

sub timeout {
 my $me = shift;
 my $timeout = ${*$me}{Timeout};

 ${*$me}{Timeout} = 0 + shift if(@_);

 $timeout;
}

sub _select {
 my $fd = shift;
 local *timeout = \$_[0]; shift;
 my $rw = shift;
 my($rin,$win);

 return 1 unless $timeout;

 $rin = '';
 vec($rin,fileno($fd),1) = 1;

 $win = $rw ? undef : $rin;
 $rin = undef unless $rw;

 my $nfound = select($rin, $win, undef, $timeout);

 croak "select: $!"
	if $nfound < 0;

 return $nfound;
}

sub can_read {
 my $fd = shift;
 local *timeout = \$_[0];

 $fd->_select($timeout,1);
}

sub can_write {
 my $fd = shift;
 local *timeout = \$_[0];

 $fd->_select($timeout,0);
}

sub cmd {
 my $me = shift;

 ${*$me}{Cmd};
}


@Net::FTP::L::ISA = qw(Net::FTP::I);
@Net::FTP::E::ISA = qw(Net::FTP::I);

package Net::FTP::A;
@Net::FTP::A::ISA = qw(Net::FTP::dataconn);
use Carp;

no strict 'vars';

sub read {
 my $fd = shift;
 local *buf = \$_[0]; shift;
 my $size = shift || croak 'read($buf,$size,[$offset])';
 my $offset = shift || 0;
 my $timeout = ${*$fd}{Timeout};
 my $l;

 croak "Bad offset"
	if($offset < 0);

 $offset = length $buf
	if($offset > length $buf);

 $l = 0;
 READ:
  {
   $fd->can_read($timeout) or
	croak "Timeout";

   my $n = sysread($fd, ${*$fd}, $size, length ${*$fd});

   return $n
	unless($n >= 0);

#   my $lf = substr(${*$fd},-1,1) eq "\r" ? chop(${*$fd})
#					 : "";

   my $lf = (length ${*$fd} > 0 && substr(${*$fd},-1,1) eq "\r") ? chop(${*$fd})
                     : "";

   ${*$fd} =~ s/\r\n/\n/go;

   substr($buf,$offset) = ${*$fd};

   $l += length(${*$fd});
   $offset += length(${*$fd});

   ${*$fd} = $lf;
   
   redo READ
     if($l == 0 && $n > 0);

   if($n == 0 && $l == 0)
    {
     substr($buf,$offset) = ${*$fd};
     ${*$fd} = "";
    }
  }

 return $l;
}

sub write {
 my $fd = shift;
 local *buf = \$_[0]; shift;
 my $size = shift || croak 'write($buf,$size,[$timeout])';
 my $timeout = @_ ? shift : ${*$fd}{Timeout};

 $fd->can_write($timeout) or
	croak "Timeout";

 # What is previous pkt ended in \r or not ??

 my $tmp;
 ($tmp = $buf) =~ s/(?!\r)\n/\r\n/g;

 my $len = $size + length($tmp) - length($buf);
 my $wrote = syswrite($fd, $tmp, $len);

 if($wrote >= 0)
  {
   $wrote = $wrote == $len ? $size
			   : $len - $wrote
  }

 return $wrote;
}

package Net::FTP::I;
@Net::FTP::I::ISA = qw(Net::FTP::dataconn);
use Carp;

no strict 'vars';

sub read {
 my $fd = shift;
 local *buf = \$_[0]; shift;
 my $size = shift || croak 'read($buf,$size,[$timeout])';
 my $timeout = @_ ? shift : ${*$fd}{Timeout};

 $fd->can_read($timeout) or
	croak "Timeout";

 my $n = sysread($fd, $buf, $size);

 $n;
}

sub write {
 my $fd = shift;
 local *buf = \$_[0]; shift;
 my $size = shift || croak 'write($buf,$size,[$timeout])';
 my $timeout = @_ ? shift : ${*$fd}{Timeout};

 $fd->can_write($timeout) or
	croak "Timeout";

 syswrite($fd, $buf, $size);
}

=head2 AUTHOR

Graham Barr <Graham.Barr@tiuk.ti.com>

=head2 REVISION

$Revision: 1.17 $

=head2 COPYRIGHT

Copyright (c) 1995 Graham Barr. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut


1;


##
## Generic data connection package
##

package Net::FTP::dataconn;

use Carp;
use vars qw(@ISA $timeout $VERSION);
use Net::Cmd;

$VERSION = '0.10';
@ISA = qw(IO::Socket::INET);

sub reading
{
 my $data = shift;
 ${*$data}{'net_ftp_bytesread'} = 0;
}

sub abort
{
 my $data = shift;
 my $ftp  = ${*$data}{'net_ftp_cmd'};

 # no need to abort if we have finished the xfer
 return $data->close
    if ${*$data}{'net_ftp_eof'};

 # for some reason if we continously open RETR connections and not
 # read a single byte, then abort them after a while the server will
 # close our connection, this prevents the unexpected EOF on the
 # command channel -- GMB
 if(exists ${*$data}{'net_ftp_bytesread'}
	&& (${*$data}{'net_ftp_bytesread'} == 0)) {
   my $buf="";
   my $timeout = $data->timeout;
   $data->can_read($timeout) && sysread($data,$buf,1);
 }

 ${*$data}{'net_ftp_eof'} = 1; # fake

 $ftp->abort; # this will close me
}

sub _close
{
 my $data = shift;
 my $ftp  = ${*$data}{'net_ftp_cmd'};

 $data->SUPER::close();

 delete ${*$ftp}{'net_ftp_dataconn'}
    if exists ${*$ftp}{'net_ftp_dataconn'} &&
        $data == ${*$ftp}{'net_ftp_dataconn'};
}

sub close
{
 my $data = shift;
 my $ftp  = ${*$data}{'net_ftp_cmd'};

 if(exists ${*$data}{'net_ftp_bytesread'} && !${*$data}{'net_ftp_eof'}) {
   my $junk;
   $data->read($junk,1,0);
   return $data->abort unless ${*$data}{'net_ftp_eof'};
 }

 $data->_close;

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

sub bytes_read {
 my $ftp = shift;

 ${*$ftp}{'net_ftp_bytesread'} || 0;
}

1;

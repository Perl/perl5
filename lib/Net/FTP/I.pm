## $Id: //depot/libnet/Net/FTP/I.pm#11 $
## Package to read/write on BINARY data connections
##

package Net::FTP::I;

use vars qw(@ISA $buf $VERSION);
use Carp;

require Net::FTP::dataconn;

@ISA = qw(Net::FTP::dataconn);
$VERSION = "1.10"; 

sub read {
  my    $data 	 = shift;
  local *buf 	 = \$_[0]; shift;
  my    $size    = shift || croak 'read($buf,$size,[$timeout])';
  my    $timeout = @_ ? shift : $data->timeout;

  $data->can_read($timeout) or
	 croak "Timeout";

  my($b,$n,$l);
  my $blksize = ${*$data}{'net_ftp_blksize'};
  $blksize = $size if $size > $blksize;

  while(($l = length(${*$data})) < $size) {
   $n += ($b = sysread($data, ${*$data}, $blksize, $l));
   last unless $b;
  }

  $n = $size < ($l = length(${*$data})) ? $size : $l;

  $buf = substr(${*$data},0,$n);
  substr(${*$data},0,$n) = '';

  ${*$data}{'net_ftp_bytesread'} += $n if $n;
  ${*$data}{'net_ftp_eof'} = 1 unless $n;

  $n;
}

sub write {
  my    $data    = shift;
  local *buf     = \$_[0]; shift;
  my    $size    = shift || croak 'write($buf,$size,[$timeout])';
  my    $timeout = @_ ? shift : $data->timeout;

  # If the remote server has closed the connection we will be signal'd
  # when we write. This can happen if the disk on the remote server fills up

  local $SIG{PIPE} = 'IGNORE' unless $^O eq 'MacOS';
  my $sent = $size;
  my $off = 0;

  my $blksize = ${*$data}{'net_ftp_blksize'};
  while($sent > 0) {
    $data->can_write($timeout) or
	 croak "Timeout";

    my $n = syswrite($data, $buf, $sent > $blksize ? $blksize : $sent ,$off);
    return undef unless defined($n);
    $sent -= $n;
    $off += $n;
  }

  $size;
}

1;

#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bSocket\b/ && $Config{'osname'} ne 'VMS') {
	print STDERR "1..0\n";
	exit 0;
    }
}
	
use Socket;

print "1..6\n";

if( socket(T,PF_INET,SOCK_STREAM,6) ){
  print "ok 1\n";

  if( connect(T,pack_sockaddr_in(AF_INET,7,inet_aton("localhost")))){
	print "ok 2\n";

	print "# Connected to ",
		inet_ntoa((unpack_sockaddr_in(getpeername(T)))[2]),"\n";

	syswrite(T,"hello",5);
	sysread(T,$buff,10);
	print $buff eq "hello" ? "ok 3\n" : "not ok 3\n";
  }
  else{
	print "# $!\n";
	print "not ok 2\n";
  }
}
else{
	print "# $!\n";
	print "not ok 1\n";
}

if( socket(S,PF_INET,SOCK_STREAM,6) ){
  print "ok 4\n";

  if( connect(S,pack_sockaddr_in(AF_INET,7,INADDR_LOOPBACK))){
	print "ok 5\n";

	print "# Connected to ",
		inet_ntoa((unpack_sockaddr_in(getpeername(S)))[2]),"\n";

	syswrite(S,"olleh",5);
	sysread(S,$buff,10);
	print $buff eq "olleh" ? "ok 6\n" : "not ok 6\n";
  }
  else{
	print "# $!\n";
	print "not ok 5\n";
  }
}
else{
	print "# $!\n";
	print "not ok 4\n";
}


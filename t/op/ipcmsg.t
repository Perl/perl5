#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use Config;

BEGIN {
    unless($Config{'d_msgget'} eq 'define' &&
	   $Config{'d_msgctl'} eq 'define' &&
	   $Config{'d_msgsnd'} eq 'define' &&
	   $Config{'d_msgrcv'} eq 'define') {
	print "1..0\n";
	exit;
    }
}

use strict;

use IPC::SysV qw(IPC_PRIVATE IPC_NOWAIT IPC_STAT IPC_RMID
		 S_IRWXU S_IRWXG S_IRWXO);

print "1..6\n";

my $msg = msgget(IPC_PRIVATE, S_IRWXU | S_IRWXG | S_IRWXO);
# Very first time called after machine is booted value may be 0 
die "msgget failed: $!\n" unless defined($msg) && $msg >= 0;

print "ok 1\n";

#Putting a message on the queue
my $msgtype = 1;
my $msgtext = "hello";

msgsnd($msg,pack("L a*",$msgtype,$msgtext),0) or print "not ";
print "ok 2\n";

my $data;
msgctl($msg,IPC_STAT,$data) or print "not ";
print "ok 3\n";

print "not " unless length($data);
print "ok 4\n";

my $msgbuf;
msgrcv($msg,$msgbuf,256,0,IPC_NOWAIT) or print "not ";
print "ok 5\n";

my($rmsgtype,$rmsgtext) = unpack("L a*",$msgbuf);

print "not " unless($rmsgtype == $msgtype && $rmsgtext eq $msgtext);
print "ok 6\n";

msgctl($msg,IPC_RMID,0);


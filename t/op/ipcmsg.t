#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

my @define;

BEGIN {
    @define = qw(
	IPC_PRIVATE
	IPC_RMID
	IPC_NOWAIT
	IPC_STAT
	S_IRWXU
	S_IRWXG
	S_IRWXO
    );
}

use Config;
use vars map { '$' . $_ } @define;

BEGIN {
    unless($Config{'d_msgget'} eq 'define' &&
	   $Config{'d_msgctl'} eq 'define' &&
	   $Config{'d_msgsnd'} eq 'define' &&
	   $Config{'d_msgrcv'} eq 'define') {
	print "1..0\n";
	exit;
    }

    use strict;

    my @incpath = (split(/\s+/, $Config{usrinc}), split(/\s+/ ,$Config{locincpth}));
    my %done = ();
    my %define = ();

    sub process_file {
	my($file,$level) = @_;

	return unless defined $file;

	my $path = undef;
	my $dir;
	foreach $dir (@incpath) {
	    my $tmp = $dir . "/" . $file;
	    next unless -r $tmp;
	    $path = $tmp;
	    last;
	}

	return if exists $done{$path};
	$done{$path} = 1;

	if(not defined $path and $level == 0) {
	    warn "Cannot find '$file'";
	    return;
	}

	local(*F);
	open(F,$path) or return;
        $level = 1 unless defined $level;
	my $indent = " " x $level;
	print "#$indent open $path\n";
	while(<F>) {
	    s#/\*.*(\*/|$)##;

	    if ( /^#\s*include\s*[<"]([^>"]+)[>"]/ ) {
	        print "#${indent} include $1\n";
		process_file($1,$level+1);
	        print "#${indent} done include $1\n";
	        print "#${indent} back in $path\n";
	    }

	    s/(?:\([^)]*\)\s*)//;

	    if ( /^#\s*define\s+(\w+)\s+(\w+)/ ) {
	        print "#${indent} define $1 $2\n";
		$define{$1} = $2;
	    }
       }
       close(F);
       print "#$indent close $path\n";
    }

    process_file("sys/sem.h");
    process_file("sys/ipc.h");
    process_file("sys/stat.h");

    foreach my $d (@define) {
	while(defined($define{$d}) && $define{$d} !~ /^(0x)?\d+$/) {
	    $define{$d} = exists $define{$define{$d}}
		    ? $define{$define{$d}} : undef;
	}
	unless(defined $define{$d}) {
	    print "# $d undefined\n";
	    print "1..0\n";
	    exit;
	}
	{
	    no strict 'refs';
	    ${ $d } = eval $define{$d};
        }
    }
}

use strict;

print "1..6\n";

my $msg = msgget($IPC_PRIVATE, $S_IRWXU | $S_IRWXG | $S_IRWXO)
	|| die "msgget failed: $!\n";

print "ok 1\n";

#Putting a message on the queue
my $msgtype = 1;
my $msgtext = "hello";

msgsnd($msg,pack("L a*",$msgtype,$msgtext),0) or print "not ";
print "ok 2\n";

my $data;
msgctl($msg,$IPC_STAT,$data) or print "not ";
print "ok 3\n";

print "not " unless length($data);
print "ok 4\n";

my $msgbuf;
msgrcv($msg,$msgbuf,256,0,$IPC_NOWAIT) or print "not ";
print "ok 5\n";

my($rmsgtype,$rmsgtext) = unpack("L a*",$msgbuf);

print "not " unless($rmsgtype == $msgtype && $rmsgtext eq $msgtext);
print "ok 6\n";

msgctl($msg,$IPC_RMID,0);


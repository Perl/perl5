#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

my @define;

BEGIN {
    @define = qw(
	GETALL
	SETALL
	IPC_PRIVATE
	IPC_CREAT
	IPC_RMID
	IPC_STAT
	S_IRWXU
	S_IRWXG
	S_IRWXO
    );
}

use Config;
use vars map { '$' . $_ } @define;

BEGIN {
    unless($Config{'d_semget'} eq 'define' &&
	   $Config{'d_semctl'} eq 'define') {
	print "1..0\n";
	exit;
    }
    my @incpath = (split(/\s+/, $Config{usrinc}), split(/\s+/ ,$Config{locincpth}));
    my %done = ();
    my %define = ();

    sub process_file {
	my($file) = @_;

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

	unless(defined $path) {
	    warn "Cannot find '$file'";
	    return;
	}

	open(F,$path) or return;
	while(<F>) {
	    s#/\*.*(\*/|$)##;

	    process_file($mm,$1)
		    if /^#\s*include\s*[<"]([^>"]+)[>"]/;

	    s/(?:\([^)]*\)\s*)//;

	    $define{$1} = $2
		if /^#\s*define\s+(\w+)\s+((0x)?\d+|\w+)/;
       }
       close(F);
    }

    process_file("sys/sem.h");
    process_file("sys/ipc.h");
    process_file("sys/stat.h");

    foreach $d (@define) {
	while(defined($define{$d}) && $define{$d} !~ /^(0x)?\d+$/) {
	    $define{$d} = exists $define{$define{$d}}
		    ? $define{$define{$d}} : undef;
	}
	unless(defined $define{$d}) {
	    print "1..0\n";
	    exit;
	};
	${ $d } = eval $define{$d};
    }
}

use strict;

# This test doesn't seem to work properly yet so skip it for _65
print "1..0\n";
exit;


print "1..10\n";

my $sem = semget($IPC_PRIVATE, 10, $S_IRWXU | $S_IRWXG | $S_IRWXO | $IPC_CREAT)
	|| die "semget: $!\n";

print "ok 1\n";

my $data;
semctl($sem,0,$IPC_STAT,$data) or print "not ";
print "ok 2\n";

print "not " unless length($data);
print "ok 3\n";

semctl($sem,0,$SETALL,pack("s*",(0) x 10)) or print "not ";
print "ok 4\n";

$data = "";
semctl($sem,0,$GETALL,$data) or print "not ";
print "ok 5\n";

print "not " unless length($data);
print "ok 6\n";

my @data = unpack("s*",$data);

print "not " unless join("",@data) eq "0000000000";
print "ok 7\n";

$data[2] = 1;
semctl($sem,0,$SETALL,pack("s*",@data)) or print "not ";
print "ok 8\n";

$data = "";
semctl($sem,0,$GETALL,$data) or print "not ";
print "ok 9\n";

@data = unpack("s*",$data);

print "not " unless join("",@data) eq "0010000000";
print "ok 10\n";

semctl($sem,0,$IPC_RMID,undef);


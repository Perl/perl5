#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    $SIG{__DIE__} = 'cleanup';
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

print "1..10\n";

my $sem = semget($IPC_PRIVATE, 10, $S_IRWXU | $S_IRWXG | $S_IRWXO | $IPC_CREAT);
# Very first time called after machine is booted value may be 0 
die "semget: $!\n" unless defined($sem) && $sem >= 0;

print "ok 1\n";

my $data;
semctl($sem,0,$IPC_STAT,$data) or print "not ";
print "ok 2\n";

print "not " unless length($data);
print "ok 3\n";

my $template;

# Find the pack/unpack template capable of handling native C shorts.

if      ($Config{shortsize} == 2) {
    $template = "s";
} elsif ($Config{shortsize} == 4) {
    $template = "l";
} elsif ($Config{shortsize} == 8) {
    foreach my $t (qw(i q)) { # Try quad last because not supported everywhere.
	# We could trap the unsupported quad template with eval
	# but if we get this far we should have quad support anyway.
	if (length(pack($t, 0)) == 8) {
            $template = $t;
            last;
        }
    }
}

die "$0: cannot pack native shorts\n" unless defined $template;

$template .= "*";

my $nsem = 10;

semctl($sem,0,$SETALL,pack($template,(0) x $nsem)) or print "not ";
print "ok 4\n";

$data = "";
semctl($sem,0,$GETALL,$data) or print "not ";
print "ok 5\n";

print "not " unless length($data) == length(pack($template,(0) x $nsem));
print "ok 6\n";

my @data = unpack($template,$data);

my $adata = "0" x $nsem;

print "not " unless @data == $nsem and join("",@data) eq $adata;
print "ok 7\n";

my $poke = 2;

$data[$poke] = 1;
semctl($sem,0,$SETALL,pack($template,@data)) or print "not ";
print "ok 8\n";

$data = "";
semctl($sem,0,$GETALL,$data) or print "not ";
print "ok 9\n";

@data = unpack($template,$data);

my $bdata = "0" x $poke . "1" . "0" x ($nsem-$poke-1);

print "not " unless join("",@data) eq $bdata;
print "ok 10\n";

sub cleanup { semctl($sem,0,$IPC_RMID,undef) if defined $sem }

cleanup;

#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    $SIG{__DIE__} = 'cleanup';
}

use Config;

BEGIN {
    unless($Config{'d_semget'} eq 'define' &&
	   $Config{'d_semctl'} eq 'define') {
	print "1..0\n";
	exit;
    }
}

use strict;

use IPC::SysV qw(IPC_PRIVATE IPC_CREAT IPC_STAT IPC_RMID
		 GETALL SETALL
		 S_IRWXU S_IRWXG S_IRWXO);

print "1..10\n";

my $sem = semget(IPC_PRIVATE, 10, S_IRWXU | S_IRWXG | S_IRWXO | IPC_CREAT);
# Very first time called after machine is booted value may be 0 
die "semget: $!\n" unless defined($sem) && $sem >= 0;

print "ok 1\n";

my $data;
semctl($sem,0,IPC_STAT,$data) or print "not ";
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

semctl($sem,0,SETALL,pack($template,(0) x $nsem)) or print "not ";
print "ok 4\n";

$data = "";
semctl($sem,0,GETALL,$data) or print "not ";
print "ok 5\n";

print "not " unless length($data) == length(pack($template,(0) x $nsem));
print "ok 6\n";

my @data = unpack($template,$data);

my $adata = "0" x $nsem;

print "not " unless @data == $nsem and join("",@data) eq $adata;
print "ok 7\n";

my $poke = 2;

$data[$poke] = 1;
semctl($sem,0,SETALL,pack($template,@data)) or print "not ";
print "ok 8\n";

$data = "";
semctl($sem,0,GETALL,$data) or print "not ";
print "ok 9\n";

@data = unpack($template,$data);

my $bdata = "0" x $poke . "1" . "0" x ($nsem-$poke-1);

print "not " unless join("",@data) eq $bdata;
print "ok 10\n";

sub cleanup { semctl($sem,0,IPC_RMID,undef) if defined $sem }

cleanup;


use File::Spec;
use FindBin qw($Bin);

use IPC::Open3;
use Test::More;


my $pid = undef;
my $stdout = undef;
my $stderr = undef;

# get path to perldoc exec in a hopefully platform neutral way..
my ($volume, $bindir, undef) = File::Spec->splitpath($Bin);
my $perldoc = File::Spec->catpath($volume,$bindir, File::Spec->catfile(qw(blib script perldoc)));
my @dir = ($bindir,"lib","Pod");
my $podpath = File::Spec->catdir(@dir);
my $good_podfile = File::Spec->catpath($volume,$podpath,"Perldoc.pm");
my $bad_podfile = File::Spec->catpath($volume,$podpath,"asdfsdaf.pm");

plan tests => 7;

# First, look for something that should be there

eval{

$pid = open3(\*CHLD_IN,\*CHLD_OUT1,\*CHLD_ERR1,"perl " .$perldoc." ".$good_podfile);

};

is(length($@),0,"open succeeded"); # returns '' not undef
ok(defined($pid),"got process id");

#gather STDOUT
while(<CHLD_OUT1>){
 $stdout .=$_;
}

#check STDOUT
like($stdout,qr/Look up Perl documentation/,"got expected output in STDOUT");

while(<CHLD_ERR1>){
 $stderr .=$_;
}

#is($stderr,undef,"no output to STDERR as expected");

# Then look for something that should not be there
$stdout = undef;
$stderr = undef;

eval{

$pid = open3(\*CHLD_IN,\*CHLD_OUT2,\*CHLD_ERR2,"perl " .$perldoc." ".$bad_podfile);

};

is(length($@),0,"open succeeded"); # returns '' not undef
ok(defined($pid),"got process id");

#gather STDOUT
while(<CHLD_OUT2>){
 $stdout .=$_;
}

#check STDOUT
is($stdout,undef,"no output to STDOUT as expected");

while(<CHLD_ERR2>){
 $stderr .=$_;
}

like($stderr,qr/No documentation/,"got expected output in STDERR");


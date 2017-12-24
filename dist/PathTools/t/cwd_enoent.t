use warnings;
use strict;

use Config;
use Errno qw(ENOENT);
use File::Temp qw(tempdir);
use Test::More;

my $tmp = tempdir(CLEANUP => 1);
unless(mkdir("$tmp/testdir") && chdir("$tmp/testdir") && rmdir("$tmp/testdir")){
    plan skip_all => "can't be in non-existent directory";
}

plan tests => 8;
my $EXTRA_ABSPATH_TESTS = ($Config{prefix} =~ m/\//) && $^O ne 'cygwin';
require Cwd;

foreach my $type (qw(regular perl)) {
    SKIP: {
	skip "_perl_abs_path() not expected to work", 4
	    if $type eq "perl" &&
		!(($Config{prefix} =~ m/\//) && $^O ne "cygwin");
	no warnings "redefine";
	local *Cwd::abs_path = \&Cwd::_perl_abs_path if $type eq "perl";
	local *Cwd::getcwd = \&Cwd::_perl_getcwd if $type eq "perl";
	my($res, $eno);
	$! = 0;
	$res = Cwd::getcwd();
	$eno = 0+$!;
	is $res, undef, "$type getcwd result on non-existent directory";
	is $eno, ENOENT, "$type getcwd errno on non-existent directory";
	$! = 0;
	$res = Cwd::abs_path(".");
	$eno = 0+$!;
	is $res, undef, "$type abs_path result on non-existent directory";
	is $eno, ENOENT, "$type abs_path errno on non-existent directory";
    }
}

chdir $tmp or die "$tmp: $!";

1;

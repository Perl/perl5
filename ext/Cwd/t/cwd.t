#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use Config;
use Cwd;
use strict;
use warnings;
use File::Path;

print "1..14\n";

# check imports
print +(defined(&cwd) && 
	defined(&getcwd) &&
	defined(&fastcwd) &&
	defined(&fastgetcwd) ?
        "" : "not "), "ok 1\n";
print +(!defined(&chdir) &&
	!defined(&abs_path) &&
	!defined(&fast_abs_path) ?
	"" : "not "), "ok 2\n";

# XXX force Cwd to bootsrap its XSUBs since we have set @INC = "../lib"
# XXX and subsequent chdir()s can make them impossible to find
eval { fastcwd };

# Must find an external pwd (or equivalent) command.

my $pwd_cmd =
    ($^O eq "MSWin32" || $^O eq "NetWare") ? "cd" : (grep { -x && -f } map { "$_/pwd" }
			       split m/$Config{path_sep}/, $ENV{PATH})[0];

if ($^O eq 'VMS') { $pwd_cmd = 'SHOW DEFAULT'; }

if (defined $pwd_cmd) {
    chomp(my $start = `$pwd_cmd`);
    # Win32's cd returns native C:\ style
    $start =~ s,\\,/,g if ($^O eq 'MSWin32' || $^O eq "NetWare");
    # DCL SHOW DEFAULT has leading spaces
    $start =~ s/^\s+// if $^O eq 'VMS';
    if ($?) {
	for (3..6) {
	    print "ok $_ # Skip: '$pwd_cmd' failed\n";
	}
    } else {
	my $cwd        = cwd;
	my $getcwd     = getcwd;
	my $fastcwd    = fastcwd;
	my $fastgetcwd = fastgetcwd;
	print +($cwd        eq $start ? "" : "not "), "ok 3\n";
	print +($getcwd     eq $start ? "" : "not "), "ok 4\n";
	print +($fastcwd    eq $start ? "" : "not "), "ok 5\n";
	print +($fastgetcwd eq $start ? "" : "not "), "ok 6\n";
    }
} else {
    for (3..6) {
	print "ok $_ # Skip: no pwd command found\n";
    }
}

mkpath(["_ptrslt_/_path_/_to_/_a_/_dir_"], 0, 0777);
Cwd::chdir "_ptrslt_/_path_/_to_/_a_/_dir_";
my $cwd        = cwd;
my $getcwd     = getcwd;
my $fastcwd    = fastcwd;
my $fastgetcwd = fastgetcwd;
my $want = "t/_ptrslt_/_path_/_to_/_a_/_dir_";
print "# cwd        = '$cwd'\n";
print "# getcwd     = '$getcwd'\n";
print "# fastcwd    = '$fastcwd'\n";
print "# fastgetcwd = '$fastgetcwd'\n";
# This checked out OK on ODS-2 and ODS-5:
$want = "T\.PTEERSLT\.PATH\.TO\.A\.DIR\]" if $^O eq 'VMS';
print +($cwd        =~ m|$want$| ? "" : "not "), "ok 7\n";
print +($getcwd     =~ m|$want$| ? "" : "not "), "ok 8\n";
print +($fastcwd    =~ m|$want$| ? "" : "not "), "ok 9\n";
print +($fastgetcwd =~ m|$want$| ? "" : "not "), "ok 10\n";

# Cwd::chdir should also update $ENV{PWD}
print "#$ENV{PWD}\n";
print +($ENV{PWD} =~ m|$want$| ? "" : "not "), "ok 11\n";
Cwd::chdir "..";
print "#$ENV{PWD}\n";
Cwd::chdir "..";
print "#$ENV{PWD}\n";
Cwd::chdir "..";
print "#$ENV{PWD}\n";
Cwd::chdir "..";
print "#$ENV{PWD}\n";
Cwd::chdir "..";
print "#$ENV{PWD}\n";

rmtree(["_ptrslt_"], 0, 0);

if ($^O eq 'VMS') {
    # This checked out OK on ODS-2 and ODS-5:
    print +($ENV{PWD}  =~ m|\bT\]$| ? "" : "not "), "ok 12\n";
}
else {
    print +($ENV{PWD}  =~ m|\bt$| ? "" : "not "), "ok 12\n";
}

if ($Config{d_symlink}) {
    mkpath(["_ptrslt_/_path_/_to_/_a_/_dir_"], 0, 0777);
    symlink "_ptrslt_/_path_/_to_/_a_/_dir_" => "linktest";

    my $abs_path      =  Cwd::abs_path("linktest");
    my $fast_abs_path =  Cwd::fast_abs_path("linktest");
    my $want          = "t/_ptrslt_/_path_/_to_/_a_/_dir_";

    print "# abs_path      $abs_path\n";
    print "# fast_abs_path $fast_abs_path\n";
    print "# want          $want\n";
    print +($abs_path      =~ m|$want$| ? "" : "not "), "ok 13\n";
    print +($fast_abs_path =~ m|$want$| ? "" : "not "), "ok 14\n";

    rmtree(["ptrslt"], 0, 0);
    unlink "linktest";
} else {
    print "ok 13 # skipped\n";
    print "ok 14 # skipped\n";
}

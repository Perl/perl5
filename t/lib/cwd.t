#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use Config;
use Cwd;
use strict;
use warnings;

print "1..10\n";

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

mkdir "pteerslt", 0777;
mkdir "pteerslt/path", 0777;
mkdir "pteerslt/path/to", 0777;
mkdir "pteerslt/path/to/a", 0777;
mkdir "pteerslt/path/to/a/dir", 0777;
Cwd::chdir "pteerslt/path/to/a/dir";
my $cwd        = cwd;
my $getcwd     = getcwd;
my $fastcwd    = fastcwd;
my $fastgetcwd = fastgetcwd;
my $want = "t/pteerslt/path/to/a/dir";
print +($cwd        =~ m|$want$| ? "" : "not "), "ok 3\n";
print +($getcwd     =~ m|$want$| ? "" : "not "), "ok 4\n";
print +($fastcwd    =~ m|$want$| ? "" : "not "), "ok 5\n";
print +($fastgetcwd =~ m|$want$| ? "" : "not "), "ok 6\n";

# Cwd::chdir should also update $ENV{PWD}
print +($ENV{PWD} =~ m|$want$| ? "" : "not "), "ok 7\n";
Cwd::chdir ".."; rmdir "dir";
Cwd::chdir ".."; rmdir "a";
Cwd::chdir ".."; rmdir "to";
Cwd::chdir ".."; rmdir "path";
Cwd::chdir ".."; rmdir "pteerslt";
print +($ENV{PWD}  =~ m|\bt$| ? "" : "not "), "ok 8\n";

if ($Config{d_symlink}) {
    my @dirs = split " " => $Config{libpth};
    my $target = pop @dirs;
    symlink $target => "linktest";
    mkdir "pteerslt";
    chdir "pteerslt";
    my $rel = "../../t/linktest";

    my $abs_path      = Cwd::abs_path($rel);
    my $fast_abs_path = Cwd::fast_abs_path($rel);
    print +($abs_path      eq $target ? "" : "not "), "ok 9\n";
    print +($fast_abs_path eq $target ? "" : "not "), "ok 10\n";

    chdir "..";
    rmdir "pteerslt";
    unlink "linktest";
} else {
    print "ok 9 # Skip: no symlink\n";
    print "ok 10 # Skip: no symlink\n";
}

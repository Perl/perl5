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

use Test::More tests => 16;

my $IsVMS = $^O eq 'VMS';

# check imports
can_ok('main', qw(cwd getcwd fastcwd fastgetcwd));
ok( !defined(&chdir),           'chdir() not exported by default' );
ok( !defined(&abs_path),        '  nor abs_path()' );
ok( !defined(&fast_abs_path),   '  nor fast_abs_path()');


# XXX force Cwd to bootsrap its XSUBs since we have set @INC = "../lib"
# XXX and subsequent chdir()s can make them impossible to find
eval { fastcwd };

# Must find an external pwd (or equivalent) command.

my $pwd_cmd =
    ($^O eq "MSWin32" || $^O eq "NetWare") ?
        "cd" :
        (grep { -x && -f } map { "$_/pwd$Config{exe_ext}" }
	                   split m/$Config{path_sep}/, $ENV{PATH})[0];

$pwd_cmd = 'SHOW DEFAULT' if $IsVMS;

print "# native pwd = '$pwd_cmd'\n";

SKIP: {
    skip "No native pwd command found to test against", 4 unless $pwd_cmd;

    chomp(my $start = `$pwd_cmd`);
    # Win32's cd returns native C:\ style
    $start =~ s,\\,/,g if ($^O eq 'MSWin32' || $^O eq "NetWare");
    # DCL SHOW DEFAULT has leading spaces
    $start =~ s/^\s+// if $IsVMS;
    SKIP: {
        skip "'$pwd_cmd' failed, nothing to test against", 4 if $?;

	my $cwd        = cwd;
	my $getcwd     = getcwd;
	my $fastcwd    = fastcwd;
	my $fastgetcwd = fastgetcwd;
	is(cwd(),       $start, 'cwd()');
	is(getcwd(),    $start, 'getcwd()');
	is(fastcwd(),   $start, 'fastcwd()');
	is(fastgetcwd(),$start, 'fastgetcwd()');
    }
}

my $Top_Test_Dir = '_ptrslt_';
my $Test_Dir     = "$Top_Test_Dir/_path_/_to_/_a_/_dir_";
my $want = "t/$Test_Dir";
if( $IsVMS ) {
    # translate the unixy path to VMSish
    $want =~ s|/|\.|g;
    $want .= '\]';
    $want = '((?i)' . $want . ')';  # might be ODS-2 or ODS-5
}

mkpath(["$Test_Dir"], 0, 0777);
Cwd::chdir "$Test_Dir";

like(cwd(),        qr|$want$|, 'chdir() + cwd()');
like(getcwd(),     qr|$want$|, '        + getcwd()');    
like(fastcwd(),    qr|$want$|, '        + fastcwd()');
like(fastgetcwd(), qr|$want$|, '        + fastgetcwd()');

# Cwd::chdir should also update $ENV{PWD}
like($ENV{PWD}, qr|$want$|,      'Cwd::chdir() updates $ENV{PWD}');
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

rmtree([$Top_Test_Dir], 0, 0);

if ($IsVMS) {
    like($ENV{PWD}, qr|\b((?i)t)\]$|);
}
else {
    like($ENV{PWD}, qr|\bt$|);
}

SKIP: {
    skip "no symlinks on this platform", 2 unless $Config{d_symlink};

    mkpath([$Test_Dir], 0, 0777);
    symlink $Test_Dir => "linktest";

    my $abs_path      =  Cwd::abs_path("linktest");
    my $fast_abs_path =  Cwd::fast_abs_path("linktest");
    my $want          = "t/$Test_Dir";

    like($abs_path,      qr|$want$|);
    like($fast_abs_path, qr|$want$|);

    rmtree([$Top_Test_Dir], 0, 0);
    unlink "linktest";
}

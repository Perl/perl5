#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require "./test.pl";
}

use strict;

Win32::FsType() eq 'NTFS'
    or skip_all("need NTFS");

my $tmpfile1 = tempfile();

# test some of the win32 specific stat code, since we
# don't depend on the CRT for some of it

ok(link($0, $tmpfile1), "make a link to test nlink");

my @st = stat $0;
open my $fh, "<", $0 or die;
my @fst = stat $fh;
close $fh;

# the ucrt stat() is inconsistent here, using an A=0 drive letter for stat()
# and the fd for fstat(), I assume that's something backward compatible.
#
# I don't see anything we could reasonable populate it with either.
$st[6] = $fst[6] = 0;

is("@st", "@fst", "check named stat vs handle stat");

ok($st[0], "we set dev by default now");
ok($st[1], "and ino");

# unlikely, but someone else might have linked to win32/stat.t
cmp_ok($st[3], '>', 1, "should be more than one link");

my $nlink = $st[3];

# check we get nlinks etc for a directory
@st = stat("win32");
ok($st[0], "got dev for a directory");
ok($st[1], "got ino for a directory");
ok($st[3], "got nlink for a directory");

${^WIN32_SLOPPY_STAT} = 1;

@st = stat $0;
open my $fh, "<", $0 or die;
@fst = stat $fh;
close $fh;

$st[6] = $fst[6] = 0;

is("@st", "@fst", "sloppy check named stat vs handle stat");
is($st[0], 0, "sloppy no dev");
is($st[1], 0, "sloppy no ino");
# don't check nlink, Microsoft might fix it one day

${^WIN32_SLOPPY_STAT} = 0;

# symbolic links
unlink($tmpfile1); # no more hard link

# mklink is available from Vista onwards
# this may only work in an admin shell
# MKLINK [[/D] | [/H] | [/J]] Link Target
if (system("mklink $tmpfile1 win32\\stat.t") == 0) {
    ok(-l $tmpfile1, "lstat sees a symlink");

    # check stat on file vs symlink
    @st = stat $0;
    my @lst = stat $tmpfile1;

    $st[6] = $lst[6] = 0;

    is("@st", "@lst", "check stat on file vs link");

    # our hard link no longer exists, check that is reflected in nlink
    is($st[3], $nlink-1, "check nlink updated");

    unlink($tmpfile1);
}

# similarly for a directory
if (system("mklink /d $tmpfile1 win32") == 0) {
    ok(-l $tmpfile1, "lstat sees a symlink on the directory symlink");

    # check stat on directory vs symlink
    @st = stat "win32";
    my @lst = stat $tmpfile1;

    $st[6] = $lst[6] = 0;

    is("@st", "@lst", "check stat on dir vs link");

    # for now at least, we need to rmdir symlinks to directories
    rmdir( $tmpfile1 );
}

# check a junction doesn't look like a symlink

if (system("mklink /j $tmpfile1 win32") == 0) {
    ok(!-l $tmpfile1, "lstat doesn't see a symlink on the directory junction");

    rmdir( $tmpfile1 );
}

done_testing();

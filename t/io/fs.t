#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require "./test.pl";
}

use Config;

my $Is_VMSish = ($^O eq 'VMS');

if (($^O eq 'MSWin32') || ($^O eq 'NetWare')) {
    $wd = `cd`;
} elsif ($^O eq 'VMS') {
    $wd = `show default`;
} else {
    $wd = `pwd`;
}
chomp($wd);

my $has_link            = $Config{d_link};
my $accurate_timestamps =
    !($^O eq 'MSWin32' || $^O eq 'NetWare' ||
      $^O eq 'dos'     || $^O eq 'os2'     ||
      $^O eq 'mint'    || $^O eq 'cygwin'  ||
      $^O eq 'amigaos' || $wd =~ m#$Config{afsroot}/#
     );

if (defined &Win32::IsWinNT && Win32::IsWinNT()) {
    if (Win32::FsType() eq 'NTFS') {
        $has_link            = 1;
        $accurate_timestamps = 1;
    }
}

my $needs_fh_reopen =
    $^O eq 'dos'
    # Not needed on HPFS, but needed on HPFS386 ?!
    || $^O eq 'os2';

plan tests => 32;


if (($^O eq 'MSWin32') || ($^O eq 'NetWare')) {
    `rmdir /s /q tmp 2>nul`;
    `mkdir tmp`;
} elsif ($^O eq 'VMS') {
    `if f\$search("[.tmp]*.*") .nes. "" then delete/nolog/noconfirm [.tmp]*.*.*`;
    `if f\$search("tmp.dir") .nes. "" then delete/nolog/noconfirm tmp.dir;`;
    `create/directory [.tmp]`;
}
else {
    `rm -f tmp 2>/dev/null; mkdir tmp 2>/dev/null`;
}

chdir './tmp';

`/bin/rm -rf a b c x` if -x '/bin/rm';

umask(022);

SKIP: {
    skip "bogus umask", 1 if ($^O eq 'MSWin32') || ($^O eq 'NetWare');

    is((umask(0)&0777), 022, 'umask'),
}

open(fh,'>x') || die "Can't create x";
close(fh);
open(fh,'>a') || die "Can't create a";
close(fh);

my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
    $blksize,$blocks);

SKIP: { 
    skip("no link", 4) unless $has_link;

    ok(link('a','b'), "link a b");
    ok(link('b','c'), "link b c");

    ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
     $blksize,$blocks) = stat('c');

    SKIP: {
        skip "no nlink", 1 if $Config{dont_use_nlink};

        is($nlink, 3, "link count of triply-linked file");
    }

    SKIP: {
        skip "hard links not that hard in $^O", 1 if $^O eq 'amigaos';

        is($mode & 0777, 0666, "mode of triply-linked file");
    }
}

$newmode = (($^O eq 'MSWin32') || ($^O eq 'NetWare')) ? 0444 : 0777;

is(chmod($newmode,'a'), 1, "chmod succeeding");

SKIP: {
    skip("no link", 7) unless $has_link;

    ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
     $blksize,$blocks) = stat('c');

    is($mode & 0777, $newmode, "chmod going through");

    $newmode = 0700;
    chmod 0444, 'x';
    $newmode = 0666;

    is(chmod($newmode,'c','x'), 2, "chmod two files");
    
    ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
     $blksize,$blocks) = stat('c');

    is($mode & 0777, $newmode, "chmod going through to c");

    ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
     $blksize,$blocks) = stat('x');

    is($mode & 0777, $newmode, "chmod going through to x");

    is(unlink('b','x'), 2, "unlink two files");

    ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
     $blksize,$blocks) = stat('b');

    is($ino, undef, "ino of removed file b should be undef");

    ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
     $blksize,$blocks) = stat('x');

    is($ino, undef, "ino of removed file x should be undef");
}

is(rename('a','b'), 1, "rename a b");

($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
 $blksize,$blocks) = stat('a');

is($ino, undef, "ino of renamed file a should be undef");

$delta = $accurate_timestamps ? 1 : 2;	# Granularity of time on the filesystem
chmod 0777, 'b';
$foo = (utime 500000000,500000000 + $delta,'b');

is($foo, 1, "utime");

($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
    $blksize,$blocks) = stat('b');

SKIP: {
    skip "bogus inode num", 1 if ($^O eq 'MSWin32') || ($^O eq 'NetWare');

    ok($ino,    'non-zero inode num');
}

SKIP: {
    skip "filesystem atime/mtime granularity too low", 2 
      unless $accurate_timestamps;

    print "# atime - $atime  mtime - $mtime  delta - $delta\n";
    if($atime == 500000000 && $mtime == 500000000 + $delta) {
        pass('atime');
        pass('mtime');
    }
    else {
        if ($^O =~ /\blinux\b/i) {
            print "# Maybe stat() cannot get the correct atime, ".
                  "as happens via NFS on linux?\n";
            $foo = (utime 400000000,500000000 + 2*$delta,'b');
            my ($new_atime, $new_mtime) = (stat('b'))[8,9];
            print "# newatime - $new_atime  nemtime - $new_mtime\n";
            if ($new_atime == $atime && $new_mtime - $mtime == $delta) {
                pass("atime/mtime - accounted for possible NFS/glibc2.2 bug on linux");
            } 
            else {
                fail("atime mtime - $atime/$new_atime $mtime/$new_mtime");
            }
        } 
        elsif ($^O eq 'VMS') {
            # why is this 1 second off?
            is( $atime, 500000001,          'atime' );
            is( $mtime, 500000000 + $delta, 'mtime' );
        } 
        elsif ($^O eq 'beos') {
            SKIP: { skip "atime not updated", 1; }
            is($mtime, 500000001, 'mtime');
        } 
        else {
            fail("atime");
            fail("mtime");
        }
    }
}

is(unlink('b'), 1, "unlink b");

($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
    $blksize,$blocks) = stat('b');
is($ino, undef, "ino of unlinked file b should be undef");
unlink 'c';

chdir $wd || die "Can't cd back to $wd";

# Yet another way to look for links (perhaps those that cannot be
# created by perl?).  Hopefully there is an ls utility in your
# %PATH%. N.B. that $^O is 'cygwin' on Cygwin.

SKIP: {
    skip "Win32/Netware specific test", 2
      unless ($^O eq 'MSWin32') || ($^O eq 'NetWare');
    skip "No symbolic links found to test with", 2 
      unless  `ls -l perl 2>nul` =~ /^l.*->/;

    system("cp TEST TEST$$");
    # we have to copy because e.g. GNU grep gets huffy if we have
    # a symlink forest to another disk (it complains about too many
    # levels of symbolic links, even if we have only two)
    is(symlink("TEST$$","c"), 1, "symlink");
    $foo = `grep perl c 2>&1`;
    ok($foo, "found perl in c");
    unlink 'c';
    unlink("TEST$$");
}

unlink "Iofs.tmp";
open IOFSCOM, ">Iofs.tmp" or die "Could not write IOfs.tmp: $!";
print IOFSCOM 'helloworld';
close(IOFSCOM);

# TODO: pp_truncate needs to be taught about F_CHSIZE and F_FREESP,
# as per UNIX FAQ.

SKIP: {
    eval { truncate "Iofs.tmp", 5; };

    skip("no truncate - $@", 4) if $@;

    is(-s "Iofs.tmp", 5, "truncation to five bytes");

    truncate "Iofs.tmp", 0;

    ok(-z "Iofs.tmp",    "truncation to zero bytes");

    open(FH, ">Iofs.tmp") or die "Can't create Iofs.tmp";

    binmode FH;
    select FH;
    $| = 1;
    select STDOUT;

    {
	use strict;
	print FH "x\n" x 200;
	ok(truncate(FH, 200), "fh resize to 200");
    }

    if ($needs_fh_reopen) {
	close (FH); open (FH, ">>Iofs.tmp") or die "Can't reopen Iofs.tmp";
    }

    is(-s "Iofs.tmp", 200, "fh resize to 200 working");

    ok(truncate(FH, 0), "fh resize to zero");

    if ($needs_fh_reopen) {
	close (FH); open (FH, ">>Iofs.tmp") or die "Can't reopen Iofs.tmp";
    }

    ok(-z "Iofs.tmp", "fh resize to zero working");

    close FH;
}

# check if rename() can be used to just change case of filename
SKIP: {
    skip "Works in Cygwin only if check_case is set to relaxed", 1
      if $^O eq 'cygwin';

    chdir './tmp';
    open(fh,'>x') || die "Can't create x";
    close(fh);
    rename('x', 'X');
    
    # this works on win32 only, because fs isn't casesensitive
    ok(-e 'X', "rename working");

    1 while unlink 'X';
    chdir $wd || die "Can't cd back to $wd";
}

# check if rename() works on directories
if ($^O eq 'VMS') {
    # must have delete access to rename a directory
    `set file tmp.dir/protection=o:d`;
    ok(rename('tmp.dir', 'tmp1.dir'), "rename on directories") ||
      print "# errno: $!\n";
} else {
    ok(rename('tmp', 'tmp1'), "rename on directories");
}

ok(-d 'tmp1', "rename on directories working");

# need to remove 'tmp' if rename() in test 28 failed!
END { rmdir 'tmp1'; rmdir 'tmp'; unlink "Iofs.tmp"; }

#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use Config;
use File::Spec;

plan tests => 69;

$Is_Amiga   = $^O eq 'amigaos';
$Is_Cygwin  = $^O eq 'cygwin';
$Is_Dos     = $^O eq 'dos';
$Is_MPE     = $^O eq 'mpeix';
$Is_MSWin32 = $^O eq 'MSWin32';
$Is_NetWare = $^O eq 'NetWare';
$Is_OS2     = $^O eq 'os2';
$Is_Solaris = $^O eq 'solaris';
$Is_VMS     = $^O eq 'VMS';

$Is_Dosish  = $Is_Dos || $Is_OS2 || $Is_MSWin32 || $Is_NetWare || $Is_Cygwin;

my($DEV, $INO, $MODE, $NLINK, $UID, $GID, $RDEV, $SIZE,
   $ATIME, $MTIME, $CTIME, $BLKSIZE, $BLOCKS) = (0..12);

my $Curdir = File::Spec->curdir;


my $tmpfile = 'Op_stat.tmp';
my $tmpfile_link = $tmpfile.'2';


unlink $tmpfile;
open(FOO, ">$tmpfile") || BAILOUT("Can't open temp test file: $!");
close FOO;

open(FOO, ">$tmpfile") || BAILOUT("Can't open temp test file: $!");

my($nlink, $mtime, $ctime) = (stat(FOO))[$NLINK, $MTIME, $CTIME];
SKIP: {
    skip "No link count", 1 if $Is_VMS;

    is($nlink, 1, 'nlink on regular file');
}

SKIP: {
  skip "mtime and ctime not reliable", 2 
    if $Is_MSWin32 or $Is_NetWare or $Is_Cygwin or $Is_Dos;

  ok( $mtime,           'mtime' );
  is( $mtime, $ctime,   'mtime == ctime' );
}


# Cygwin seems to have a 3 second granularity on its timestamps.
my $funky_FAT_timestamps = $Is_Cygwin;
sleep 3 if $funky_FAT_timestamps;

print FOO "Now is the time for all good men to come to.\n";
close(FOO);

sleep 2 unless $funky_FAT_timestamps;


SKIP: {
    unlink $tmpfile_link;
    my $lnk_result = eval { link $tmpfile, $tmpfile_link };
    skip "link() unimplemented", 6 if $@ =~ /unimplemented/;

    is( $@, '',         'link() implemented' );
    ok( $lnk_result,    'linked tmp testfile' );
    ok( chmod(0644, $tmpfile),             'chmoded tmp testfile' );

    my($nlink, $mtime, $ctime) = (stat($tmpfile))[$NLINK, $MTIME, $CTIME];

    SKIP: {
        skip "No link count", 1 if $Config{dont_use_nlink};
        is($nlink, 2,     'Link count on hard linked file' );
    }

    SKIP: {
        my $cwd = File::Spec->rel2abs($Curdir);
        skip "Solaris tmpfs has different mtime/ctime link semantics", 2 
                                     if $Is_Solaris and $cwd =~ m#^/tmp# and 
                                        $mtime && $mtime == $ctime;
        skip "AFS has different mtime/ctime link semantics", 2
                                     if $cwd =~ m#$Config{'afsroot'}/#;
        skip "AmigaOS has different mtime/ctime link semantics", 2
                                     if $Is_Amiga;

        if( !ok($mtime, 'hard link mtime') ||
            !isnt($mtime, $ctime, 'hard link ctime != mtime') ) {
            print <<DIAG;
# Check if you are on a tmpfs of some sort.  Building in /tmp sometimes 
# has this problem.  Also building on the ClearCase VOBS filesystem may 
# cause this failure.
DIAG
        }
    }

}

# truncate and touch $tmpfile.
open(F, ">$tmpfile") || BAILOUT("Can't open temp test file: $!");
close F;

ok(-z $tmpfile,     '-z on empty file');
ok(! -s $tmpfile,   '   and -s');

open(F, ">$tmpfile") || BAILOUT("Can't open temp test file: $!");
print F "hi\n";
close F;

ok(! -z $tmpfile,   '-z on non-empty file');
ok(-s $tmpfile,     '   and -s');


# Strip all access rights from the file.
ok( chmod(0000, $tmpfile),     'chmod 0000' );

SKIP: {
    skip "-r, -w and -x have different meanings on VMS", 3 if $Is_VMS;

    SKIP: {
        # Going to try to switch away from root.  Might not work.
        my $olduid = $>;
        eval { $> = 1; };
        skip "Can't test -r or -w meaningfully if you're superuser", 2 
          if $> == 0;

        SKIP: {
            skip "Can't test -r meaningfully?", 1 if $Is_Dos || $Is_Cygwin;
            ok(!-r $tmpfile,    "   -r");
        }

        ok(!-w $tmpfile,    "   -w");

        # switch uid back (may not be implemented)
        eval { $> = $olduid; };
    }

    ok(! -x $tmpfile,   '   -x');
}




# in ms windows, $tmpfile inherits owner uid from directory
# not sure about os/2, but chown is harmless anyway
eval { chown $>,$tmpfile; 1 } or print "# $@" ;

ok(chmod(0700,$tmpfile),    'chmod 0700');
ok(-r $tmpfile,     '   -r');
ok(-w $tmpfile,     '   -w');

SKIP: {
    skip "-x simply determins if a file ends in an executable suffix", 1
      if $Is_Dosish;

    ok(-x $tmpfile,     '   -x');
}

ok(  -f $tmpfile,   '   -f');
ok(! -d $tmpfile,   '   !-d');

# Is this portable?
ok(  -d $Curdir,          '-d cwd' );
ok(! -f $Curdir,          '!-f cwd' );


SKIP: {
    unlink($tmpfile_link);
    my $symlink_rslt = eval { symlink $tmpfile, $tmpfile_link };
    skip "symlink not implemented", 3 if $@ =~ /unimplemented/;

    is( $@, '',     'symlink() implemented' );
    ok( $symlink_rslt,      'symlink() ok' );
    ok(-l $tmpfile_link,    '-l');
}

ok(-o $tmpfile,     '-o');

ok(-e $tmpfile,     '-e');

unlink($tmpfile_link);
ok(! -e $tmpfile_link,  '   -e on unlinked file');

SKIP: {
    skip "No character, socket or block special files", 3
      if $Is_MSWin32 || $Is_NetWare || $Is_Dos;
    skip "/dev isn't available to test against", 3
      unless -d '/dev' && -r '/dev' && -x '/dev';

    my $LS  = $Config{d_readlink} ? "ls -lL" : "ls -l"; 
    my $CMD = "$LS /dev";
    my $DEV = qx($CMD);

    skip "$CMD failed", 3 if $DEV eq '';

    my @DEV = do { my $dev; opendir($dev, "/dev") ? readdir($dev) : () };

    skip "opendir failed: $!", 3 if @DEV == 0;

    my $try = sub {
	my @c1 = eval qq[\$DEV =~ /^$_[0]/mg];
	my @c2 = eval qq[grep { $_[1] "/dev/\$_" } \@DEV];
	my $c1 = scalar @c1;
	my $c2 = scalar @c2;
	is($c1, $c2, "ls and $_[1] agree on /dev ($c1 $c2)");
    };

    $try->('b', '-b');
    $try->('c', '-c');
    $try->('s', '-S');
}

ok(! -b $Curdir,    '!-b cwd');
ok(! -c $Curdir,    '!-c cwd');
ok(! -S $Curdir,    '!-S cwd');

SKIP: {
    skip "No setuid", 3 if $Is_MPE or $Is_Amiga or $Is_Dosish or $Is_Cygwin;

    my($cnt, $uid);
    $cnt = $uid = 0;

    # Find a set of directories that's very likely to have setuid files
    # but not likely to be *all* setuid files.
    my @bin = grep {-d && -r && -x} qw(/sbin /usr/sbin /bin /usr/bin);
    skip "Can't find a setuid file to test with", 3 unless @bin;

    for my $bin (@bin) {
        opendir BIN, $bin or die "Can't opendir $bin: $!";
        while (defined($_ = readdir BIN)) {
            $_ = "$bin/$_";
            $cnt++;
            $uid++ if -u;
            last if $uid && $uid < $cnt;
        }
    }
    closedir BIN;

    if( !isnt($cnt, 0,    'found some programs') ||
        !isnt($uid, 0,    'found some setuid programs') ||
        !ok($uid < $cnt,  "  they're not all setuid") )
    {
        print <<DIAG;
# The above two tests assume that at least one of these directories
# are readable, executable and contain at least one setuid file
# (but aren't all setuid).
#   @bin
DIAG
    }
}


# To assist in automated testing when a controlling terminal (/dev/tty)
# may not be available (at, cron  rsh etc), the PERL_SKIP_TTY_TEST env var
# can be set to skip the tests that need a tty.
SKIP: {
    skip "These tests require a TTY", 4 if $ENV{PERL_SKIP_TTY_TEST};

    my $TTY = $^O eq 'rhapsody' ? "/dev/ttyp0" : "/dev/tty";

    SKIP: {
        skip "Test uses unixisms", 2 if $Is_MSWin32 || $Is_NetWare;
        skip "No TTY to test -t with", 2 unless -e $TTY;

        open(TTY, $TTY) || 
          warn "Can't open $TTY--run t/TEST outside of make.\n";
        ok(-t TTY,  '-t');
        ok(-c TTY,  'tty is -c');
        close(TTY);
    }
    ok(! -t TTY,    '!-t on closed TTY filehandle');
    ok(-t,          '-t on STDIN');
}

my $Null = File::Spec->devnull;
SKIP: {
    skip "No null device to test with", 1 unless -e $Null;

    open(NULL, $Null) or BAIL_OUT("Can't open $Null: $!");
    ok(! -t NULL,   'null device is not a TTY');
    close(NULL);
}


# These aren't strictly "stat" calls, but so what?

ok(-T 'op/stat.t',      '-T');
ok(! -B 'op/stat.t',    '!-B');

ok(-B $^X,      '-B');
ok(! -T $^X,    '!-T');

open(FOO,'op/stat.t');
SKIP: {
    eval { -T FOO; };
    skip "-T/B on filehandle not implemented", 15 if $@ =~ /not implemented/;

    is( $@, '',     '-T on filehandle causes no errors' );

    ok(-T FOO,      '   -T');
    ok(! -B FOO,    '   !-B');

    $_ = <FOO>;
    ok(/perl/,      'after readline');
    ok(-T FOO,      '   still -T');
    ok(! -B FOO,    '   still -B');
    close(FOO);

    open(FOO,'op/stat.t');
    $_ = <FOO>;
    ok(/perl/,      'reopened and after readline');
    ok(-T FOO,      '   still -T');
    ok(! -B FOO,    '   still !-B');

    ok(seek(FOO,0,0),   'after seek');
    ok(-T FOO,          '   still -T');
    ok(! -B FOO,        '   still !-B');

    # It's documented this way in perlfunc *shrug*
    () = <FOO>;
    ok(eof FOO,         'at EOF');
    ok(-T FOO,          '   still -T');
    ok(-B FOO,          '   now -B');
}
close(FOO);


SKIP: {
    skip "No null device to test with", 2 unless -e $Null;

    ok(-T $Null,  'null device is -T');
    ok(-B $Null,  '    and -B');
}


# and now, a few parsing tests:
$_ = $tmpfile;
ok(-f,      'bare -f   uses $_');
ok(-f(),    '     -f() "');

unlink $tmpfile or print "# unlink failed: $!\n";

# bug id 20011101.069
my @r = \stat(".");
is(scalar @r, 13,   'stat returns full 13 elements');


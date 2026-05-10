#!./perl

# When the system code page is CP_UTF8 (set via "Use Unicode UTF-8 for
# worldwide language support" or a per-process app manifest), several
# CORE Win32 wrappers in win32/win32.c return UTF-8-encoded bytes
# through char buffers and the resulting Perl SVs do not carry the
# SvUTF8 flag.  Concatenation with a Unicode string then upgrades each
# byte as Latin-1 and produces mojibake.
#
# The assertions below are FLAG-based so they hold regardless of system
# locale.  Each is wrapped in TODO until win32.c calls SvUTF8_on (or
# equivalent) at the relevant SV-construction sites.
#
# Test design:
#   - Skip the whole file unless the active code page is CP_UTF8.
#   - Each assertion runs under TODO so the suite stays green until
#     someone lands the fix and removes the TODO marker.

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;
use warnings;
use File::Temp qw(tempdir);
use Cwd ();
use POSIX ();

if ($^O ne 'MSWin32') {
    skip_all('Windows only');
}

require Win32;
my $acp = Win32::GetACP();
if ($acp != 65001) {
    skip_all("requires GetACP() == 65001 (got $acp); embed an "
             . "<activeCodePage>UTF-8</activeCodePage> manifest in "
             . "perl.exe to enable");
}

note("GetACP() = $acp");

# readdir entries
{
    my $home = Cwd::getcwd();
    my $tmp  = tempdir(CLEANUP => 1);
    chdir $tmp or die "chdir $tmp: $!";
    open(my $fh, '>', 'marker.txt') or die "open: $!";
    close $fh;
    opendir(my $dh, '.') or die "opendir: $!";
    my @entries = grep { !/^\./ } readdir $dh;
    closedir $dh;
    chdir $home;

    TODO: {
        local our $TODO = 'win32_readdir does not set SvUTF8 under CP_UTF8 ACP';
        for my $e (@entries) {
            ok(utf8::is_utf8($e), "readdir entry '$e' has SvUTF8 flag");
        }
    }
}

# $ENV{X}
{
    $ENV{T_CP_UTF8_ACP} = 'value';
    TODO: {
        local our $TODO = 'win32_getenv does not set SvUTF8 under CP_UTF8 ACP';
        ok(utf8::is_utf8($ENV{T_CP_UTF8_ACP}), '$ENV{X} has SvUTF8 flag');
    }
    delete $ENV{T_CP_UTF8_ACP};
}

# $^E (formatted Windows error message)
{
    $! = 0;
    open(my $fh, '<', "no-such-file-pid$$");  # expected to fail
    my $err = "$^E";
    TODO: {
        local our $TODO = 'win32_str_os_error does not set SvUTF8 under CP_UTF8 ACP';
        ok(utf8::is_utf8($err), '$^E has SvUTF8 flag');
    }
}

# getlogin()
{
    my $login = getlogin();
    TODO: {
        local our $TODO = 'getlogin (GetUserName) does not set SvUTF8 under CP_UTF8 ACP';
        ok(defined $login && utf8::is_utf8($login),
           "getlogin() has SvUTF8 flag (got: " . (defined $login ? "'$login'" : 'undef') . ')');
    }
}

# POSIX::uname() nodename
{
    my @uname = POSIX::uname();
    TODO: {
        local our $TODO = 'win32_uname does not set SvUTF8 under CP_UTF8 ACP';
        ok(@uname && utf8::is_utf8($uname[1]),
           "POSIX::uname()[1] has SvUTF8 flag (got: '$uname[1]')");
    }
}

# Cwd::getcwd
{
    my $cwd = Cwd::getcwd();
    TODO: {
        local our $TODO = 'win32_get_childdir does not set SvUTF8 under CP_UTF8 ACP';
        ok(defined $cwd && utf8::is_utf8($cwd),
           "Cwd::getcwd() has SvUTF8 flag");
    }
}

# Cwd::getdcwd (Win32-only XS sub, separate _getdcwd CRT call)
{
    my $dcwd = Cwd::getdcwd();
    TODO: {
        local our $TODO = '_getdcwd does not set SvUTF8 under CP_UTF8 ACP';
        ok(defined $dcwd && utf8::is_utf8($dcwd),
           "Cwd::getdcwd() has SvUTF8 flag");
    }
}

# readlink — needs an actual symlink. Symlink creation on Windows
# requires Developer Mode or admin; skip cleanly when symlink() fails.
{
    my $home = Cwd::getcwd();
    my $tmp  = tempdir(CLEANUP => 1);
    chdir $tmp or die "chdir $tmp: $!";
    open(my $fh, '>', 'target.txt') or die "open target: $!";
    close $fh;
    my $made = eval { symlink('target.txt', 'link') } ? 1 : 0;
    SKIP: {
        skip 'symlink not allowed (need developer mode or admin)', 1
            unless $made;
        my $value = readlink 'link';
        TODO: {
            local our $TODO = 'win32_readlink does not set SvUTF8 under CP_UTF8 ACP';
            ok(defined $value && utf8::is_utf8($value),
               "readlink() has SvUTF8 flag (got: "
               . (defined $value ? "'$value'" : 'undef') . ')');
        }
    }
    chdir $home;
}

done_testing();

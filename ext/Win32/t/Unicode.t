use strict;
use Test;
use Win32;

use Cwd qw(cwd);

BEGIN {
    unless (defined &Win32::BuildNumber && Win32::BuildNumber() >= 820 or $] >= 5.008009) {
	print "1..0 # Skip: Needs ActivePerl 820 or Perl 5.8.9 or later\n";
	exit 0;
    }
    unless ((Win32::FsType())[1] & 4) {
	print "1..0 # Skip: Filesystem doesn't support Unicode\n";
	exit 0;
    }
    unless ((Win32::GetOSVersion())[1] > 4) {
	print "1..0 # Skip: Unicode support requires Windows 2000 or later\n";
	exit 0;
    }
}

my $home = Win32::GetCwd();
my $dir  = "Foo \x{394}\x{419} Bar \x{5E7}\x{645} Baz";
my $file = "$dir\\xyzzy \x{394}\x{419} plugh \x{5E7}\x{645}";

sub cleanup {
    chdir($home);
    my $ansi = Win32::GetANSIPathName($file);
    unlink($ansi) if -f $ansi;
    $ansi = Win32::GetANSIPathName($dir);
    rmdir($ansi) if -d $ansi;
}

cleanup();
END { cleanup() }

plan test => 12;

# Create Unicode directory
Win32::CreateDirectory($dir);
ok(-d Win32::GetANSIPathName($dir));

# Create Unicode file
Win32::CreateFile($file);
ok(-f Win32::GetANSIPathName($file));

# readdir() returns ANSI form of Unicode filename
ok(opendir(my $dh, Win32::GetANSIPathName($dir)));
while ($_ = readdir($dh)) {
    next if /^\./;
    ok($file, Win32::GetLongPathName("$dir\\$_"));
}
closedir($dh);

# Win32::GetLongPathName() of the absolute path restores the Unicode dir name
my $full = Win32::GetFullPathName($dir);
my $long = Win32::GetLongPathName($full);

ok($long, Win32::GetLongPathName($home)."\\$dir");

# We can Win32::SetCwd() into the Unicode directory
ok(Win32::SetCwd($dir));
ok(Win32::GetLongPathName(Win32::GetCwd()), $long);

# cwd() also returns a usable ANSI directory name
(my $cwd = cwd) =~ s,/,\\,g;
ok(Win32::GetLongPathName($cwd), $long);

# change back to home directory
ok(chdir($home));
ok(Win32::GetCwd(), $home);

# We can chdir() into the Unicode directory if we use the ANSI name
ok(chdir(Win32::GetANSIPathName($dir)));
ok(Win32::GetLongPathName(Win32::GetCwd()), $long);

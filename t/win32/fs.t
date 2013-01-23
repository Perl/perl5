#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require "./test.pl";
    eval 'use Errno';
    die $@ if $@ and !is_miniperl();
}

use Config;
use Cwd;

plan tests => 12;

my $tmpfile1 = tempfile();
my $tmpfile2 = tempfile();

# RT #112272
ok(!link($tmpfile1, $tmpfile2),
   "Cannot link to unknown file");
is(0+$!, &Errno::ENOENT, "check errno is ENOENT");
open my $fh, ">", $tmpfile1
    or skip("Cannot create test link src", 2);
close $fh;
open my $fh, ">", $tmpfile2
    or skip("Cannot create test link target", 2);
close $fh;
ok(!link($tmpfile1, $tmpfile2),
   "Cannot link to existing file");
is(0+$!, &Errno::EEXIST, "check for EEXIST");

# RT #45331
SKIP: {
    local $TODO = "-d on //?/C:/ fails";
    # get the current drive letter and make a //?/C:/ path
    my $cwd = getcwd();
    my $drive = ($cwd =~ /^(\w:)/)
	or skip "cwd isn't on a drive", 1;
    my $ntdrive = "//?/\U$drive/";
    ok(-d, "-d on //?/C:/ type path");
}

SKIP: {
    my $path = $ENV{WIN32_TEST_UNC};
    if (!$path && $ENV{SystemDrive}) {
	# this works on Windows 7
	my $letter = substr($ENV{SystemDrive}, 0, 1);
	$path = "\\\\localhost\\$letter\$\\";
	note "Trying path '$path'";
    }
    -d $path
	or skip "Can't find a share to test with, set WIN32_TEST_UNC to a \\\\server\\share", 7;
    $path =~ s(/)(\\)g;
    $path =~ s=([^\\\/])$=$1\\=;

    # look for a filename
    opendir my $unc, $path
	or skip "Cannot opendir test UNC path: $!", 7;
    my ($filename) = grep -f $path . $_, readdir $unc;
    closedir $unc;
    $filename
	or skip "Cannot find a file under $path", 7;
    
    # make a \\?\ form
    my $ntpath = "\\\\?\\UNC" . $path;
    my $ntfilepath = $ntpath . $filename;
    my $filepath = $path . $filename;
    my @stat = stat($filepath);
    my @ntstat = stat($ntfilepath);
    
    note "Direct: @stat\n";
    note "NTpath: @ntstat\n";
    ok(-f $ntfilepath, "[perl #45331] -f should pass on $ntfilepath");

    local $TODO = "stat()[2] (mode) on \\\\?\\UNC\\server\\share\\filename fails";
    is($ntstat[2], $stat[2], "[perl #45331] file mode on $ntfilepath");

    undef $TODO;
    is($ntstat[3], $stat[3], "[perl #45331] file nlink $ntfilepath");

    is($ntstat[7], $stat[7], "[perl #45331] file size on $ntfilepath");

    $TODO = "stat()[8] (atime) on \\\\?\\UNC\\server\\share\\filename fails";
    is($ntstat[8], $stat[8], "[perl #45331] atime on $ntfilepath");

    $TODO = "stat()[9] (mtime) on \\\\?\\UNC\\server\\share\\filename fails";
    is($ntstat[9], $stat[9], "[perl #45331] mtime on $ntfilepath");

    $TODO = "stat()[10] (ctime) on \\\\?\\UNC\\server\\share\\filename fails";
    is($ntstat[10], $stat[10], "[perl #45331] ctime on $ntfilepath");
}

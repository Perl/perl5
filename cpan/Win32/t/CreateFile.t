use strict;
use Test::More tests => 15;
use Win32;

my $path = "testing-$$";
rmdir($path)  if -d $path;
unlink($path) if -f $path;

ok(!-d $path);
ok(!-f $path);

ok(Win32::CreateDirectory($path));
ok(-d $path);

ok(!Win32::CreateDirectory($path));
ok(!Win32::CreateFile($path));

ok(rmdir($path));
ok(!-d $path);

ok(Win32::CreateFile($path));
ok(-f $path);
is(-s $path, 0);

ok(!Win32::CreateDirectory($path));
ok(!Win32::CreateFile($path));

ok(unlink($path));
ok(!-f $path);

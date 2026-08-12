use strict;
use Test::More tests => 16;
use Win32;

my $cwd = Win32::GetCwd;
my @cwd = split/\\/, $cwd;
my $file = pop @cwd;
my $dir = join('\\', @cwd);

is(scalar Win32::GetFullPathName('.'), $cwd);
is((Win32::GetFullPathName('.'))[0], "$dir\\");
is((Win32::GetFullPathName('.'))[1], $file);

is((Win32::GetFullPathName('./'))[0], "$cwd\\");
is((Win32::GetFullPathName('.\\'))[0], "$cwd\\");
is((Win32::GetFullPathName('./'))[1], "");

is(scalar Win32::GetFullPathName($cwd), $cwd);
is((Win32::GetFullPathName($cwd))[0], "$dir\\");
is((Win32::GetFullPathName($cwd))[1], $file);

is(scalar Win32::GetFullPathName(substr($cwd,2)), $cwd);
is((Win32::GetFullPathName(substr($cwd,2)))[0], "$dir\\");
is((Win32::GetFullPathName(substr($cwd,2)))[1], $file);

is(scalar Win32::GetFullPathName('/Foo Bar/'), substr($cwd,0,2)."\\Foo Bar\\");

chdir(my $dird = $dir !~ /^[A-Z]:$/ ? $dir : "$dir\\");
is(scalar Win32::GetFullPathName('.'), $dird);

is((Win32::GetFullPathName($file))[0], "$dir\\");
is((Win32::GetFullPathName($file))[1], $file);

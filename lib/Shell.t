#!./perl

use Test::More tests => 4;

BEGIN { use_ok('Shell'); }

my $Is_VMS     = $^O eq 'VMS';
my $Is_MSWin32 = $^O eq 'MSWin32';
my $Is_NetWare = $^O eq 'NetWare';

$Shell::capture_stderr = 1; #

# Now test that that works ..

my $tmpfile = 'sht0001';

while ( -f $tmpfile )
{
  $tmpfile++;
}

END { -f $tmpfile && unlink $tmpfile };



open(SAVERR,">&STDERR") ;
open(STDERR, ">$tmpfile");

xXx();  # Ok someone could have a program called this :(

ok( !(-s $tmpfile) ,'$Shell::capture_stderr');

$Shell::capture_stderr = 0; #

# someone will have to fill in the blanks for other platforms

if ( $Is_VMS )
{
   skip "Please implement VMS test", 2;
   ok(1);
   ok(1);
}
elsif( $Is_MSWin32 )
{
  ok(dir(),'Execute command');

  my @files = dir('*.*');

  ok(@files, 'Quoted arguments');
}
else
{
  ok(ls(),'Execute command');

  my @files = ls('*');

  ok(@files,'Quoted arguments');

}

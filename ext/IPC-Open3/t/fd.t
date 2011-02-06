#!./perl

BEGIN {
    if ($^O eq 'VMS') {
        print "1..0 # Skip: needs porting, perhaps imitating Win32 mechanisms\n";
	exit 0;
    }
}
use strict;
use warnings;

use Test::More tests => 5;
use Test::PerlRun qw(perlrun perlrun_stdout_like);

# [perl #76474]
{
  my ($stdout, $stderr, $status)
	= perlrun({switches => ['-MIPC::Open3', '-w'],
		   code => 'open STDIN, q _Makefile_ or die $!; open3(q _<&0_, my $out, undef, $ENV{PERLEXE}, q _-e0_)',
		  });

  is($stdout, '',
     'dup STDOUT in a child process by using its file descriptor');
  is($stderr, '', 'no errors');
  is($status, 0, 'clean exit');
}

{
  my $want = qr/\A# This Makefile is for the IPC::Open3 extension to perl\.\r?\n\z/;
  open my $fh, '<', 'Makefile' or die "Can't open MAKEFILE: $!";
  my $have = <$fh>;
  like($have, $want, 'No surprises from MakeMaker');
  close $fh;

  perlrun_stdout_like(<<'EOP',
use IPC::Open3;
open FOO, 'Makefile' or die $!;
open3('<&' . fileno FOO, my $out, undef, $ENV{PERLEXE}, '-eprint scalar <STDIN>');
print <$out>;
EOP
		      $want,
		      'Numeric file handles are duplicated correctly'
		     );
}

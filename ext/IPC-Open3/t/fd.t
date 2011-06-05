#!./perl

BEGIN {
    if (!PerlIO::Layer->find('perlio') || $ENV{PERLIO} eq 'stdio') {
	print "1..0 # Skip: not perlio\n";
	exit 0;
    }
    if ($^O eq 'VMS') {
        print "1..0 # Skip: needs porting, perhaps imitating Win32 mechanisms\n";
	exit 0;
    }
    require "../../t/test.pl";
}
use strict;
use warnings;

plan 1;

# [perl #76474]
{
  my $stderr = runperl(
     switches => ['-MIPC::Open3', '-w'],
     prog => 'open STDIN, q _Makefile_ or die $!; open3(q _<&1_, my $out, undef, $ENV{PERLEXE}, q _-e0_)',
     stderr => 1,
  );

  is $stderr, '',
   "dup STDOUT in a child process by using its file descriptor";
}

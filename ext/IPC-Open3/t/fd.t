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

plan 2;

# [perl #76474]
{
  my $stderr = runperl(
     switches => ['-MIPC::Open3', '-w'],
     prog => 'open STDIN, q _Makefile_ or die $!; open3(q _<&1_, my $out, undef, $ENV{PERLEXE}, q _-e0_)',
     stderr => 1,
  );
  {
      local $::TODO = "Bogus warning in IPC::Open3::spawn_with_handles"
	  if $^O eq 'MSWin32';
      $stderr =~ s/(Use of uninitialized value.*Open3\.pm line \d+\.)\n//;
      is($1, undef, 'No bogus warning found');
  }

  is $stderr, '',
   "dup STDOUT in a child process by using its file descriptor";
}

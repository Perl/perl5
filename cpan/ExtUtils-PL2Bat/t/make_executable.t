#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Config;
use Test::More;
use ExtUtils::PL2Bat;
use Cwd qw/cwd/;

plan($^O eq 'MSWin32' ? (tests => 7) : skip_all => 'Only usable on Windows');

my $filename = 'test_exec';
my @files;

open my $out, '>', $filename or die "Couldn't create $filename: $!";
print $out "#! perl -w\nexit \$ARGV[0];\n";
close $out;

pl2bat(in => $filename);

print STDERR "make_executable.t original path: $ENV{PATH}\n";
my $tmp_path = do { # keep PATH from going above 1023 chars (incompatible on win2k)
	my $perl_path = $^X;
	my $cmd_path = $ENV{ComSpec} ||  `where cmd`; # doesn't seem to work on all windows versions
	printf STDERR "make_executable.t cmd path: %s\n", ($cmd_path || "undef");
	my @path_fallbacks = grep /\Q$ENV{SystemRoot}\E|system32|winnt|windows/i, split $Config{path_sep}, $ENV{PATH};
	$_ =~ s/[\\\/][^\\\/]+$// for $perl_path, $cmd_path; # strip executable name
	join $Config{path_sep}, @path_fallbacks, $cmd_path, $perl_path, cwd();
};
print STDERR "make_executable.t perl executable: $^X\n";
print STDERR "make_executable.t temp path: $tmp_path\n";

foreach my $i (42, 51, 0) {
	local $ENV{PATH} = $tmp_path;
	print STDERR "make_executable.t set path: $ENV{PATH}\n";
	my $ret = system $filename, $i;
	is $ret & 0xff, 0, 'test_exec executed successfully';
	is $ret >> 8, $i, "test_exec $i return value ok";
}

push @files, grep { -f } map { $filename.$_ } split / $Config{path_sep} /x, $ENV{PATHEXT} || '';
is scalar(@files), 1, "Executable file exists";

unlink $filename, @files;

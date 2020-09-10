#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Config;
use Test::More;
use ExtUtils::PL2Bat;
use Cwd qw/cwd/;

plan($^O eq 'MSWin32' ? (tests => 8) : skip_all => 'Only usable on Windows');

my $filename = 'test_exec';
my @files;

open my $out, '>', $filename or die "Couldn't create $filename: $!";
print $out "#! perl -w\nexit \$ARGV[0];\n";
close $out;

pl2bat(in => $filename);

my $path_with_cwd = construct_test_PATH();

foreach my $i (42, 51, 0) {
	local $ENV{PATH} = $path_with_cwd;
	my $ret = system $filename, $i;
	is $ret & 0xff, 0, 'test_exec executed successfully';
	is $ret >> 8, $i, "test_exec $i return value ok";
}

push @files, grep { -f } map { $filename.$_ } split / $Config{path_sep} /x, $ENV{PATHEXT} || '';
is scalar(@files), 1, "Executable file exists";

unlink $filename, @files;

# the test needs CWD in PATH to check the created .bat files, but under win2k
# PATH must not be too long. so to keep any win2k smokers happy, we construct
# a new PATH that contains the dirs which hold cmd.exe, perl.exe, and CWD

sub construct_test_PATH {
	my $perl_path = $^X;
	my $cmd_path = $ENV{ComSpec} ||  `where cmd`; # where doesn't seem to work on all windows versions
	$_ =~ s/[\\\/][^\\\/]+$// for $perl_path, $cmd_path; # strip executable names

	my @path_fallbacks = grep /\Q$ENV{SystemRoot}\E|system32|winnt|windows/i, split $Config{path_sep}, $ENV{PATH};

	my $path_with_cwd = join $Config{path_sep}, @path_fallbacks, $cmd_path, $perl_path, cwd();

	my ($perl) = ( $^X =~ /[\\\/]([^\\]+)$/ ); # in case the perl executable name differs
	note "using perl executable name: $perl";

	local $ENV{PATH} = $path_with_cwd;
	my $test_out = `$perl -e 1 2>&1`;
	is $test_out, "", "perl execution with temp path works"
		or diag "make_executable.t tmp path: $path_with_cwd";
	diag "make_executable.t PATH likely did not contain cmd.exe"
		if !defined $test_out;

	return $path_with_cwd;
}

#!./perl

BEGIN {
    chdir '..' if -d '../pod' && -d '../t';
    @INC = 'lib';
}

use strict;
use warnings;
use Config;

my %Core_Modules;

unless (open(MANIFEST, "MANIFEST")) {
    die "$0: failed to open 'MANIFEST': $!\n";
}

sub add_by_name {
    $Core_Modules{$_[0]}++;
}

while (<MANIFEST>) {
    next unless m!^lib/(\S+?)\.pm!;
    my $module = $1;
    $module =~ s!/!::!g;
    add_by_name($module);
}

close(MANIFEST);

# Delete stuff that can't be tested here.

sub delete_by_name {
    delete $Core_Modules{$_[0]};
}

sub has_extension {
    $Config{extensions} =~ /\b$_[0]\b/i;
}

sub delete_unless_has_extension {
    delete $Core_Modules{$_[0]} unless has_extension($_[0]);
}

foreach my $known_extension (split(' ', $Config{known_extensions})) {
    delete_unless_has_extension($known_extension);
}

sub delete_by_prefix {
    for my $match (grep { /^$_[0]/ } keys %Core_Modules) {
	delete_by_name($match);
    }
}

delete_by_name('CGI::Fast');		# won't load without FCGI

delete_by_name('Devel::DProf');		# needs to be run as -d:DProf

delete_by_prefix('ExtUtils::MM_');	# ExtUtils::MakeMaker's domain

delete_by_prefix('File::Spec::');	# File::Spec's domain
add_by_name('File::Spec::Functions');	# put this back

sub using_feature {
    my $use = "use$_[0]";
    exists $Config{$use} &&
	defined $Config{$use} &&
	$Config{$use} eq 'define';
}

unless (using_feature('threads') && has_extension('Thread')) {
    delete_by_name('Thread');
    delete_by_prefix('Thread::');
}

delete_by_prefix('unicode::');
add_by_name('unicode::distinct');	# put this back


# Delete all modules which have their own tests.  This makes
# this test alot faster.
foreach my $mod (<DATA>) {
    chomp $mod;
    delete_by_name($mod);
}

# Okay, this is the list.

my @Core_Modules = sort keys %Core_Modules;

print "1..".@Core_Modules."\n";

my $test_num = 1;

foreach my $module (@Core_Modules) {
    print "# $module compile failed\nnot " unless compile_module($module);
    print "ok $test_num\n";
    $test_num++;
}

# We do this as a separate process else we'll blow the hell
# out of our namespace.
sub compile_module {
    my ($module) = $_[0];
    
    return scalar `$^X "-Ilib" t/lib/compmod.pl $module` =~ /^ok/;
}


__DATA__
AnyDBM_File
AutoLoader
B
B::Debug
B::Deparse
B::ShowLex
B::Stash
Benchmark
CGI
CGI::Pretty
CGI::Util
Carp
Class::ISA
Class::Struct
Cwd
DB_File
Data::Dumper
Devel::DProf
Devel::Peek
Digest
Digest::MD5
DirHandle
Dumpvalue
Encode
English
Env
Errno
Exporter
Exporter::Heavy
Fatal
Fcntl
File::Basename
File::CheckTree
File::Copy
File::DosGlob
File::Find
File::Glob
File::Path
File::Spec
File::Spec::Functions
File::Temp
FileCache
FileHandle
Filter::Util::Call
FindBin
GDBM_File
Getopt::Long
Getopt::Std
IO::Dir
IO::File
IO::Handle
IO::Pipe
IO::Poll
IO::Seekable
IO::Select
IO::Socket
IO::Socket::INET
IO::Socket::UNIX
IPC::Open2
IPC::Open3
IPC::SysV
List::Util
Locale::Constants
Locale::Country
Locale::Currency
Locale::Language
MIME::Base64
MIME::QuotedPrint
Math::BigFloat
Math::BigInt
Math::Complex
Math::Trig
NDBM_File
Net::hostent
ODBM_File
Opcode
POSIX
Pod::Checker
Pod::Find
Pod::Text
Pod::Usage
SDBM_File
Safe
Scalar::Util
Search::Dict
SelectSaver
SelfLoader
Socket
Storable
Switch
Symbol
Sys::Hostname
Sys::Syslog
Term::ANSIColor
Test
Test::Harness
Test::ParseWords
Text::Abbrev
Text::Balanced
Text::ParseWords
Text::Soundex
Text::Tabs
Text::Wrap
Thread
Tie::Array
Tie::Handle
Tie::Hash
Tie::RefHash
Tie::Scalar
Tie::SubstrHash
Time::HiRes
Time::Local
Time::Piece
UNIVERSAL
XS::Typemap
attrs
base
bytes
charnames
constant
diagnostics
fields
integer
locale
ops
overload
strict
subs
utf8
vars
warnings
warnings::register

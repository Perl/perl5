#!./perl

BEGIN {
    chdir '..' if -d '../pod' && -d '../t';
    @INC = 'lib';
}

use strict;
use warnings;
use Config;

my %Core_Modules;
my %Test;

unless (open(MANIFEST, "MANIFEST")) {
    die "$0: failed to open 'MANIFEST': $!\n";
}

sub add_by_name {
    $Core_Modules{$_[0]}++;
}

while (<MANIFEST>) {
    if (m!^(lib)/(\S+?)\.pm\s!) {
	# Collecting modules names from under ext/ would be
	# rather painful since the mapping from filenames
	# to module names is not 100%.
	my ($dir, $module) = ($1, $2);
	$module =~ s!/!::!g;
	add_by_name($module);
    } elsif (m!^(lib|ext)/(\S+?)(?:\.t|/test.pl)\s!) {
	my ($dir, $test) = ($1, $2);
	$test =~ s!(\w+)/\1$!$1! if $dir eq 'ext';
	$test =~ s!/t/[^/]+$!!;
	$test =~ s!/!::!g;
	$Test{$test}++;
    }
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

delete_by_prefix('Attribute::Handlers');# we test this, and we have demos

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

unless (has_extension('NDBM_File')) {
    delete_by_name('Memoize::NDBM_File');
}

delete_by_prefix('unicode::');

# Delete all modules which have their own tests.
# This makes this test a lot faster.
foreach my $mod (sort keys %Test) {
    delete_by_name($mod);
}
foreach my $mod (<DATA>) {
    chomp $mod;
    print "### $mod\n" if exists $Test{$mod};
    delete_by_name($mod);
}

# Okay, this is the list.

my @Core_Modules = sort keys %Core_Modules;

print "1..".@Core_Modules."\n";

my $test_num = 1;

foreach my $module (@Core_Modules) {
    print "$module compile failed\nnot " unless compile_module($module);
    print "ok $test_num\n";
    $test_num++;
}

# We do this as a separate process else we'll blow the hell
# out of our namespace.
sub compile_module {
    my ($module) = $_[0];
    
    my $out = scalar `$^X "-Ilib" t/lib/compmod.pl $module`;
    print "# $out";
    return $out =~ /^ok/;
}

# Add here modules that have their own test scripts and therefore
# need not be test-compiled by 1_compile.t.
__DATA__
B::ShowLex
CGI::Apache
CGI::Carp
CGI::Cookie
CGI::Form
CGI::Pretty
CGI::Switch
CGI::Util
Carp::Heavy
Devel::DProf
Dumpvalue
Exporter::Heavy
ExtUtils::Constant
ExtUtils::MakeMaker
Filter::Util::Call
GDBM_File
I18N::LangTags::List
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
Locale::Constants
Locale::Country
Locale::Currency
Locale::Language
MIME::QuotedPrint
Math::BigFloat
Math::BigInt::Calc
Memoize::AnyDBM_File
Memoize::Expire
Memoize::ExpireFile
Memoize::ExpireTest
Memoize::NDBM_File
Memoize::SDBM_File
Memoize::Storable
NDBM_File
ODBM_File
Pod::Checker
Pod::Find
Pod::Text
Pod::Usage
SDBM_File
Safe
Scalar::Util
Sys::Syslog
Test::More
Test::ParseWords
Text::Tabs
Text::Wrap
Thread
Tie::Array
Tie::Handle
Tie::Hash
Tie::Scalar
Time::tm
UNIVERSAL
attributes
base
blib
bytes
ops
warnings::register

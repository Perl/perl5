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
    
    return scalar `./perl -Ilib t/lib/compmod.pl $module` =~ /^ok/;
}

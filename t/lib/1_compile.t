#!./perl

BEGIN {
    chdir '..' if -d '../pod' && -d '../t';
    @INC = 'lib';
}

use strict;
use warnings;
use Config;
use File::Find;

my %Core_Modules;

find(sub {
        if ($File::Find::name =~ m!^lib\W+(.+)\.pm$!i) {
	    my $module = $1;
	    $module =~ s/[^\w-]/::/g;
	    $Core_Modules{$module}++;
	}
    }, "lib");

# Delete stuff that can't be tested here.

sub delete_unless_in_extensions {
    delete $Core_Modules{$_[0]} unless $Config{extensions} =~ /\b$_[0]\b/;
}

foreach my $known_extension (split(' ', $Config{known_extensions})) {
    delete_unless_in_extensions($known_extension);
}

sub delete_by_prefix {
    delete @Core_Modules{grep { /^$_[0]/ } keys %Core_Modules};
}

delete $Core_Modules{'CGI::Fast'}; # won't load without FCGI

delete $Core_Modules{'Devel::DProf'}; # needs to be run as -d:DProf

delete_by_prefix('ExtUtils::MM_');	# ExtUtils::MakeMaker's domain

delete_by_prefix('File::Spec::');	# File::Spec's domain
$Core_Modules{'File::Spec::Functions'}++;	# put this back

unless ($Config{extensions} =~ /\bThread\b/) {
    delete $Core_Modules{Thread};
    delete_by_prefix('Thread::');
}

delete_by_prefix('unicode::');
$Core_Modules{'unicode::distinct'}++;	# put this back

# Okay, this is the list.

my @Core_Modules = sort keys %Core_Modules;

print "1..".@Core_Modules."\n";

my $test_num = 1;

foreach my $module (@Core_Modules) {
    print "# $module compile failed\nnot " unless compile_module($module);
    print "ok $test_num\n";
    $test_num++;
}


# We do this as a separate process else we'll blow the hell out of our
# namespace.
sub compile_module {
    my($module) = @_;
    
    return scalar `./perl -Ilib t/lib/compmod.pl $module` =~ /^ok/;
}

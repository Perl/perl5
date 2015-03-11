#!/usr/bin/perl

# Test important dependant modules so we don't accidentally half of CPAN.

use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => "Dependents only tested when releasing" unless $ENV{PERL_RELEASING};
}

require File::Spec;
use CPAN;

CPAN::HandleConfig->load;
$CPAN::Config->{test_report} = 0;

# Module which depend on Test::More to test
my @Modules = qw(
    Test::Tester
    Test::Most
    Test::Warn
    Test::Exception
    Test::Class
    Test::Deep
    Test::Differences
    Test::NoWarnings
);

# Modules which are known to be broken
my %Broken = map { $_ => 1 } (
    'Test::Most',
    'Test::Differences'
);

# Have to do it here because CPAN chdirs.
my $perl5lib = join ":", File::Spec->rel2abs("blib/lib"), File::Spec->rel2abs("lib");

TODO: for my $name (@ARGV ? @ARGV : @Modules) {
    local $TODO = "$name known to be broken" if $Broken{$name};
    local $ENV{PERL5LIB} = $perl5lib;

    my $module = CPAN::Shell->expand("Module", $name);
    $module->make;
    $module->test;
    my $test_result = $module->distribution->{make_test};
    ok( $test_result && !$test_result->failed, $name );
}
done_testing();

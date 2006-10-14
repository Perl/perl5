#!/usr/bin/perl -T

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}

use strict;
use Config;

BEGIN {
    eval "use Test::More";
    if ($@) {
        print "1..0 # Skip: Test::More not available\n";
        die "Test::More not available\n";
    }
}


my %modules = (
    # ModuleName  => q|code to check that it was loaded|,
    'Cwd'        => q| ::can_ok( 'Cwd' => 'fastcwd'         ) |,  # 5.7 ?
    'File::Glob' => q| ::can_ok( 'File::Glob' => 'doglob'   ) |,  # 5.6
    'SDBM_File'  => q| ::can_ok( 'SDBM_File' => 'TIEHASH'   ) |,  # 5.0
    'Socket'     => q| ::can_ok( 'Socket' => 'inet_aton'    ) |,  # 5.0
    'Time::HiRes'=> q| ::can_ok( 'Time::HiRes' => 'usleep'  ) |,  # 5.7.3
);

plan tests => keys(%modules) * 3 + 5;

# Try to load the module
use_ok( 'XSLoader' );

# Check functions
can_ok( 'XSLoader' => 'load' );
can_ok( 'XSLoader' => 'bootstrap_inherit' );

# Check error messages
eval { XSLoader::load() };
like( $@, '/^XSLoader::load\(\'Your::Module\', \$Your::Module::VERSION\)/',
        "calling XSLoader::load() with no argument" );

eval q{ package Thwack; XSLoader::load('Thwack'); };
like( $@, q{/^Can't locate loadable object for module Thwack in @INC/},
        "calling XSLoader::load() under a package with no XS part" );

# Now try to load well known XS modules
my $extensions = $Config{'extensions'};
$extensions =~ s|/|::|g;

for my $module (sort keys %modules) {
    SKIP: {
        skip "$module not available", 3 if $extensions !~ /\b$module\b/;

        eval qq{ package $module; XSLoader::load('$module', "qunckkk"); };
        like( $@, "/^$module object version \\S+ does not match bootstrap parameter (?:qunckkk|0\\.000)/",  
                "calling XSLoader::load() with a XS module and an incorrect version" );

        eval qq{ package $module; XSLoader::load('$module'); };
        is( $@, '',  "XSLoader::load($module)");

        eval qq{ package $module; $modules{$module}; };
    }
}


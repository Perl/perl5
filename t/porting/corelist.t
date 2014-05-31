#!perl -w

# Check that the current version of perl exists in Module-CoreList data

use TestInit qw(T);
use strict;
use Config;

require 't/test.pl';

plan(tests => 9);

use_ok('Module::CoreList');
use_ok('Module::CoreList::Utils');
use_ok('Module::CoreList::TieHashDelta');

{
  no warnings 'once';
  ok( defined $Module::CoreList::released{ $] }, "$] exists in released" );
  ok( defined $Module::CoreList::version{ $] }, "$] exists in version" );
  ok( defined $Module::CoreList::Utils::utilities{$] }, "$] exists in Utils" );
}

#plan skip_all => 'Special case v5.21.1 because rjbs' if sprintf("v%vd", $^V) eq 'v5.21.1';

my @modules = qw[
  Module::CoreList
  Module::CoreList::Utils
  Module::CoreList::TieHashDelta
];

SKIP: {
  skip('Special case v5.21.1 because rjbs', 3) if sprintf("v%vd", $^V) eq 'v5.21.1';
  foreach my $mod ( @modules ) {
    my $vers = eval $mod->VERSION;
    ok( !( $vers < $] || $vers > $] ), "$mod version should match perl version in core" )
      or diag("$mod $vers doesn't match $]");
  }
}

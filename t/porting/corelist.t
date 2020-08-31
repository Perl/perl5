#!perl -w

# Check that the current version of perl exists in Module-CoreList data

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    unshift (@INC, '..') if -f '../TestInit.pm';
    require Config; Config->import;
}

use TestInit qw(T);
plan(tests => 5);

use_ok('Module::CoreList');
use_ok('Module::CoreList::Utils');

{
  no warnings 'once';
  ok( defined $Module::CoreList::released{ $] }, "$] exists in released" );
  ok( defined $Module::CoreList::version{ $] }, "$] exists in version" );
  ok( defined $Module::CoreList::Utils::utilities{$] }, "$] exists in Utils" );
}

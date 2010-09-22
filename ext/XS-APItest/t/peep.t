#!perl

use strict;
use warnings;
use Test::More tests => 9;

use XS::APItest;

my $record = XS::APItest::peep_record;
my $rrecord = XS::APItest::rpeep_record;

# our peep got called and remembered the string constant
XS::APItest::peep_enable;
eval q[my $foo = q/affe/];
XS::APItest::peep_disable;

is(scalar @{ $record }, 1);
is(scalar @{ $rrecord }, 1);
is($record->[0], 'affe');
is($rrecord->[0], 'affe');


# peep got called for each root op of the branch
$::moo = $::moo = 0;
XS::APItest::peep_enable;
eval q[my $foo = $::moo ? q/x/ : q/y/];
XS::APItest::peep_disable;

is(scalar @{ $record }, 1);
is(scalar @{ $rrecord }, 2);
is($record->[0], 'y');
is($rrecord->[0], 'x');
is($rrecord->[1], 'y');

#!/usr/bin/perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use Test::Builder;
my $Test = Test::Builder->new;

$Test->plan( tests => 4 );

my $default_lvl = $Test->level;
$Test->level(0);

$Test->ok( 1,  'compiled and new()' );
$Test->ok( $default_lvl == 1,      'level()' );

$Test->is_eq('foo', 'foo',      'is_eq');
$Test->is_num('23.0', '23',     'is_num');


#!./perl

# Test // and friends.

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

package main;
require './test.pl';

plan( tests => 9 );

my($x);

$x=1;
is($x // 0, 1,		'	// : left-hand operand defined');

$x = undef;
is($x // 1, 1, 		'	// : left-hand operand undef');

$x='';
is($x // 0, '',		'	// : left-hand operand defined but empty');

$x=1;
is(($x err 0), 1,	'	err: left-hand operand defined');

$x = undef;
is(($x err 1), 1, 	'	err: left-hand operand undef');

$x='';
is(($x err 0), '',	'	err: left-hand operand defined but empty');

$x=undef;
$x //= 1;
is($x, 1, 		'	//=: left-hand operand undefined');

$x //= 0;
is($x, 1, 		'	//=: left-hand operand defined');

$x = '';
$x //= 0;
is($x, '', 		'	//=: left-hand operand defined but empty');

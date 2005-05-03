#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

plan tests => 6;

# compile time evaluation

$s = sqrt(2);
is(substr($s,0,5), '1.414');

$s = exp(1);
is(substr($s,0,7), '2.71828');

ok(exp(log(1)) == 1);

# run time evaluation

$x1 = 1;
$x2 = 2;
$s = sqrt($x2);
is(substr($s,0,5), '1.414');

$s = exp($x1);
is(substr($s,0,7), '2.71828');

ok(exp(log($x1)) == 1);

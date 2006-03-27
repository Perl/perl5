#!./perl

BEGIN {
    chdir 't';
    @INC = '../lib';
    require './test.pl';
}
use strict;
use warnings;

plan (8);

# Historically constant folding was performed by evaluating the ops, and if
# they threw an exception compilation failed. This was seen as buggy, because
# even illegal constants in unreachable code would cause failure. So now
# illegal expressions are reported at runtime, if the expression is reached,
# making constant folding consistent with many other languages, and purely an
# optimisation rather than a behaviour change.

my $a;
$a = eval '$b = 0/0 if 0; 3';
is ($a, 3);
is ($@, "");

my $b = 0;
$a = eval 'if ($b) {return sqrt -3} 3';
is ($a, 3);
is ($@, "");

$a = eval q{
	$b = eval q{if ($b) {return log 0} 4};
 	is ($b, 4);
	is ($@, "");
	5;
};
is ($a, 5);
is ($@, "");


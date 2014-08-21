#!./perl

# Simple tests for the basic math functions.

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

plan tests => 32;

# compile time evaluation

eval { $s = sqrt(-1) }; # Kind of compile time.
like($@, qr/sqrt of -1/, 'compile time sqrt(-1) fails');

$s = sqrt(0);
is($s, 0, 'compile time sqrt(0)');

$s = sqrt(1);
is($s, 1, 'compile time sqrt(1)');

$s = sqrt(2);
is(substr($s,0,5), '1.414', 'compile time sqrt(2) == 1.414');

$s = exp(0);
is($s, 1, 'compile time exp(0) == 1');

$s = exp(1);
is(substr($s,0,7), '2.71828', 'compile time exp(1) == e');

eval { $s = log(0) };  # Kind of compile time.
like($@, qr/log of 0/, 'compile time log(0) fails');

$s = log(1);
is($s, 0, 'compile time log(1) == 0');

$s = log(2);
is(substr($s,0,5), '0.693', 'compile time log(2)');

cmp_ok(exp(log(1)), '==', 1, 'compile time exp(log(1)) == 1');

# run time evaluation

$x0 = 0;
$x1 = 1;
$x2 = 2;

eval { $s = sqrt(-$x1) };
like($@, qr/sqrt of -1/, 'run time sqrt(-1) fails');

$s = sqrt($x0);
is($s, 0, 'run time sqrt(0)');

$s = sqrt($x1);
is($s, 1, 'run time sqrt(1)');

$s = sqrt($x2);
is(substr($s,0,5), '1.414', 'run time sqrt(2) == 1.414');

$s = exp($x0);
is($s, 1, 'run time exp(0) = 1');

$s = exp($x1);
is(substr($s,0,7), '2.71828', 'run time exp(1) = e');

eval { $s = log($x0) };
like($@, qr/log of 0/, 'run time log(0) fails');

$s = log($x1);
is($s, 0, 'compile time log(1) == 0');

$s = log($x2);
is(substr($s,0,5), '0.693', 'run time log(2)');

cmp_ok(exp(log($x1)), '==', 1, 'run time exp(log(1)) == 1');

# tests for transcendental functions

my $pi = 3.1415926535897931160;
my $pi_2 = 1.5707963267948965580;

sub round {
   my $result = shift;
   return sprintf("%.9f", $result);
}

# sin() tests
cmp_ok(sin(0), '==', 0.0, 'sin(0) == 0');
cmp_ok(round(sin($pi)), '==', 0.0, 'sin(pi) == 0');
cmp_ok(round(sin(-1 * $pi)), '==', 0.0, 'sin(-pi) == 0');
cmp_ok(round(sin($pi_2)), '==', 1.0, 'sin(pi/2) == 1');
cmp_ok(round(sin(-1 * $pi_2)), '==', -1.0, 'sin(-pi/2) == -1');

cmp_ok(round(sin($x1)), '==', '0.841470985', "sin(1)");

# cos() tests
cmp_ok(cos(0), '==', 1.0, 'cos(0) == 1');
cmp_ok(round(cos($pi)), '==', -1.0, 'cos(pi) == -1');
cmp_ok(round(cos(-1 * $pi)), '==', -1.0, 'cos(-pi) == -1');
cmp_ok(round(cos($pi_2)), '==', 0.0, 'cos(pi/2) == 0');
cmp_ok(round(cos(-1 * $pi_2)), '==', 0.0, 'cos(-pi/2) == 0');

cmp_ok(round(cos($x1)), '==', '0.540302306', "cos(1)");

# atan2() tests were removed due to differing results from calls to
# atan2() on various OS's and architectures.  See perlport.pod for
# more information.

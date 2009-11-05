use warnings;
use strict;

use Test::More tests => 13;

BEGIN { $^H |= 0x20000; }
no warnings;

my($t, $n);
$n = 5;

$t = undef;
eval q{
	use XS::APItest::KeywordRPN ();
	$t = rpn($n $n 1 + * 2 /);
};
isnt $@, "";

$t = undef;
eval q{
	use XS::APItest::KeywordRPN qw(rpn);
	$t = rpn($n $n 1 + * 2 /);
};
is $@, "";
is $t, 15;

$t = undef;
eval q{
	use XS::APItest::KeywordRPN qw(rpn);
	$t = join(":", "x", rpn($n $n 1 + * 2 /), "y");
};
is $@, "";
is $t, "x:15:y";

$t = undef;
eval q{
	use XS::APItest::KeywordRPN qw(rpn);
	$t = 1 + rpn($n $n 1 + * 2 /) * 10;
};
is $@, "";
is $t, 151;

$t = undef;
eval q{
	use XS::APItest::KeywordRPN qw(rpn);
	$t = rpn($n $n 1 + * 2 /);
	$t++;
};
is $@, "";
is $t, 16;

$t = undef;
eval q{
	use XS::APItest::KeywordRPN qw(rpn);
	$t = rpn($n $n 1 + * 2 /)
	$t++;
};
isnt $@, "";

$t = undef;
eval q{
	use XS::APItest::KeywordRPN qw(calcrpn);
	calcrpn $t { $n $n 1 + * 2 / }
	$t++;
};
is $@, "";
is $t, 16;

$t = undef;
eval q{
	use XS::APItest::KeywordRPN qw(calcrpn);
	123 + calcrpn $t { $n $n 1 + * 2 / } ;
};
isnt $@, "";

1;

use warnings;
use strict;

use Test::More tests => 18;

BEGIN { $^H |= 0x20000; }

my $t;

$t = "";
eval q{
	use XS::APItest qw(labelconst);
	$t .= "a";
	$t .= labelconst b:;
	$t .= "c";
};
is $@, "";
is $t, "abc";

$t = "";
eval q{
	use XS::APItest qw(labelconst);
	$t .= "a";
	$t .= "b" . labelconst FOO: . "c";
	$t .= "d";
};
is $@, "";
is $t, "abFOOcd";

$t = "";
eval q{
	use XS::APItest qw(labelconst);
	$t .= "a";
	$t .= labelconst FOO :;
	$t .= "b";
};
is $@, "";
is $t, "aFOOb";

$t = "";
eval q{
	use XS::APItest qw(labelconst);
	$t .= "a";
	$t .= labelconst F_1B:;
	$t .= "b";
};
is $@, "";
is $t, "aF_1Bb";

$t = "";
eval q{
	use XS::APItest qw(labelconst);
	$t .= "a";
	$t .= labelconst _AB:;
	$t .= "b";
};
is $@, "";
is $t, "a_ABb";

$t = "";
eval q{
	use XS::APItest qw(labelconst);
	no warnings;
	$t .= "a";
	$t .= labelconst 1AB:;
	$t .= "b";
};
isnt $@, "";
is $t, "";

$t = "";
eval q{
	use XS::APItest qw(labelconst);
	$t .= "a";
	$t .= labelconst :;
	$t .= "b";
};
isnt $@, "";
is $t, "";

$t = "";
eval q{
	use XS::APItest qw(labelconst);
	$t .= "a";
	$t .= labelconst ;
	$t .= "b";
};
isnt $@, "";
is $t, "";

$t = "";
$t = do("t/labelconst.aux");
is $@, "";
is $t, "FOOBARBAZQUUX";

1;

use warnings;
use strict;

use Test::More tests => 28;

BEGIN { $^H |= 0x20000; }

my $t;

$t = "";
eval q{
	use XS::APItest qw(swaplabel);
	$t .= "a";
	$t .= "b";
	swaplabel $t .= "c";
	swaplabel $t .= "d";
	$t .= "e";
};
is $@, "";
is $t, "abcde";

$t = "";
eval q{
	use XS::APItest qw(swaplabel);
	$t .= "a";
	Lb: $t .= "b";
	swaplabel $t .= "c"; Lc:
	swaplabel $t .= "d"; Ld:
	Le: $t .= "e";
};
is $@, "";
is $t, "abcde";

$t = "";
eval q{
	use XS::APItest qw(swaplabel);
	$t .= "a";
	goto Lb;
	Lb: $t .= "b";
	swaplabel $t .= "c"; Lc:
	swaplabel $t .= "d"; Ld:
	Le: $t .= "e";
};
is $@, "";
is $t, "abcde";

$t = "";
eval q{
	use XS::APItest qw(swaplabel);
	$t .= "a";
	goto Lc;
	Lb: $t .= "b";
	swaplabel $t .= "c"; Lc:
	swaplabel $t .= "d"; Ld:
	Le: $t .= "e";
};
is $@, "";
is $t, "acde";

$t = "";
eval q{
	use XS::APItest qw(swaplabel);
	$t .= "a";
	goto Ld;
	Lb: $t .= "b";
	swaplabel $t .= "c"; Lc:
	swaplabel $t .= "d"; Ld:
	Le: $t .= "e";
};
is $@, "";
is $t, "ade";

$t = "";
eval q{
	use XS::APItest qw(swaplabel);
	$t .= "a";
	goto Le;
	Lb: $t .= "b";
	swaplabel $t .= "c"; Lc:
	swaplabel $t .= "d"; Ld:
	Le: $t .= "e";
};
is $@, "";
is $t, "ae";

$t = "";
eval q{
	use XS::APItest qw(swaplabel);
	$t .= "a";
	swaplabel $t .= "b"; y:
	$t .= "c";
};
isnt $@, "";
is $t, "";

$t = "";
eval q{
	use XS::APItest qw(swaplabel);
	if(1) { $t .= "a"; }
	if(1) { $t .= "b"; }
	swaplabel if(1) { $t .= "c"; }
	swaplabel if(1) { $t .= "d"; }
	if(1) { $t .= "e"; }
};
is $@, "";
is $t, "abcde";

$t = "";
eval q{
	use XS::APItest qw(swaplabel);
	if(1) { $t .= "a"; }
	Lb: if(1) { $t .= "b"; }
	swaplabel if(1) { $t .= "c"; } Lc:
	swaplabel if(1) { $t .= "d"; } Ld:
	Le: if(1) { $t .= "e"; }
};
is $@, "";
is $t, "abcde";

$t = "";
eval q{
	use XS::APItest qw(swaplabel);
	if(1) { $t .= "a"; }
	goto Lb;
	Lb: if(1) { $t .= "b"; }
	swaplabel if(1) { $t .= "c"; } Lc:
	swaplabel if(1) { $t .= "d"; } Ld:
	Le: if(1) { $t .= "e"; }
};
is $@, "";
is $t, "abcde";

$t = "";
eval q{
	use XS::APItest qw(swaplabel);
	if(1) { $t .= "a"; }
	goto Lc;
	Lb: if(1) { $t .= "b"; }
	swaplabel if(1) { $t .= "c"; } Lc:
	swaplabel if(1) { $t .= "d"; } Ld:
	Le: if(1) { $t .= "e"; }
};
is $@, "";
is $t, "acde";

$t = "";
eval q{
	use XS::APItest qw(swaplabel);
	if(1) { $t .= "a"; }
	goto Ld;
	Lb: if(1) { $t .= "b"; }
	swaplabel if(1) { $t .= "c"; } Lc:
	swaplabel if(1) { $t .= "d"; } Ld:
	Le: if(1) { $t .= "e"; }
};
is $@, "";
is $t, "ade";

$t = "";
eval q{
	use XS::APItest qw(swaplabel);
	if(1) { $t .= "a"; }
	goto Le;
	Lb: if(1) { $t .= "b"; }
	swaplabel if(1) { $t .= "c"; } Lc:
	swaplabel if(1) { $t .= "d"; } Ld:
	Le: if(1) { $t .= "e"; }
};
is $@, "";
is $t, "ae";

$t = "";
eval q{
	use XS::APItest qw(swaplabel);
	if(1) { $t .= "a"; }
	swaplabel if(1) { $t .= "b"; } y:
	if(1) { $t .= "c"; }
};
isnt $@, "";
is $t, "";

1;

use warnings;
use strict;

use Test::More;

BEGIN { $^H |= 0x20000; }

my @t;

@t = ();
eval q{
	use experimental 'signatures';
	use XS::APItest qw(subsignature);
	push @t, (subsignature $x, $y);
	push @t, (subsignature $z, $);
	push @t, (subsignature @rest);
	push @t, (subsignature %rest);
	push @t, (subsignature $one = 1);

	# these should all appear empty
	push @t, (subsignature );
	push @t, (subsignature);
	push @t, (subsignature #empty
		    );
};
is $@, "";
is_deeply \@t, [
	['nextstate:4', 'multiparam:2..2:-:$x=0:$y=1' ],
	['nextstate:5', 'multiparam:2..2:-:$z=0:(anon)=1',],
	['nextstate:6', 'multiparam:0..0:@:@rest=*'],
	['nextstate:7', 'multiparam:0..0:%:%rest=*'],
	['nextstate:8', 'multiparam:0..1:-:$one=0?'],

	['nextstate:11', 'multiparam:0..0:-'],
	['nextstate:12', 'multiparam:0..0:-'],
	['nextstate:13', 'multiparam:0..0:-'],
];

done_testing;

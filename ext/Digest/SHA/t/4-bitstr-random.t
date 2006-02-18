use Test;
use strict;
use integer;
use Digest::SHA;

BEGIN {
	if ($ENV{PERL_CORE}) {
		chdir 't' if -d 't';
		@INC = '../lib';
	}
}

BEGIN { plan tests => 1 }

my $reps = 8000000;
my $bitstr = pack("B*", "11111111" x 127);
my $maxbits = 8 * 127;
my $state = Digest::SHA->new(1);
my $num;

while ($reps > $maxbits) {
	$num = int(rand($maxbits));
	$state->add_bits($bitstr, $num);
	$reps -= $num;
}
$state->add_bits($bitstr, $reps);

ok(
	$state->hexdigest,
	"559a512393dd212220ee080730d6f11644ba0222"
);

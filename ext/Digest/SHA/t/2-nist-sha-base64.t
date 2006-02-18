use Test;
use strict;
use integer;
use Digest::SHA qw(sha1_base64 sha224_base64 sha256_base64 sha384_base64 sha512_base64);

BEGIN {
	if ($ENV{PERL_CORE}) {
		chdir 't' if -d 't';
		@INC = '../lib';
	}
}

my(@vec, $data);

BEGIN {
	$data = "abc";
	@vec = (
\&sha1_base64, "qZk+NkcGgWq6PiVxeFDCbJzQ2J0",
\&sha224_base64, "Iwl9IjQF2CKGQqR3vaJVsyqtvOS9oLP342ydpw",
\&sha256_base64, "ungWv48Bz+pBQUDeXa4iI7ADYaOWF3qctBD/YfIAFa0",
\&sha384_base64, "ywB1P0WjXou1oD1pmsZQBycsMqsO3tFjGotgWkP/W+2AhgcroefMI1i67KE0yCWn",
\&sha512_base64, "3a81oZNherrMQXNJriBBMRLm+k6JqX6iCp7u5ktV05ohkpkqJ0/BqDa6PCOj/uu9RU1EI2Q86A4qmslPpUyknw"
	);

	plan tests => scalar(@vec) / 2;
}

my $fcn;
my $rsp;
my $skip;

while (@vec) {
	$fcn = shift(@vec);
	$rsp = shift(@vec);
	$skip = &$fcn("") ? 0 : 1;
	skip($skip, &$fcn($data), $rsp);
}

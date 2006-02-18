use Test;
use Digest::SHA qw(sha1);
use strict;
use integer;

BEGIN {
	if ($ENV{PERL_CORE}) {
		chdir 't' if -d 't';
		@INC = '../lib';
	}
}

my(@vec, @rsp);

BEGIN {

	@vec = ( "hello world" );

	@rsp = ( pack("H*", "2aae6c35c94fcfb415dbe95f408b9ce91ee846ed") );

	plan tests => scalar(@vec);

}

for (my $i = 0; $i < @vec; $i++) {
	ok(sha1($vec[$i]), $rsp[$i]);
}

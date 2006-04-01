#!./perl

BEGIN {
    chdir 't';
    @INC = ('../lib', 'lib');
}

use strict;
use warnings;
use Test::More tests => 5;

use mypragma (); # don't enable this pragma yet

BEGIN {
   is($^H{mypragma}, undef, "Shouldn't be in %^H yet");
}

is(mypragma::in_effect(), undef, "pragma not in effect yet");
{
    use mypragma;
    is(mypragma::in_effect(), 1, "pragma is in effect within this block");
}
is(mypragma::in_effect(), undef, "pragma no longer in effect");


BEGIN {
   is($^H{mypragma}, undef, "Should no longer be in %^H");
}

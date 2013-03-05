#!./perl

# Checks if the parser behaves correctly in edge case
# (including weird syntax errors)

BEGIN {
    require './test.pl';
}

use 5.016;
use utf8;
use open qw( :utf8 :std );

plan (tests => 5);

# ${single:colon} should not be valid syntax
{
    no strict;

    local $@;
    eval "\${\x{30cd}single:\x{30cd}colon} = 1";
    like($@,
         qr/syntax error .* near "\x{30cd}single:/,
         '${\x{30cd}single:\x{30cd}colon} should not be valid syntax'
        );

    local $@;
    no utf8;
    evalbytes '${single:colon} = 1';
    like($@,
         qr/syntax error .* near "single:/,
         '...same with ${single:colon}'
        );
}

# ${yadda'etc} and ${yadda::etc} should both work under strict
{
    local $@;
    eval q<use strict; ${flark::fleem}>;
    is($@, '', q<${package::var} works>);

    local $@;
    eval q<use strict; ${fleem'flark}>;
    is($@, '', q<...as does ${package'var}>);
}

# The first character in ${...} should respect the rules
TODO: {
   local $::TODO = "Fixed by the next commit";
   local $@;
   use utf8;
   eval '${☭asd} = 1';
   like($@, qr/\QUnrecognized character/, q(the first character in ${...} isn't special))
}

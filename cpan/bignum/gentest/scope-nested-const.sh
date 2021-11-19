#!/bin/sh
# -*- mode: cperl; coding: utf-8-unix; -*-

eval 'exec ${PERL-perl} -Sx "$0" ${1+"$@"}'
  if 0;

#!perl
#line 9

use strict;
use warnings;

use Algorithm::Combinatorics 'permutations';

my $data = [
            ['bigint', 'Math::BigInt'  ],
            ['bignum', 'Math::BigFloat'],
            ['bigrat', 'Math::BigRat'  ],
           ];

print <<"EOF";
#!perl

use strict;
use warnings;

use Test::More tests => 48;
EOF

my $iter = permutations([0, 1, 2]);
while (my $idxs = $iter -> next()) {

    my $p0 = $data -> [ $idxs -> [0] ][0];
    my $c0 = $data -> [ $idxs -> [0] ][1];
    my $p1 = $data -> [ $idxs -> [1] ][0];
    my $c1 = $data -> [ $idxs -> [1] ][1];
    my $p2 = $data -> [ $idxs -> [2] ][0];
    my $c2 = $data -> [ $idxs -> [2] ][1];

    print <<"EOF";

note "\\n$p0 -> $p1 -> $p2\\n\\n";

{
    note "use $p0;";
    use $p0;
    is(ref(1), "$c0");

    {
        note "use $p1;";
        use $p1;
        is(ref(1), "$c1");

        {
            note "use $p2;";
            use $p2;
            is(ref(1), "$c2");

            note "no $p2;";
            no $p2;
            is(ref(1), "");
        }

        is(ref(1), "$c1");

        note "no $p1;";
        no $p1;
        is(ref(1), "");
    }

    is(ref(1), "$c0");

    note "no $p0;";
    no $p0;
    is(ref(1), "");
}
EOF
}

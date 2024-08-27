#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use strict;

require './test.pl';

plan(1);

$ENV{PERL5OPT} = "-Mlib=optm1 -Iopti1 -Mlib=optm2 -Iopti2";
$ENV{PERL5LIB} = "e1:e2";

# this isn't *quite* identical to what's in perlrun.pod, because
# test.pl:_create_runperl adds -I../lib and -I.
like(runperl(switches => [qw(-Ii1 -Mlib=m1 -Ii2 -Mlib=m2)], prog => 'print join(chr(32), @INC)'),
     qr{^\Qoptm2 optm1 m2 m1 opti2 opti1 ../lib . i1 i2 e1 e2 \E},
     "Order of application of -I and -M matches documentation");

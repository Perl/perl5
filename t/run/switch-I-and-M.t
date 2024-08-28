#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use strict;
use Config;

require './test.pl';

plan(2);

# first test using -Margs ...
$ENV{PERL5OPT} = "-Mlib=optm1 -Iopti1 -Mlib=optm2 -Iopti2";
$ENV{PERL5LIB} = join($Config{path_sep}, qw(e1 e2));

# this isn't *quite* identical to what's in perlrun.pod, because
# test.pl:_create_runperl adds -I../lib and -I.
like(runperl(switches => [qw(-Ii1 -Mlib=m1 -Ii2 -Mlib=m2)], prog => 'print join(q( ), @INC)'),
     qr{^\Qoptm2 optm1 m2 m1 opti2 opti1 ../lib . i1 i2 e1 e2\E\b},
     "Order of application of -I and -M matches documentation");

# and now using -M args with a space. NB that '-M foo' isn't supported
# in PERL5OPT, just like how '-I foo' isn't.
like(runperl(switches => [qw(-Ii1 -M lib=m1 -Ii2 -M lib=m2)], prog => 'print join(q( ), @INC)', stderr => 1),
     qr{^\Qoptm2 optm1 m2 m1 opti2 opti1 ../lib . i1 i2 e1 e2\E\b},
     "Order of application of -I and -M matches documentation when -M has a space");

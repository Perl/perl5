#!./perl

use strict;
use warnings;

BEGIN {
    unless (-d 'blib') {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More;

plan tests => 8;

{
    package MRO_A;
    our @ISA = qw//;
    package MRO_B;
    our @ISA = qw//;
    package MRO_C;
    our @ISA = qw//;
    package MRO_D;
    our @ISA = qw/MRO_A MRO_B MRO_C/;
    package MRO_E;
    our @ISA = qw/MRO_A MRO_B MRO_C/;
    package MRO_F;
    our @ISA = qw/MRO_D MRO_E/;
}

is(mro::get_mro('MRO_F'), 'dfs');
is_deeply(mro::get_linear_isa('MRO_F'),
    [qw/MRO_F MRO_D MRO_A MRO_B MRO_C MRO_E/]
);
mro::set_mro('MRO_F', 'c3');
is(mro::get_mro('MRO_F'), 'c3');
is_deeply(mro::get_linear_isa('MRO_F'),
    [qw/MRO_F MRO_D MRO_E MRO_A MRO_B MRO_C/]
);

my @isarev = sort { $a cmp $b } mro::get_isarev('MRO_B');
is_deeply(\@isarev,
    [qw/MRO_D MRO_E MRO_F/]
);

ok(!mro::is_universal('MRO_B'));

@UNIVERSAL::ISA = qw/MRO_F/;
ok(mro::is_universal('MRO_B'));

@UNIVERSAL::ISA = ();
ok(mro::is_universal('MRO_B'));

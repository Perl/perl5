#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

is( _num_to_alpha(-1), undef);
is( _num_to_alpha( 0), 'A');
is( _num_to_alpha( 1), 'B');

is( _num_to_alpha(26 - 1), 'Z');
is( _num_to_alpha(26    ), 'AA');
is( _num_to_alpha(26 + 1), 'AB');

is( _num_to_alpha(26 + 26 - 2), 'AY');
is( _num_to_alpha(26 + 26 - 1), 'AZ');
is( _num_to_alpha(26 + 26    ), 'BA');
is( _num_to_alpha(26 + 26 + 1), 'BB');

is( _num_to_alpha(26 ** 2 - 1), 'YZ');
is( _num_to_alpha(26 ** 2    ), 'ZA');
is( _num_to_alpha(26 ** 2 + 1), 'ZB');

is( _num_to_alpha(26 ** 2 + 26 - 1), 'ZZ');
is( _num_to_alpha(26 ** 2 + 26    ), 'AAA');
is( _num_to_alpha(26 ** 2 + 26 + 1), 'AAB');

is( _num_to_alpha(26 ** 3 + 26 ** 2 + 26 - 1 ), 'ZZZ');
is( _num_to_alpha(26 ** 3 + 26 ** 2 + 26     ), 'AAAA');
is( _num_to_alpha(26 ** 3 + 26 ** 2 + 26 + 1 ), 'AAAB');

done_testing();

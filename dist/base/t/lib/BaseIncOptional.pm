package BaseIncOptional;

BEGIN { package main;
    isnt $INC[-1], '.', 'no trailing dot in @INC during optional module load from base';
    is 0+(grep ref eq 'CODE', @INC), 2, '... but the expected dummy hook';
}

use lib 't/lib/on-head';

push @INC, 't/lib/on-tail';

1;

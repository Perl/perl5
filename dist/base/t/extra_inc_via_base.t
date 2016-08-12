#!/usr/bin/perl -w

use strict;
use Test::More tests => 10;  # one test is in each BaseInc* itself

use lib qw(t/lib);

# make it look like an older perl
BEGIN {
    push @INC, '.'
        if $INC[-1] ne '.';
}

use base 'BaseIncExtender';

BEGIN {
    is $INC[0], 't/libleblab', 'Expected head @INC adjustment from within `use base`';
    is $INC[1], 't/lib', 'Preexisting @INC adjustment still in @INC';
    is $INC[-1], '.', 'Trailing . still in @INC ater `use base`'; 
}

use base 'BaseIncDoubleExtender';

BEGIN {
    is $INC[0], 't/libloblub', 'Expected head @INC adjustment from within `use base`';
    is $INC[1], 't/libleblab', 'Preexisting @INC adjustment still in @INC';
    is $INC[2], 't/lib', 'Preexisting @INC adjustment still in @INC';
    cmp_ok $INC[-2], 'ne', '.', 'Trailing . not reinserted erroneously'; 
    is $INC[-1], 't/libonend', 'Expected tail @INC adjustment from within `use base`';
}

package BaseIncOptional;

BEGIN { package main;
    is $INC[-1], '.', 'trailing dot remains in @INC during optional module load from base';
    is 0+(grep ref eq 'CODE', @INC), 3, '... but the expected extra hooks';
    delete $INC{'t/lib/Dummy.pm'};
    ok eval('require t::lib::Dummy'), '... however they do not prevent loading modules from .' or diag "$@";
    isnt 0+(grep ref eq 'CODE', @INC), 3, '... which auto-removes the dot-hiding hook';
}

use lib 't/lib/on-head';

push @INC, 't/lib/on-tail';

1;

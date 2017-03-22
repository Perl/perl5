package BaseIncDoubleExtender;

BEGIN {
    ::ok(
        ( $INC[-1] ne '.' ),
        '. not at @INCs tail during `use base ...`',
    );
}

use lib 't/libloblub';

push @INC, 't/libonend';

1;

package BaseIncExtender;

BEGIN {
    ::ok(
        ( $INC[-1] ne '.' ),
        '. not at @INCs tail during `use base ...`',
    );
}

use lib 't/libleblab';

1;

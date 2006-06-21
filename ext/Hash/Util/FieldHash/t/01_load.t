#!perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use strict; use warnings;

use Test::More tests => 8;

# see that Hash::Util::FieldHash and Hash::Util load and export what
# they should

# note to self: this test only works in the perl build environment,
# not in my homely test environment (haven't got the right Hash::Util.pm
# there).  mask it.

BEGIN {
    use_ok( 'Hash::Util');
    ok( defined( &Hash::Util::lock_keys), "Hash::Util::lock_keys found");
    ok( !defined( &Hash::Util::FieldHash::fieldhashes),
        "Hash::Util::FieldHash not loaded",
    );
}

package one;
use Test::More;
use Hash::Util qw( lock_keys);
BEGIN {
    ok( defined( &lock_keys), "lock_keys imported from Hash::Util");
}

use Hash::Util qw( fieldhashes);
BEGIN {
    ok( defined( &Hash::Util::FieldHash::fieldhashes),
        "Hash::Util::FieldHash loaded",
    );
    ok( defined( &fieldhashes),
        "fieldhashes imported from Hash::Util",
    );
}

package two;
use Test::More;
use Hash::Util::FieldHash qw( fieldhashes);
BEGIN {
    ok( defined( &fieldhashes),
        "fieldhashes imported from Hash::Util::FieldHash",
    );
}

use Hash::Util::FieldHash qw( :all);
BEGIN {
    ok( defined( &fieldhash),
        "fieldhash imported from Hash::Util::FieldHash via :all",
    );
}


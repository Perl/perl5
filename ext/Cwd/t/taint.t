#!./perl -Tw
# Testing Cwd under taint mode.

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use Cwd;
use Test::More tests => 2;

# The normal kill() trick is not portable.
sub is_tainted { 
    return ! eval { eval("#" . substr(join("", @_), 0, 0)); 1 };
}

my $cwd;
eval { $cwd = getcwd; };
is( $@, '',                 'getcwd() does not explode under taint mode' );
ok( is_tainted($cwd),       "it's return value is tainted" );


#!./perl

BEGIN {
    chdir '..' if -d '../pod' && -d '../t';
    @INC = 'lib';
}

use Test::More tests => 2;

BEGIN { use_ok('diagnostics') }

require base;

eval {
    'base'->import(qw(I::do::not::exist));
};

is( $@, '',   'diagnostics not tripped up by "use base qw(Dont::Exist)"' );

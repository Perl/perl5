### Module::Load test suite ###
BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir '../lib/Module/Load' if -d '../lib/Module/Load';
        unshift @INC, '../../..';
    }
}

BEGIN { chdir 't' if -d 't' }

use strict;
use lib qw[../lib to_load];
use Module::Load;
use Test::More 'no_plan';

### test loading files & modules
{   my @Map = (
        # module               flag diagnostic
        [q|Must::Be::Loaded|,   1,  'module'],
        [q|::Must::Be::Loaded|, 1,  'module'],
        [q|LoadIt|,             1,  'ambiguous module'  ],
    );

    for my $aref (@Map) {
        my($mod, $flag, $diag) = @$aref;

        eval { Module::Load::load_module $mod };
        my $file = Module::Load::_to_file($mod, $flag);

        is( $@, '',                 qq[Loading $diag '$mod' $@] );
        ok( defined($INC{$file}),   qq[  '$file' found in \%INC] );
    }
}

### Test importing functions ###
{   my $mod     = 'TestModule';
    my @funcs   = qw[func1 func2];

    eval { Module::Load::load_module $mod, @funcs };
    is( $@, '', qq[Loaded exporter module '$mod'] );

    ### test if import gets called properly
    ok( $mod->imported,                 "   ->import() was called" );

    ### test if functions get exported
    for my $func (@funcs) {
        ok( $mod->can($func),           "   $mod->can( $func )" );
        ok( __PACKAGE__->can($func),    "   we ->can ( $func )" );
    }
}

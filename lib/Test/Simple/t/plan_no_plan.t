BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}

use Test::More;

BEGIN {
    if( !$ENV{HARNESS_ACTIVE} && $ENV{PERL_CORE} ) {
        plan skip_all => "Won't work with t/TEST";
    }
}

BEGIN {
    require Test::Harness;
}

# This feature requires a fairly new version of Test::Harness
if( $Test::Harness::VERSION < 2.03 ) {
    plan tests => 1;
    diag "Need Test::Harness 2.03 or up.  You have $Test::Harness::VERSION.";
    fail 'Need Test::Harness 2.03 or up';
    exit;
}

plan 'no_plan';

pass('Just testing');
ok(1, 'Testing again');

{
    my $warning = '';
    local $SIG{__WARN__} = sub { $warning = join "", @_ };
    SKIP: {
        skip 'Just testing skip with no_plan';
        fail("So very failed");
    }
    is( $warning, '', 'skip with no "how_many" ok with no_plan' );


    $warning = '';
    TODO: {
        todo_skip "Just testing todo_skip";

        fail("Just testing todo");
        die "todo_skip should prevent this";
        pass("Again");
    }
    is( $warning, '', 'skip with no "how_many" ok with no_plan' );
}

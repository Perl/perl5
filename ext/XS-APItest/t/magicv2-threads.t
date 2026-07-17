use strict;
use warnings;
use Config;

BEGIN {
    if( !$Config{usethreads} ) {
        require Test::More;
        Test::More::plan( skip_all => "No threads" );
    }
}

use XS::APItest;

# We must 'use threads' before 'use Test::More' so the test count sync works
use threads;
use Test::More;

# MgAUXSV cloning into thread
{
    my $sv;
    sv_magicv2_add($sv, empty => \(my $tmp = "orig-data"));

    threads->create(sub {
        my $auxsvref = MgAUXSV($sv, 'empty');
        is($$auxsvref, "orig-data", 'sv_magicv2_find_by_funcs sees auxsv inside thread');
        $$auxsvref = "new-data";
        is($$auxsvref, "new-data", 'can modify data inside thread');
    })->join;

    my $auxsvref = MgAUXSV($sv, 'empty');
    is($$auxsvref, "orig-data", 'sv_magicv2_find_by_funcs sees original auxsv in main');
}

# MgPTR cloning into thread
{
    my $sv;
    sv_magicv2_add($sv, empty => undef);
    mg_ptr_store($sv, 'empty', "ABCDE");

    threads->create(sub {
        is(MgPTR($sv, 'empty'), "ABCDE", 'sv_magicv2_find_by_funcs sees MgPTR cloned inside thread');

        MgPTR_write($sv, 'empty', "ZYXWV");
        is(MgPTR($sv, 'empty'), "ZYXWV", 'MgPTR can be updated inside thread');
    })->join;

    is(MgPTR($sv, 'empty'), "ABCDE", 'Original MgPTR is retained');
}

# MgKEYIV cloning into thread
{
    my $sv;
    sv_magicv2_add($sv, with_keyiv => undef);
    MgKEYIV_set($sv, with_keyiv => 12345);

    threads->create(sub {
        is(MgKEYIV($sv, 'with_keyiv'), 12345, 'MgKEYIV is set inside thread');

        MgKEYIV_set($sv, with_keyiv => 54321);
        is(MgKEYIV($sv, 'with_keyiv'), 54321, 'MgKEYIV can be updated inside thread');
    })->join;

    is(MgKEYIV($sv, 'with_keyiv'), 12345, 'Original MgKEYIV is retained');
}

# MgKEYSV cloning into thread
{
    my $sv;
    sv_magicv2_add($sv, with_keysv => undef);
    MgKEYSV_set($sv, with_keysv => "XYZ");

    threads->create(sub {
        is(MgKEYSV($sv, 'with_keysv'), "XYZ", 'MgKEYSV is set inside thread');

        MgKEYSV_set($sv, with_keysv => "ZYX");
        is(MgKEYSV($sv, 'with_keysv'), "ZYX", 'MgKEYSV can be updated inside thread');
    })->join;

    is(MgKEYSV($sv, 'with_keysv'), "XYZ", 'Original MgKEYSV is retained');
}

# MgUSERSTRUCT cloning into thread
{
    my $sv;
    sv_magicv2_add($sv, userstruct => undef);
    sv_magicv2_set_userstruct($sv, 76, 54);

    threads->create(sub {
        is_deeply([sv_magicv2_get_userstruct($sv)], [76, 54],
            'Userstruct data copied into thread');

        sv_magicv2_set_userstruct($sv, 87, 65);
        is_deeply([sv_magicv2_get_userstruct($sv)], [87, 65],
            'Userstruct data can be updated inside thread');
    })->join;

    is_deeply([sv_magicv2_get_userstruct($sv)], [76, 54],
        'Original userstruct data is retained');
}

# clone trigger is invoked
{
    my $sv;
    sv_magicv2_add($sv, inc_on_clone => \(my $counter = 1));

    threads->create(sub {
        is($counter, 2, '$counter is 2 inside thread');
    })->join;

    is($counter, 1, '$counter remains 1 in main');
}

done_testing();

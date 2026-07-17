use strict;
use warnings;
use Test::More;

use XS::APItest;

# MgPRIV storage
{
    my $sv;
    sv_magicv2_add($sv, empty => undef, 1234);
    is(MgPRIV($sv, 'empty'), 1234, 'sv_magicv2_find retrieves MgPRIV value');
}

# MgAUXSV refcounting
{
    my $auxsv;
    {
        my $sv;
        sv_magicv2_add($sv, empty => \$auxsv);

        ok(sv_magicv2_exists($sv, 'empty'), 'sv_magicv2_exists finds empty magic');

        is(Internals::SvREFCNT($auxsv), 2, '$auxsv has refcount 2 before drop');

        ok(sv_magicv2_exists_by_auxsv($sv, \$auxsv), 'sv_magicv2_exists_by_auxsv finds magic');
    }
    is(Internals::SvREFCNT($auxsv), 1, '$auxsv has refcount 1 after drop');

    # MgAUXSV_set can replace it
    {
        my $sv;
        sv_magicv2_add($sv, empty => \$auxsv);

        is(Internals::SvREFCNT($auxsv), 2, '$auxsv has refcount 2 before MgAUXSV_set');

        MgAUXSV_set($sv, empty => my $arr = []);

        is(MgAUXSV($sv, 'empty'), $arr, 'MgAUXSV_set has replaced aux SV');
        is(Internals::SvREFCNT($auxsv), 1, '$auxsv has refcount 1 after MgAUXSV_set');
        is(Internals::SvREFCNT(@$arr), 2, '@$arr has refcount 2 after MgAUXSV_set');
    }
}

# MgAUXSV with WEAK_AUXSV
{
    my $auxsv;
    {
        my $sv;
        sv_magicv2_add($sv, weak => \$auxsv);

        ok(sv_magicv2_exists($sv, 'weak'), 'sv_magicv2_exists finds weak magic');

        is(Internals::SvREFCNT($auxsv), 1, '$auxsv has refcount 2 before drop');
    }
    is(Internals::SvREFCNT($auxsv), 1, '$auxsv has refcount 1 after drop');

    # MgAUXSV_set can replace it
    {
        my $sv;
        sv_magicv2_add($sv, weak => \$auxsv);

        is(Internals::SvREFCNT($auxsv), 1, '$auxsv has refcount 1 before MgAUXSV_set');

        MgAUXSV_set($sv, weak => my $arr = []);

        is(MgAUXSV($sv, 'weak'), $arr, 'MgAUXSV_set has replaced aux SV');
        is(Internals::SvREFCNT($auxsv), 1, '$auxsv has refcount 1 after MgAUXSV_set');
        is(Internals::SvREFCNT(@$arr), 1, '@$arr has refcount 1 after MgAUXSV_set');
    }
}

# MgPTR can store a byte buffer
{
    my $sv;
    sv_magicv2_add($sv, empty => undef);
    mg_ptr_store($sv, 'empty', "ABCDE");

    is(MgPTR($sv, 'empty'), "ABCDE", 'MgPTR can store a byte buffer');
}

# MgPTRLEN is usable on its own
{
    my $sv;
    sv_magicv2_add($sv, empty => undef);

    MgPTRLEN_set($sv, 'empty', 123456);
    is(MgPTRLEN($sv, 'empty'), 123456, 'MgPTRLEN is usable on its own');
}

# MgKEYIV
{
    my $sv;
    sv_magicv2_add($sv, with_keyiv => undef);

    is(MgKEYIV($sv, 'with_keyiv'), 0, 'MgKEYIV is zero initially');

    MgKEYIV_set($sv, with_keyiv => 12345);
    is(MgKEYIV($sv, 'with_keyiv'), 12345, 'MgKEYIV can be set to a value');
}

# MgKEYSV
{
    my $sv;
    sv_magicv2_add($sv, with_keysv => undef);

    is(MgKEYSV($sv, 'with_keysv'), undef, 'MgKEYSV is zero initially');

    MgKEYSV_set($sv, with_keysv => "XYZ");
    is(MgKEYSV($sv, 'with_keysv'), "XYZ", 'MgKEYSV can be set to a value');
}

# sv_magicv2_find
{
    my $sv;
    sv_magicv2_add($sv, empty => \"the auxsv data");
    my $auxsvref = MgAUXSV($sv, 'empty');
    is($$auxsvref, "the auxsv data", 'sv_magicv2_find can find magic structure');
    is(MgAUXSV_value($sv, 'empty'), "the auxsv data", 'MgAUXSV_value works');
    ok(!defined MgAUXSV($sv, 'inc_on_free'), 'sv_magicv2_find does not see wrong magic');
}

# Can add the same magic multiple times
{
    my $sv;
    sv_magicv2_add($sv, empty => \"data 1");
    sv_magicv2_add($sv, empty => \"data 2");
    # We don't guarantee what the order will be
    is_deeply([sort +MgAUXSV_values($sv, 'empty')], ["data 1", "data 2"],
        "MgAUXSV_values can see multiple auxsv");
}

# free trigger is invoked
{
    my $counter;
    {
        my $sv = 123;
        sv_magicv2_add($sv, inc_on_free => \$counter);
    }
    is $counter, 1, '$counter is now 1 after SV free';
}

# MgUSERSTRUCT can store more data
{
    my $sv;
    sv_magicv2_add($sv, userstruct => undef);

    is_deeply([sv_magicv2_get_userstruct($sv)], [123, 456],
        'Magic gets initialised with userstruct data');

    sv_magicv2_set_userstruct($sv, 987, 654);
    is_deeply([sv_magicv2_get_userstruct($sv)], [987, 654],
        'Userstruct data can be modified');
}

# Magic can be removed
{
    my $counter;
    my $sv = 123;
    sv_magicv2_add($sv, inc_on_free => \$counter);
    sv_magicv2_remove($sv, 'inc_on_free');
    is($counter, 1, '$counter is now 1 after sv_magicv2_remove');
}

# Removed magics don't disturb others
{
    my $counterA;
    my $counterB;
    {
        my $sv;
        sv_magicv2_add($sv, inc_on_free => \$counterA);
        sv_magicv2_add($sv, empty => \undef);
        sv_magicv2_add($sv, inc_on_free => \$counterB);

        sv_magicv2_remove($sv, 'empty');
    }
    is($counterA, 1, 'first inc_on_free trigger invoked after empty magic removed');
    is($counterB, 1, 'second inc_on_free trigger invoked after empty magic removed');
}

# Non-container magics do not persist through `local`
{
    my $auxsv;
    # we can't local'ise a lexical var
    my @var = (undef);
    sv_magicv2_add($var[0], empty => \$auxsv);

    {
        local $var[0];
        is(MgAUXSV($var[0], 'empty'), undef, 'sv_magicv2_find sees nothing while localised');
    }

    is(MgAUXSV($var[0], 'empty'), \$auxsv, 'sv_magicv2_find after SV restored');
}

# Container magics keep MgAUXSV across `local`
{
    my $auxsv;
    # we can't local'ise a lexical var
    my @var = (undef);
    sv_magicv2_add($var[0], container_empty => \$auxsv);

    {
        local $var[0];
        is(MgAUXSV($var[0], 'container_empty'), \$auxsv, 'sv_magicv2_find sees auxsv localised');
        is(Internals::SvREFCNT($auxsv), 3, '$auxsv has refcount 3 after local');
    }

    is(MgAUXSV($var[0], 'container_empty'), \$auxsv, 'sv_magicv2_find after SV restored');
}

# Container magics keep MgPTR across `local`
{
    # we can't local'ise a lexical var
    my @var = (undef);
    sv_magicv2_add($var[0], container_empty => undef);
    mg_ptr_store($var[0], 'container_empty' => "ABCDE");

    {
        local $var[0];
        is(MgPTR($var[0], 'container_empty'), "ABCDE", 'MgPTR copied on local');

        MgPTR_write($var[0], 'container_empty', "ZYXWV");
        is(MgPTR($var[0], 'container_empty'), "ZYXWV", 'MgPTR can be updated');
    }

    is(MgPTR($var[0], 'container_empty'), "ABCDE", 'Original MgPTR is retained');
}

# Container magics keep MgPTRLEN across `local`
{
    # we can't local'ise a lexical var
    my @var = (undef);
    sv_magicv2_add($var[0], container_empty => undef);
    MgPTRLEN_set($var[0], 'container_empty', 7654);

    {
        local $var[0];
        is(MgPTRLEN($var[0], 'container_empty'), 7654, 'MgPTRLEN copied on local');
    }
}

# Container magics keep MgKEYIV across `local`
{
    # we can't local'ise a lexical var
    my @var = (undef);
    sv_magicv2_add($var[0], with_keyiv => undef);
    MgKEYIV_set($var[0], 'with_keyiv', 7654);

    {
        local $var[0];
        is(MgKEYIV($var[0], 'with_keyiv'), 7654, 'MgKEYIV copied on local');
    }
}

# Container magics keep MgKEYSV across `local`
{
    # we can't local'ise a lexical var
    my @var = (undef);
    sv_magicv2_add($var[0], with_keysv => undef);
    MgKEYSV_set($var[0], 'with_keysv', "EFGH");

    {
        local $var[0];
        is(MgKEYSV($var[0], 'with_keysv'), "EFGH", 'MgKEYSV copied on local');
    }
}

# Container magics keep MgUSERSTRUCT across `local`
{
    # we can't local'ise a lexical var
    my @var = (undef);
    sv_magicv2_add($var[0], userstruct => undef);
    sv_magicv2_set_userstruct($var[0], 55, 66);

    {
        local $var[0];
        is_deeply([sv_magicv2_get_userstruct($var[0])], [55, 66],
            'Userstruct data copied on local');
    }
}

# Scalar Variable magics with 'post_set' function
{
    my $counter;
    my $sv = 123;
    sv_magicv2_add($sv, inc_after_set => \$counter);
    is $counter, undef, '$counter before SV modify';

    $sv = 456;
    is $counter, 1, '$counter after SV modify';

    undef $sv;
    is $counter, 2, '$counter after SV undef';

    my $counter2;
    sv_magicv2_add($sv, inc_after_set => \$counter2);
    $sv = 789;

    is $counter,  3, '$counter after SV modify';
    is $counter2, 1, '$counter2 after SV modify';
}

# Scalar Variable magics with 'pre_get' function
{
    my $shadow = 456;
    my $sv = 123;
    sv_magicv2_add($sv, grab_before_get => \$shadow);
    is $sv+0, 456, '$sv appears as a copy of $shadow';

    # length is weird in magic
    $shadow = "x" x 100;
    is length($sv), 100, 'length($sv) from shadow';
}

# Scalar Variable magics persist through `local`
{
    my $counter;
    # we can't local'ise a lexical var
    my @var = ( "a" );
    sv_magicv2_add($var[0], inc_after_set => \$counter);
    {
        local $var[0] = "b";
        # local + assign has bumped the counter twice
        is $counter, 2, '$counter after SV localised';

        $var[0] = "c";
        is $counter, 3, '$counter after SV modify when localised';
    }

    is $counter, 4, '$counter after SV restored';
}

# Variable magic can be removed while it is running
{
    my $counter;
    my $sv;
    sv_magicv2_add($sv, inc_after_set => \$counter, 1);

    $sv = 123;
    is $counter, 1, '$counter after SV modify with dispel';

    $sv = 456;
    is $counter, 1, '$counter after SV modify unchanged after dispel';
}

# Array Variable magics with 'clear' function
{
    my $counter;
    my @arr;
    sv_magicv2_add(@arr, inc_after_clear_arr => \$counter);

    undef @arr;
    is $counter, 1, '$counter after AV clear with undef';
}

# Hash Variable magics with 'clear' function
{
    my $counter;
    my %hash;
    sv_magicv2_add(%hash, inc_after_clear_hash => \$counter);

    undef %hash;
    is $counter, 1, '$counter after HV clear with undef';
}

done_testing;

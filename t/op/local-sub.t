#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc(  qw(. ../lib) );
}
plan tests => 3;

package Local::Sub {
    sub test_local_sub { 42 }

    my $got = join "-", (
        test_local_sub,
        do { local sub test_local_sub { 32 }; test_local_sub },
        test_local_sub
    );

    main::is ($got, "42-32-42", "local sub overrides existing sub");

    $got = join "-", (
        test_local_sub,
        do { local sub Local::Sub::test_local_sub { 21 }; test_local_sub },
        test_local_sub
    );

    main::is ($got, "42-21-42", "local sub overrides fully qualified sub");

    $got = join "-", (
        eval { &non_existing; } // 'before',
        eval { do { local sub test_local_sub { 42 }; test_local_sub } } // 'call',
        eval { &non_existing; } // 'after',
    );

    main::is ($got, "before-42-after", "local sub can locally define sub as well");
}

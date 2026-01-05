#!/usr/bin/perl
#
# 003-parse-file-scope-keywords.t:
#
# Test the parsing of XS file-scoped keywords. (N.B.: general file-scoped
# syntax is tested in 002-parse-file-scope.t)
#
# The tests in this file, and indeed in all 0xx-parse-foo.t files, only
# test parsing, and not compilation or execution of the C code. For the
# latter, see 3xx-run-foo.t files.

use strict;
use warnings;
use Test::More;
use File::Spec;
use lib (-d 't' ? File::Spec->catdir(qw(t lib)) : 'lib');

# Private test utilities
use TestMany;

require_ok( 'ExtUtils::ParseXS' );

# Borrow the useful heredoc quoting/indenting function.
*Q = \&ExtUtils::ParseXS::Q;

chdir('t') if -d 't';
push @INC, '.';

package ExtUtils::ParseXS;
our $DIE_ON_ERROR = 1;
our $AUTHOR_WARNINGS = 1;
package main;


{
    # Check for correct package name; i.e. use the current package name,
    # not the last one seen in the fil002-parse-file-scope.te.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
        |TYPEMAP: <<EOTM
        |foo_t T_FOO
        |INPUT
        |T_FOO
        |    $var = in_foo($arg, "$Package")
        |OUTPUT
        |T_FOO
        |    out_foo($arg, $var, "$Package")
        |EOTM
        |
EOF

    my @test_fns = (
        [
            'typemap: $Package: one package',
            Q(<<'EOF'),
                |foo_t foo(foo_t a1)
EOF

            [  0, qr{
                        foo_t \s+ \Qa1 = in_foo(ST(0), "Foo")\E
                        .*
                        \Qout_foo(RETVALSV, RETVAL, "Foo")\E
                      }smx,
                "has corrrect Package"
            ],
        ],
        [
            'typemap: $Package: two packages',
            Q(<<'EOF'),
                |foo_t foo(foo_t a1)
                |
                |MODULE = Foo PACKAGE = Foo::Bar
                |
                |int blah()
EOF

            [  0, qr{
                        foo_t \s+ \Qa1 = in_foo(ST(0), "Foo")\E
                        .*
                        \Qout_foo(RETVALSV, RETVAL, "Foo")\E
                      }smx,
                "has corrrect Package"
            ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Check for correct package name in boot code; i.e. use the current
    # package name, not the last one seen in the file.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            'attr: one package',
            Q(<<'EOF'),
                |int
                |foo()
                |ATTRS: myattr(x)
EOF

            [  0, qr{\Qapply_attrs_string("Foo", cv, "myattr(x)", 0)},
                "has corrrect package"
            ],
        ],
        [
            'attr: two packages',
            Q(<<'EOF'),
                |int
                |foo()
                |ATTRS: myattr(x)
                |
                |MODULE = Foo PACKAGE = Foo::Bar
                |
                |int blah()
EOF

            [  0, qr{\Qapply_attrs_string("Foo", cv, "myattr(x)", 0)},
                "has corrrect package"
            ],
        ],

        [
            'interface: one package',
            Q(<<'EOF'),
                |int
                |foo()
                |INTERFACE: abc
EOF

            [  0, qr{\QnewXS_deffile("Foo::abc", XS_Foo_foo)},
                "has corrrect package"
            ],
        ],
        [
            'interface: two packages',
            Q(<<'EOF'),
                |int
                |foo()
                |INTERFACE: abc
                |
                |MODULE = Foo PACKAGE = Foo::Bar
                |
                |int blah()
EOF

            [  0, qr{\QnewXS_deffile("Foo::abc", XS_Foo_foo)},
                "has corrrect package"
            ],
        ],

        [
            'overload: one package',
            Q(<<'EOF'),
                |int
                |foo()
                |OVERLOAD: cmp
EOF

            [  0, qr{\QnewXS_deffile("Foo::(cmp", XS_Foo_foo)},
                "has corrrect package"
            ],
        ],
        [
            'overload: two packages',
            Q(<<'EOF'),
                |int
                |foo()
                |OVERLOAD: cmp
                |
                |MODULE = Foo PACKAGE = Foo::Bar
                |
                |int blah()
EOF

            [  0, qr{\QnewXS_deffile("Foo::(cmp", XS_Foo_foo)},
                "has corrrect package"
            ],
        ],

    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}


{
    # Test reporting of bad syntax on MODULE lines.

    my $preamble = Q(<<'EOF');
EOF

    my @test_fns = (
        [
            '1st MODULE PKG',
            Q(<<'EOF'),
                |MODULE = X PKG = Y
                |
                |PROTOTYPES:  DISABLE
                |
EOF

            [ERR, qr{Error: unparseable MODULE line: 'MODULE = X PKG = Y'},
                "got expected err msg"
            ],
        ],
        [
            '1st MODULE colon',
            Q(<<'EOF'),
                |MODULE: X PACKAGE = Y
                |
                |PROTOTYPES:  DISABLE
                |
EOF

            [ERR, qr{Error: unparseable MODULE line: 'MODULE: X PACKAGE = Y'},
                "got expected err msg"
            ],
        ],
        [
            '2nd MODULE PKG',
            Q(<<'EOF'),
                |MODULE = Foo PACKAGE = Foo
                |
                |PROTOTYPES:  DISABLE
                |
                |MODULE = X PKG = Y
EOF

            [ERR, qr{Error: unparseable MODULE line: 'MODULE = X PKG = Y'},
                "got expected err msg"
            ],
        ],
        [
            '2nd MODULE colon',
            Q(<<'EOF'),
                |MODULE = Foo PACKAGE = Foo
                |
                |PROTOTYPES:  DISABLE
                |
                |MODULE: X PACKAGE = Y
EOF

            [ERR, qr{Error: unparseable MODULE line: 'MODULE: X PACKAGE = Y'},
                "got expected err msg"
            ],
        ],
    );

    test_many($preamble, undef, \@test_fns);
}


{
    # Test valid syntax of global-effect ENABLE/DISABLE keywords
    # except PROTOTYPES.
    #
    # Check that disallowed variants give errors and allowed variants
    # get as far as generating a boot XSUB

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "VERSIONCHECK: long word",
            Q(<<'EOF'),
                |VERSIONCHECK: ENABLEblah
EOF
            [ERR, qr{\QError: VERSIONCHECK: invalid value 'ENABLEblah' (should be ENABLE/DISABLE)}, "should die" ],
        ],
        [
            "VERSIONCHECK: trailing text",
            Q(<<'EOF'),
                |VERSIONCHECK: DISABLE blah # bloo +%
EOF
            [ERR, qr{\QError: VERSIONCHECK: invalid value 'DISABLE blah # bloo +%' (should be ENABLE/DISABLE)}, "should die" ],
        ],
        [
            "VERSIONCHECK: lower case",
            Q(<<'EOF'),
                |VERSIONCHECK: disable
EOF
            [ERR, qr{\QError: VERSIONCHECK: invalid value 'disable' (should be ENABLE/DISABLE)}, "should die" ],
        ],
        [
            "VERSIONCHECK: semicolon",
            Q(<<'EOF'),
                |VERSIONCHECK: DISABLE;
EOF
            [ERR, qr{\QError: VERSIONCHECK: invalid value 'DISABLE;' (should be ENABLE/DISABLE)}, "should die" ],
        ],

        [
            "EXPORT_XSUB_SYMBOLS: long word",
            Q(<<'EOF'),
                |EXPORT_XSUB_SYMBOLS: ENABLEblah
EOF
            [ERR, qr{\QError: EXPORT_XSUB_SYMBOLS: invalid value 'ENABLEblah' (should be ENABLE/DISABLE)}, "should die" ],
        ],
        [
            "EXPORT_XSUB_SYMBOLS: trailing text",
            Q(<<'EOF'),
                |EXPORT_XSUB_SYMBOLS: diSAble blah # bloo +%
EOF
            [ERR, qr{\QError: EXPORT_XSUB_SYMBOLS: invalid value 'diSAble blah # bloo +%' (should be ENABLE/DISABLE)}, "should die" ],
        ],
        [
            "EXPORT_XSUB_SYMBOLS: lower case",
            Q(<<'EOF'),
                |EXPORT_XSUB_SYMBOLS: disable
EOF
            [ERR, qr{\QError: EXPORT_XSUB_SYMBOLS: invalid value 'disable' (should be ENABLE/DISABLE)}, "should die" ],
        ],

        [
            "file SCOPE: long word",
            Q(<<'EOF'),
                |SCOPE: ENABLEblah
                |void
                |foo()
EOF
            [ERR, qr{\QError: SCOPE: invalid value 'ENABLEblah' (should be ENABLE/DISABLE)}, "should die" ],
        ],
        [
            "file SCOPE: lower case",
            Q(<<'EOF'),
                |SCOPE: enable
                |void
                |foo()
EOF
            [ERR, qr{\QError: SCOPE: invalid value 'enable' (should be ENABLE/DISABLE)}, "should die" ],
        ],

    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}


{
    # Test PROTOTYPES keyword. Note that there is a lot of
    # backwards-compatibility oddness in the keyword's value

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
EOF

    my @test_fns = (
        [
            "PROTOTYPES: ENABLE",
            Q(<<'EOF'),
                |PROTOTYPES: ENABLE
                |
                |void
                |foo(int a, int b)
EOF
            [  0, qr{newXSproto_portable.*"\$\$"}, "has proto" ],
        ],
        [
            "PROTOTYPES: ENABLED",
            Q(<<'EOF'),
                |PROTOTYPES: ENABLED
                |
                |void
                |foo(int a, int b)
EOF
            [  0, qr{newXSproto_portable.*"\$\$"}, "has proto" ],
            [ERR, qr{Warning: invalid PROTOTYPES value 'ENABLED' interpreted as ENABLE},
                    "got warning" ],
        ],
        [
            "PROTOTYPES: ENABLE;",
            Q(<<'EOF'),
                |PROTOTYPES: ENABLE;
                |
                |void
                |foo(int a, int b)
EOF
            [  0, qr{newXSproto_portable.*"\$\$"}, "has proto" ],
            [ERR, qr{Warning: invalid PROTOTYPES value 'ENABLE;' interpreted as ENABLE},
                    "got warning" ],
        ],

        [
            "PROTOTYPES: DISABLE",
            Q(<<'EOF'),
                |PROTOTYPES: DISABLE
                |
                |void
                |foo(int a, int b)
EOF
            [NOT, qr{"\$\$"}, "doesn't have proto" ],
        ],
        [
            "PROTOTYPES: DISABLED",
            Q(<<'EOF'),
                |PROTOTYPES: DISABLED
                |
                |void
                |foo(int a, int b)
EOF
            [NOT, qr{"\$\$"}, "doesn't have proto" ],
            [ERR, qr{Warning: invalid PROTOTYPES value 'DISABLED' interpreted as DISABLE},
                    "got warning" ],
        ],
        [
            "PROTOTYPES: DISABLE;",
            Q(<<'EOF'),
                |PROTOTYPES: DISABLE;
                |
                |void
                |foo(int a, int b)
EOF
            [NOT, qr{"\$\$"}, "doesn't have proto" ],
            [ERR, qr{Warning: invalid PROTOTYPES value 'DISABLE;' interpreted as DISABLE},
                    "got warning" ],
        ],

        [
            "PROTOTYPES: long word",
            Q(<<'EOF'),
                |PROTOTYPES: ENABLEblah
                |
                |void
                |foo(int a, int b)
EOF
            [ERR, qr{\QError: PROTOTYPES: invalid value 'ENABLEblah' (should be ENABLE/DISABLE)}, "should die" ],
        ],
        [
            "PROTOTYPES: trailing text",
            Q(<<'EOF'),
                |PROTOTYPES: ENABLE blah
                |
                |void
                |foo(int a, int b)
EOF
            [ERR, qr{\QError: PROTOTYPES: invalid value 'ENABLE blah' (should be ENABLE/DISABLE)}, "should die" ],
        ],
        [
            "PROTOTYPES: trailing text and comment)",
            Q(<<'EOF'),
                |PROTOTYPES: DISABLE blah # bloo +%
                |
                |void
                |foo(int a, int b)
EOF
            [ERR, qr{\QError: PROTOTYPES: invalid value 'DISABLE blah # bloo +%' (should be ENABLE/DISABLE)}, "should die" ],
        ],


    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}


{
    # Test BOOT keyword.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo::Bar PACKAGE = Foo::Bar
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "BOOT: basic'",
            Q(<<"EOF"),
                |BOOT:
                |
                |
                |  code1
                |  code2
                |
                |
                |
EOF
            [  0, qr{\Q#line 6 "(input)"\E\n\n\n  code1\n  code2\n\n#line},
            "seen code" ],
        ],
        [
            "Warn if junk after BOOT'",
            Q(<<"EOF"),
                |BOOT: blah
                |  codeline
EOF
            [  0, qr{\Q#line 6 "(input)"\E\n  codeline\n\n#line},
            "junk ignored" ],
            [ERR, qr{Warning: text after keyword ignored: 'blah'},
                    "should die" ],
        ],
    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}


{
    # Test TYPEMAP keyword.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "TYPEMAP: basic'",
            Q(<<'EOF'),
                |TYPEMAP: <<EOF
                |mytype T_MYTYPE
                |INPUT
                |T_MYTYPE
                |   $var = get_mytype($arg)
                |OUTPUT
                |T_MYTYPE
                |   set_mytype($arg, $var)
                |EOF
                |
                |mytype foo(mytype abc)
EOF
            [  0, qr{\Qmytype	abc = get_mytype(ST(0))}, "get" ],
            [  0, qr{set_mytype\(.*?, RETVAL\)},        "set" ],
        ],
        [
            "TYPEMAP: single quote'",
            Q(<<'EOF'),
                |TYPEMAP: <<' a.b+c'
                |mytype T_IV
                | a.b+c
                |
                |int foo(mytype abc)
EOF
            [  0, qr{\Qmytype	abc = (mytype)SvIV(ST(0))}, "get" ],
        ],
        [
            "TYPEMAP: double quote'",
            Q(<<'EOF'),
                |TYPEMAP: <<" a.b+c' "
                |mytype T_UV
                | a.b+c' 
                |
                |int foo(mytype abc)
EOF
            [  0, qr{\Qmytype	abc = (mytype)SvUV(ST(0))}, "get" ],
        ],
        [
            "line continuation directly after TYPEMAP",
            Q(<<'EOF'),
                |TYPEMAP: <<EOF
                |
                |foo_t T_FOO
                |
                |EOF
                |void foo(int i, \
                |         int j)
EOF

            [  0, qr{XS_Foo_foo}, "no errs" ],
        ],

        [
            # Prior to v5.43.5-157-gae3ec82909, xsubpp 3.61, a TYPEMAP
            # appearing *directly* after an XSUB affected that preceding
            # XSUB.
            #
            # [ This was due to TYPEMAPs being processed on the fly by
            # fetch_para(): while looking for the end of the XSUB,
            # it would process the following typemap, *then* return the
            # XSUB lines to be processed by the main loop. Thankfully
            # TYPEMAP is now handled as a normal keyword. ]

            "TYPEMAP after XSUB",
            Q(<<'EOF'),
                |int foo()
                |
                |TYPEMAP: <<EOF
                |int T_UV
                |EOF
EOF

            [NOT, qr{UV}, "no UV found" ],
        ],

        [
            'TYPEMAP syntax err',
            Q(<<'EOF'),
                |TYPEMAP: <EOF
                |
EOF

            [ERR, qr{Error: unparseable TYPEMAP line: 'TYPEMAP: <EOF'},
                "got expected err msg"
            ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test FALLBACK keyword.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo::Bar PACKAGE = Foo::Bar
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "FALLBACK: TRUE",
            Q(<<'EOF'),
                |FALLBACK: TRUE
                |
                |void
                |foo()
                |    OVERLOAD: cmp
EOF
            [  0, qr{newXS.*Foo::Bar::\(\).*XS_Foo__Bar_nil}, "has nil CV" ],
            [  0, qr{sv_setsv\(\n.*\n\s+&PL_sv_yes}, "sets true" ],
        ],
        [
            "FALLBACK: FALSE",
            Q(<<'EOF'),
                |FALLBACK: FALSE
                |
                |void
                |foo()
                |    OVERLOAD: cmp
EOF
            [  0, qr{newXS.*Foo::Bar::\(\).*XS_Foo__Bar_nil}, "has nil CV" ],
            [  0, qr{sv_setsv\(\n.*\n\s+&PL_sv_no}, "sets false" ],
        ],
        [
            "FALLBACK: UNDEF",
            Q(<<'EOF'),
                |FALLBACK: UNDEF
                |
                |void
                |foo()
                |    OVERLOAD: cmp
EOF
            [  0, qr{newXS.*Foo::Bar::\(\).*XS_Foo__Bar_nil}, "has nil CV" ],
            [  0, qr{sv_setsv\(\n.*\n\s+&PL_sv_undef}, "sets undef" ],
        ],
        [
            "FALLBACK: XYZ",
            Q(<<'EOF'),
                |FALLBACK: XYZ
                |
                |void
                |foo()
                |    OVERLOAD: cmp
EOF
            [ERR, qr{\QError: FALLBACK: invalid value 'XYZ' (should be TRUE/FALSE/UNDEF)},
                    "got err" ],
        ],
        [
            "FALLBACK: dup warning",
            Q(<<'EOF'),
                |FALLBACK: TRUE
                |FALLBACK: TRUE
                |
                |void
                |foo()
EOF
            [ERR, qr{\QWarning: duplicate FALLBACK: entry},
                    "got warning" ],
        ],
        [
            "FALLBACK: no dup warning",
            Q(<<'EOF'),
                |FALLBACK: TRUE
                |
                |MODULE = Foo::Bar PACKAGE = Baz
                |
                |FALLBACK: TRUE
                |
                |void
                |foo()
EOF
            # no errors expected
        ],
    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}


{
    # Test REQUIRE keyword.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo::Bar PACKAGE = Foo::Bar
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "REQUIRE: 1",
            Q(<<'EOF'),
                |REQUIRE: 1
EOF
            # not croaking is sufficient test here
        ],
        [
            "REQUIRE: 1.0",
            Q(<<'EOF'),
                |REQUIRE:    1.0   
EOF
            # not croaking is sufficient test here
        ],
        [
            "REQUIRE: 999999.9",
            Q(<<'EOF'),
                |REQUIRE: 999999.9
EOF
            [ERR, qr{\QError: xsubpp 999999.9 (or better) required--this is only},
                    "got err" ],
        ],
        [
            "REQUIRE: missing arg",
            Q(<<'EOF'),
                |REQUIRE:   
EOF
            [ERR, qr{\QError: REQUIRE expects a version number},
                    "got err" ],
        ],
        [
            "REQUIRE: bad arg",
            Q(<<'EOF'),
                |REQUIRE: abc
EOF
            [ERR, qr{\QError: REQUIRE: expected a MMM(.NNN) number, got 'abc'},
                    "got err" ],
        ],
        [
            "REQUIRE: bad arg trailing junk",
            Q(<<'EOF'),
                |REQUIRE: 3.0.0
EOF
            [ERR, qr{\QError: REQUIRE: expected a MMM(.NNN) number, got '3.0.0'},
                    "got err" ],
        ],
    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}


{
    # Test INCLUDE, INCLUDE_COMMAND keywords.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo::Bar PACKAGE = Foo::Bar
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (

        # INCLUDE working

        [
            "INCLUDE: basic",
            Q(<<'EOF'),
                |INCLUDE: XSInclude.xsh  
EOF
            [  0, qr{newXS.*\bXS_Foo__Bar_include_ok\b},
                    "included XSUB was processed" ],
        ],

        # INCLUDE errors

        [
            "INCLUDE: no filename",
            Q(<<'EOF'),
                |INCLUDE:   
EOF
            [ERR, qr{\QError: INCLUDE: filename missing},
                    "got err" ],
        ],
        [
            "INCLUDE: no pipe",
            Q(<<'EOF'),
                |INCLUDE: |foo
EOF
            [ERR, qr{\QError: INCLUDE: output pipe is illegal},
                    "got err" ],
        ],
        [
            "INCLUDE: no loop",
            Q(<<'EOF'),
                | # this file INCLUDEs itself
                |INCLUDE: XSloop.xsh
EOF
            [ERR, qr{\QError: INCLUDE: loop detected},
                    "got err" ],
        ],
        [
            "INCLUDE: no such file",
            Q(<<'EOF'),
                |INCLUDE: NoSuchFile.xsh
EOF
            [ERR, qr{\QError: INCLUDE: cannot open 'NoSuchFile.xsh': },
                    "got err" ],
        ],

        # INCLUDE_COMMAND working

        [
            "INCLUDE_COMMAND: basic",
            Q(<<'EOF'),
                |INCLUDE_COMMAND: $^X -Ilib -It/lib -MIncludeTester -e IncludeTester::print_xs
EOF
            [  0, qr{newXS.*\bXS_Foo__Bar_sum\b},
                    "included XSUB was processed" ],
        ],


        # INCLUDE_COMMAND errors

        [
            "INCLUDE_COMMAND: no command",
            Q(<<'EOF'),
                |INCLUDE_COMMAND:     
EOF
            [ERR, qr{\QError: INCLUDE_COMMAND: command missing},
                    "got err" ],
        ],
        [
            "INCLUDE_COMMAND: no pipe - on left",
            Q(<<'EOF'),
                |INCLUDE_COMMAND:   |  blah
EOF
            [ERR, qr{\QError: INCLUDE_COMMAND: pipes are illegal},
                    "got err" ],
        ],
        [
            "INCLUDE_COMMAND: no pipe - on right",
            Q(<<'EOF'),
                |INCLUDE_COMMAND:   blah  |   
EOF
            [ERR, qr{\QError: INCLUDE_COMMAND: pipes are illegal},
                    "got err" ],
        ],
        [
            "INCLUDE_COMMAND: non-zero exit",
            # the filler 'PROTOTYPES' lines before and after are to
            # check that the line number reported for the error is the
            # right one (previously it was using the last line of the
            # current paragraph + 1).
            Q(<<'EOF'),
                |PROTOTYPES: DISABLE
                |INCLUDE_COMMAND: $^X -e "exit(1)"
                |PROTOTYPES: DISABLE
                |PROTOTYPES: DISABLE
EOF
            [ERR, qr{\QError: INCLUDE_COMMAND: got return code 0x0100\E
                       \Q when reading from pipe '\E
                       .*
                       \Q' in (input), line 6\E}x,
                    "got err" ],
        ],
    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}


{
    # Test file-scoped keywords appearing in XSUB scope

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns;

    for my $kw (qw(
                    EXPORT_XSUB_SYMBOLS
                    PROTOTYPES
                    VERSIONCHECK
                    FALLBACK
                    INCLUDE
                    INCLUDE_COMMAND
                    REQUIRE
                    BOOT
                ))
    {
        push @test_fns,

        [
            "$kw not in file scope",
            Q(<<"EOF"),
                |int foo()
                |$kw: blah
EOF
            [ERR, qr{Error: misplaced '$kw:'}, "should die" ],
        ],
    }

    test_many($preamble, undef, \@test_fns);
}


done_testing;

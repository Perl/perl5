#!/usr/bin/perl
#
# 008-parse-xsub-keywords.t
#
# Test the parsing of the various keywords of an XSUB.
# Note that there is a separate test file for the INPUT and OUTPUT
# keywords.
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
    # Test ALIAS keyword - boot code

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "ALIAS basic",
            Q(<<'EOF'),
                |void
                |foo()
                |    ALIAS: foo = 1
                |           bar = 2
                |           Baz::baz = 3
                |           boz = BOZ_VAL
                |           buz => foo
                |           baz => buz
                |           biz => Baz::baz
EOF
            [  0, qr{"Foo::foo",.*\n.*= 1;},
                   "has Foo::foo" ],
            [  0, qr{"Foo::bar",.*\n.*= 2;},
                   "has Foo::bar" ],
            [  0, qr{"Baz::baz",.*\n.*= 3;},
                   "has Baz::baz" ],
            [  0, qr{"Foo::boz",.*\n.*= BOZ_VAL;},
                   "has Foo::boz" ],
            [  0, qr{"Foo::buz",.*\n.*= 1;},
                   "has Foo::buz" ],
            [  0, qr{"Foo::baz",.*\n.*= 1;},
                   "has Foo::baz" ],
            [  0, qr{"Foo::biz",.*\n.*= 3;},
                   "has Foo::biz" ],
            [  0, qr{\QCV * cv;}, "has cv declaration" ],
        ],

        [
            "ALIAS with main as default of 0",
            Q(<<'EOF'),
                |void
                |foo()
                |    ALIAS:
                |           bar = 2
                |           baz = foo
                |           boz = 0
EOF
            [  0, qr{"Foo::foo",.*\n.*= 0;},
                   "has Foo::foo" ],
            [  0, qr{"Foo::bar",.*\n.*= 2;},
                   "has Foo::bar" ],
            [  0, qr{"Foo::baz",.*\n.*= foo;},
                   "has Foo::baz" ],
            [  0, qr{"Foo::boz",.*\n.*= 0;},
                   "has Foo::boz" ],
            [ERR, qr{\QWarning: aliases 'boz' and 'foo' have identical\E
                     \Q values of 0 - the base function in (input), line 10\E
                    }x,
                   "got dup warning" ],
        ],

        [
            "ALIAS multi-perl-line, blank lines",
            Q(<<'EOF'),
                |void
                |foo()
                |    ALIAS:            foo   =    1       bar  =  2   
                |
                | Baz::baz  =  3      boz = BOZ_VAL
                |       buz =>                          foo
                |           biz => Baz::baz
                |   
                |
EOF
            [  0, qr{"Foo::foo",.*\n.*= 1;},
                   "has Foo::foo" ],
            [  0, qr{"Foo::bar",.*\n.*= 2;},
                   "has Foo::bar" ],
            [  0, qr{"Baz::baz",.*\n.*= 3;},
                   "has Baz::baz" ],
            [  0, qr{"Foo::boz",.*\n.*= BOZ_VAL;},
                   "has Foo::boz" ],
            [  0, qr{"Foo::buz",.*\n.*= 1;},
                   "has Foo::buz" ],
            [  0, qr{"Foo::biz",.*\n.*= 3;},
                   "has Foo::biz" ],
        ],

        [
            "ALIAS no colon",
            Q(<<'EOF'),
                |void
                |foo()
                |    ALIAS: bar = X::Y
EOF
            [ERR, qr{\QError: in alias definition for 'bar' the value may not contain ':' unless it is symbolic.\E.*line 7},
                   "got expected error" ],
        ],

        [
            "ALIAS unknown alias",
            Q(<<'EOF'),
                |void
                |foo()
                |    ALIAS: Foo::bar => blurt
EOF
            [ERR, qr{\QError: unknown alias 'Foo::blurt' in symbolic definition for 'Foo::bar'\E.*line 7},
                   "got expected error" ],
        ],

        [
            "ALIAS warn duplicate",
            Q(<<'EOF'),
                |void
                |foo()
                |    ALIAS: bar = 1
                |           bar = 1
EOF
            [ERR, qr{\QWarning: ignoring duplicate alias 'bar'\E.*line 8},
                   "got expected warning" ],
        ],
        [
            "ALIAS warn conflict duplicate",
            Q(<<'EOF'),
                |void
                |foo()
                |    ALIAS: bar = 1
                |           bar = 2
EOF
            [ERR, qr{\QWarning: conflicting duplicate alias 'bar'\E.*line 8},
                   "got expected warning" ],
        ],

        [
            "ALIAS warn identical values",
            Q(<<'EOF'),
                |void
                |foo()
                |    ALIAS: bar = 1
                |           baz = 1
EOF
            [ERR, qr{\QWarning: aliases 'baz' and 'bar' have identical values of 1\E.*line 8},
                   "got expected warning" ],
        ],

        [
            "ALIAS warn twin identical values",
            Q(<<'EOF'),
                |void
                |foo()
                |    ALIAS: a1 =   1
                |           a2 => a1
                |           a3 =   1
                |           a4 =   1
EOF
            [ERR, qr{\QWarning: aliases 'a3' and 'a1', 'a2'\E
                     \Q have identical values of 1 in (input), line 9\E\n
                     \Q  (If this is deliberate use a symbolic alias instead.)\E
                     }x,
                   "got a3 warning" ],
            [ERR, qr{\QWarning: aliases 'a4' and 'a1', 'a2', 'a3'\E
                     \Q have identical values of 1 in (input), line 10\E\n\z
                     }x,
                   "got a4 warning, no hint" ],
        ],

        [
            "ALIAS warn identical 0 values",
            Q(<<'EOF'),
                |void
                |foo()
                |    ALIAS: b1  = 0
                |           foo = 0
                |           b2  = 0
EOF
            [ERR, qr{\QWarning: aliases 'b1' and 'foo'\E
                     \Q have identical values of 0\E
                     \Q - the base function in (input), line 7\E\n
                     \Q  (If this is deliberate use a symbolic alias instead.)\E
                     }x,
                   "got b1 warning" ],
            [ERR, qr{\QWarning: aliases 'foo' and 'b1', 'foo'\E
                     \Q have identical values of 0\E
                     \Q - the base function in (input), line 8\E\n
                     }x,
                   "got foo warning" ],
            [ERR, qr{\QWarning: aliases 'b2' and 'b1', 'foo'\E
                     \Q have identical values of 0\E
                     \Q - the base function in (input), line 9\E\n\z
                     }x,
                   "got b2 warning, no hint" ],
        ],

        [
            "ALIAS warn varying values",
            Q(<<'EOF'),
                |void
                |foo()
                |    ALIAS: c1 = 1
                |           c1 = 2
EOF
            [ERR, qr{\QWarning: conflicting duplicate alias 'c1' changes\E
                     \Q definition from '1' to '2' in\E
                     \Q (input), line 8\E\n\z
                     }x,
                   "got c1 warning" ],
        ],

        [
            "ALIAS unparseable entry",
            Q(<<'EOF'),
                |void
                |foo()
                |    ALIAS: bar = 
EOF
            [ERR, qr{\QError: cannot parse ALIAS definitions from 'bar ='\E.*line 7},
                   "got expected error" ],
        ],
        [
            "ALIAS zero", # zero used to be silently ignored
            Q(<<'EOF'),
                |void
                |foo()
                |    ALIAS: 0
EOF
            [ERR, qr{\QError: cannot parse ALIAS definitions from '0'\E.*line 7},
                   "got expected error" ],
        ],
        [
            "ALIAS empty",
            Q(<<'EOF'),
                |void
                |foo()
                |    ALIAS:
EOF
            # just concerend with not getting an error
        ],
    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}


{
    # Test ALIAS keyword - with AUTHOR_WARNINGS disabled

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (

        [
            "ALIAS no warn identical values under no author tests",
            Q(<<'EOF'),
                |void
                |foo()
                |    ALIAS: bar = 1
                |           baz = 1
EOF
            [  0, qr{"Foo::foo",.*\n.*= 0;},
                   "has Foo::foo" ],
            [  0, qr{"Foo::bar",.*\n.*= 1;},
                   "has Foo::bar" ],
            [  0, qr{"Foo::baz",.*\n.*= 1;},
                   "has Foo::baz" ],
            # and no warnings expected
        ],
    );

    test_many($preamble, 'boot_Foo', \@test_fns, [ author_warnings => 0 ]);
}


{
    # Test ALIAS keyword  - XSUB body

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            'ALIAS with $ALIAS used in typemap entry',
            Q(<<'EOF'),
                |void
                |foo(AV *av)
                |    ALIAS: bar = 1
EOF
            [  0, qr{croak.*\n.*\QGvNAME(CvGV(cv))},
                   "got alias variant of croak message" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test ATTRS keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "ATTRS basic",
            Q(<<'EOF'),
                |void
                |foo()
                |    ATTRS: a
                |           b     c(x)
                |    C_ARGS: foo
                |    ATTRS: d(y(  z))  
EOF
            [  0, qr{\QCV * cv;}, "has cv declaration" ],
            [  0, qr{\Qapply_attrs_string("Foo", cv, "a\E\s+b\s+c\(x\)\s+\Qd(y(  z))", 0);},
                   "has correct attrs arg" ],
        ],

    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}


{
    # Test CASE: blocks

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (

        [
            "CASE with dup INPUT and OUTPUT",
            Q(<<'EOF'),
                |int
                |foo(abc, def)
                |    CASE: X
                |            int   abc;
                |            short def;
                |        CODE:
                |            RETVAL = abc + def;
                |        OUTPUT:
                |            RETVAL
                |
                |    CASE: Y
                |            long abc;
                |            long def;
                |        CODE:
                |            RETVAL = abc - def;
                |        OUTPUT:
                |            RETVAL
EOF
            [  0, qr/_usage\(cv,\s*"abc, def"\)/,     "usage" ],

            [  0, qr/
                       if \s* \(X\)
                       .*
                       int \s+ abc \s* = [^\n]* ST\(0\)
                       .*
                       else \s+ if \s* \(Y\)
                      /xs,                       "1st abc is int and ST(0)" ],
            [  0, qr/
                       else \s+ if \s* \(Y\)
                       .*
                       long \s+ abc \s* = [^\n]* ST\(0\)
                      /xs,                       "2nd abc is long and ST(0)" ],
            [  0, qr/
                       if \s* \(X\)
                       .*
                       short \s+ def \s* = [^\n]* ST\(1\)
                       .*
                       else \s+ if \s* \(Y\)
                      /xs,                       "1st def is short and ST(1)" ],
            [  0, qr/
                       else \s+ if \s* \(Y\)
                       .*
                       long \s+ def \s* = [^\n]* ST\(1\)
                      /xs,                       "2nd def is long and ST(1)" ],
            [  0, qr/
                       if \s* \(X\)
                       .*
                       int \s+ RETVAL;
                       .*
                       else \s+ if \s* \(Y\)
                      /xs,                       "1st RETVAL is int" ],
            [  0, qr/
                       else \s+ if \s* \(Y\)
                       .*
                       int \s+ RETVAL;
                       .*
                      /xs,                       "2nd RETVAL is int" ],

            [  0, qr/
                       if \s* \(X\)
                       .*
                       \QRETVAL = abc + def;\E
                       .*
                       else \s+ if \s* \(Y\)
                      /xs,                       "1st RETVAL assign" ],
            [  0, qr/
                       else \s+ if \s* \(Y\)
                       .*
                       \QRETVAL = abc - def;\E
                       .*
                      /xs,                       "2nd RETVAL assign" ],

            [  0, qr/\b\QXSRETURN(1)/,           "ret 1" ],
            [NOT, qr/\bXSRETURN\b.*\bXSRETURN/s, "only a single XSRETURN" ],
        ],
        [
            "CASE with unconditional else",
            Q(<<'EOF'),
                |void
                |foo()
                |    CASE: CCC1
                |        CODE:
                |            YYY1
                |    CASE: CCC2
                |        CODE:
                |            YYY2
                |    CASE:
                |        CODE:
                |            YYY3
EOF
            [  0, qr/
                       ^ \s+ if \s+ \(CCC1\) \n
                       ^ \s+ \{   \n
                       .*
                       ^\s+ YYY1  \n
                       .*
                       ^ \s+ \}   \n
                       ^ \s+ else \s+ if \s+ \(CCC2\) \n
                       ^ \s+ \{   \n
                       .*
                       ^\s+ YYY2  \n
                       .*
                       ^ \s+ \}   \n
                       ^ \s+ else \n
                       ^ \s+ \{   \n
                       .*
                       ^\s+ YYY3  \n
                       .*
                       ^ \s+ \}   \n
                       ^ \s+ XSRETURN_EMPTY;\n

                      /xms,                       "all present in order" ],
        ],
        [
            "CASE with dup alien var",
            Q(<<'EOF'),
                |void
                |foo(abc)
                |    CASE: X
                |            int abc
                |            int def
                |    CASE: Y
                |            long abc
                |            long def
EOF
            [  0, qr/
                       if \s* \(X\)
                       .*
                       int \s+ def \s*;
                       .*
                       else \s+ if \s* \(Y\)
                       .*
                       long \s+ def \s*;
                      /xs,                       "two alien declarations" ],
        ],
        [
            "CASE with variant keywords",
            Q(<<'EOF'),
                |void
                |foo()
                |    CASE: X
                |       C_ARGS: x,y
                |    CASE: Y
                |       C_ARGS: y,x
EOF
            [  0, qr/\(x,y\).*\(y,x\)/s, "C_ARGS" ],
        ],
        [
            "CASE with variant THIS type",
            Q(<<'EOF'),
                |void
                |A::B::foo()
                |    CASE: X
                |       int THIS
                |    CASE: Y
                |       long THIS
                |    CASE:
                |       short THIS
EOF
            [  0, qr/int   \s+ THIS .*
                       long  \s+ THIS .*
                       short \s+ THIS/sx, "has three types" ],
        ],
        [
            "CASE with variant RETVAL type",
            Q(<<'EOF'),
                |int
                |foo()
                |    CASE: X
                |       long RETVAL
                |    CASE: Y
                |       double RETVAL
                |    CASE: Z
                |       char * RETVAL
EOF
            [  0, qr/long        \s+ RETVAL .*
                       double      \s+ RETVAL .*
                       char \s* \* \s+ RETVAL/sx, "has three decl types" ],
            [  0, qr/X .* TARGi .*
                       Y .* TARGi .*
                       Z .* TARGi .*/sx, "has one setting type" ],
        ],
        [
            "CASE with variant autocall RETVAL",
            Q(<<'EOF'),
                |int
                |foo(int a)
                |    CASE: X
                |
                |    CASE: Y
                |        CODE:
                |            YYY
EOF
            [  0, qr{\Qif (X)\E
                       .*
                       dXSTARG;
                       .*
                       \QTARGi((IV)RETVAL, 1);\E
                       .*
                       \Qelse if (Y)\E
                       }sx,                 "branch X returns RETVAL" ],

            [NOT, qr{\Qelse if (Y)\E
                       .*
                       \QPUSHi((IV)RETVAL);\E
                       }sx,                 "branch Y doesn't return RETVAL" ],
        ],
        [
            "CASE with variant deferred var inits",
            Q(<<'EOF'),
                |int
                |foo(abc)
                |    CASE: X
                |     AV *abc
                |
                |    CASE: Y
                |     HV *abc
EOF
            [  0, qr{\Qif (X)\E
                       .*
                       croak.*\Qnot an ARRAY reference\E
                       .*
                       \Qelse if (Y)\E
                       .*
                       croak.*\Qnot a HASH reference\E
                       }sx,                 "differing croaks" ],

        ],

        [
            "CASE: case follows unconditional CASE",
            Q(<<'EOF'),
                |int
                |foo()
                |    CASE: X
                |        CODE:
                |            AAA
                |    CASE:
                |        CODE:
                |            BBB
                |    CASE: Y
                |        CODE:
                |            CCC
EOF
            [ERR, qr/\QError: 'CASE:' after unconditional 'CASE:'/,
                    "expected err" ],
        ],
        [
            "CASE: not at top of function",
            Q(<<'EOF'),
                |int
                |foo()
                |    CODE:
                |        AAA
                |    CASE: X
                |        CODE:
EOF
            [ERR, qr/\QError: no 'CASE:' at top of function/,
                    "expected err" ],
        ],
        [
            "CASE: junk",
            Q(<<'EOF'),
                |int
                |foo(a)
                |CASE: X
                |    SCOPE: ENABLE
                |    INPUTx:
EOF
            [ERR, qr/\QError: junk at end of function: "    INPUTx:" in /,
                    "expected err" ],
        ],
        [
            "keyword after end of xbody",
            Q(<<'EOF'),
                |void
                |foo()
                |  CODE:
                |     abc
                |  C_ARGS:
EOF
            [ERR, qr{\QError: misplaced 'C_ARGS:' in\E.*line 8},
                                                    "got expected error"  ],
        ],

        [
            "CASE: setting ST(0)",
            Q(<<'EOF'),
                |void
                |foo(a)
                |CASE: X
                |    CODE:
                |      ST(0) = 1;
                |CASE: Y
                |    CODE:
                |      blah
EOF
            [ERR, qr/\QWarning: ST(0) isn't consistently set in every CASE's CODE block/,
                    "expected err" ],
        ],

        [
            "CASE: not at top",
            Q(<<'EOF'),
                |int abc(int x, int y)
                |  INIT:
                |    myinit
                |  CASE: x > 0
                |    CODE:
                |      code1;
                |  CASE:
                |    CODE:
                |      code2;
EOF
            [ERR, qr/\A\QError: no 'CASE:' at top of function in (input), line 8\E\n\z/,
                    "only the expected err" ],
        ],


    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test CLEANUP keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "CLEANUP basic",
            Q(<<'EOF'),
                |int
                |foo(int aaa)
                |  CLEANUP:
                |     YYY
EOF
            [  0, qr{\bint\s+aaa},                  "has aaa decl"      ],
            [  0, qr{^\s+\QRETVAL = foo(aaa);}m,    "has code body"     ],
            [  0, qr{^\s+YYY\n}m,                   "has cleanup body" ],
            [  0, qr{aaa.*foo\(aaa\).*TARGi.*YYY}s, "in sequence"       ],
            [  0, qr{\#line 8 .*\n\s+YYY},          "correct #line"     ],
        ],
        [
             "CLEANUP empty",
             Q(<<'EOF'),
                 |void
                 |foo(int aaa)
                 |  CLEANUP:
EOF
            [  0, qr{\bint\s+aaa},                  "has aaa decl"      ],
            [  0, qr{^\s+\Qfoo(aaa);}m,             "has code body"     ],
            [  0, qr{\Qfoo(aaa);\E\n\#line 8 },     "correct #line"     ],
         ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test CODE keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "CODE basic",
            Q(<<'EOF'),
                |void
                |foo(int aaa)
                |  CODE:
                |     YYY
EOF
            [  0, qr{\bint\s+aaa},           "has aaa decl"   ],
            [  0, qr{YYY},                   "has code body"  ],
            [  0, qr{aaa.*YYY}s,             "in sequence"    ],
            [  0, qr{\#line 8 .*\n\s+YYY},   "correct #line"  ],
        ],
        [
            "CODE empty",
            Q(<<'EOF'),
                |void
                |foo(int aaa)
                |  CODE:
EOF
            [  0, qr{\bint\s+aaa},               "has aaa decl"   ],
            [  0, qr{aaa.*\n\s*;\s*\n\#line 8 }, "correct #line"  ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test INIT: keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "INIT basic",
            Q(<<'EOF'),
                |void
                |foo(aaa, short bbb)
                |    int aaa
                |  INIT:
                |     XXX
                |     YYY
                |  CODE:
                |     ZZZ
EOF
            [  0, qr{\bint\s+aaa},             "has aaa decl"   ],
            [  0, qr{\bshort\s+bbb},           "has bbb decl"   ],
            [  0, qr{^\s+XXX\n\s+YYY\n}m,      "has XXX, YYY"   ],
            [  0, qr{^\s+ZZZ\n}m,              "has ZZZ"        ],
            [  0, qr{aaa.*bbb.*XXX.*YYY.*ZZZ}s,"in sequence"    ],
        ],

    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test INTERFACE keyword - boot code

    my $preamble = Q(<<'EOF');
        |MODULE = Foo::Bar PACKAGE = Foo::Bar PREFIX = foobar_
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "INTERFACE basic boot",
            Q(<<'EOF'),
                |void
                |foo()
                |    INTERFACE: f1 f2
EOF
            [  0, qr{   \QnewXS_deffile("Foo::Bar::f1", XS_Foo__Bar_foo);\E\n
                       \s+\QXSINTERFACE_FUNC_SET(cv,f1);\E
                      }x,
                   "got f1 entries" ],
            [  0, qr{   \QnewXS_deffile("Foo::Bar::f2", XS_Foo__Bar_foo);\E\n
                       \s+\QXSINTERFACE_FUNC_SET(cv,f2);\E
                      }x,
                   "got f2 entries" ],
            [  0, qr{\QCV * cv;}, "has cv declaration" ],
        ],
        [
            "INTERFACE with MACRO",
            Q(<<'EOF'),
                |void
                |foo()
                |    INTERFACE: f1 f2
                |    INTERFACE_MACRO: GETMACRO SETMACRO
EOF
            [  0, qr{   \QnewXS_deffile("Foo::Bar::f1", XS_Foo__Bar_foo);\E\n
                       \s+\QSETMACRO(cv,f1);\E
                      }x,
                   "got f1 entries" ],
            [  0, qr{   \QnewXS_deffile("Foo::Bar::f2", XS_Foo__Bar_foo);\E\n
                       \s+\QSETMACRO(cv,f2);\E
                      }x,
                   "got f2 entries" ],
            [  0, qr{\QCV * cv;}, "has cv declaration" ],
        ],

        # Assorted name mangling - test the table in perlxs:
        #
        #   Interface name     Perl function name   C function name
        #    --------------     ------------------   ----------------
        #    abc                Foo::Bar::abc        abc
        #    foobar_abc         Foo::Bar::abc        foobar_abc
        #    X::Y::foobar_def   X::Y::foobar_def     X::Y::foobar_def

        [
            'INTERFACE simple name',
            Q(<<'EOF'),
                |void
                |foo()
                |    INTERFACE: abc
EOF
            [  0, qr{newXS.*"Foo::Bar::abc"},         "perl name" ],
            [  0, qr{newXS.*XS_Foo__Bar_foo},         "XS name"   ],
            [  0, qr{\QXSINTERFACE_FUNC_SET(cv,abc)}, "C name"    ],
        ],
        [
            'INTERFACE name with prefix',
            Q(<<'EOF'),
                |void
                |foo()
                |    INTERFACE: foobar_abc
EOF
            [  0, qr{newXS.*"Foo::Bar::abc"},                "perl name" ],
            [  0, qr{newXS.*XS_Foo__Bar_foo},                "XS name"   ],
            [  0, qr{\QXSINTERFACE_FUNC_SET(cv,foobar_abc)}, "C name"    ],
        ],
        [
            'INTERFACE name with class',
            Q(<<'EOF'),
                |void
                |foo()
                |    INTERFACE: X::Y::foobar_abc
EOF
            [  0, qr{newXS.*"X::Y::foobar_abc"}, "perl name" ],
            [  0, qr{newXS.*XS_Foo__Bar_foo},    "XS name"   ],
            [  0, qr{\QXSINTERFACE_FUNC_SET(cv,X::Y::foobar_abc)}, "C name"],
        ],
    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}

{
    # Test INTERFACE keyword  - XSUB body

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
        |TYPEMAP: <<EOTM
        |X::Y T_IV
        |EOTM
        |
EOF

    my @test_fns = (
        [
            'INTERFACE basic body',
            Q(<<'EOF'),
                |void
                |foo()
                |    INTERFACE: f1 f2
EOF
            [  0, qr{\b\QdXSFUNCTION(void)},
                   "got XSFUNCTION declaration" ],
            [  0, qr{\QXSFUNCTION = XSINTERFACE_FUNC(void,cv,XSANY.any_dptr);},
                   "got XSFUNCTION assign" ],
            [  0, qr{\Q((void (*)())(XSFUNCTION))();},
                   "got XSFUNCTION call" ],
        ],
        [
            'INTERFACE with MACRO',
            Q(<<'EOF'),
                |void
                |foo()
                |    INTERFACE: f1 f2
                |    INTERFACE_MACRO: GETMACRO SETMACRO
EOF
            [  0, qr{\b\QdXSFUNCTION(void)},
                   "got XSFUNCTION declaration" ],
            [  0, qr{\QXSFUNCTION = GETMACRO(void,cv,XSANY.any_dptr);},
                   "got XSFUNCTION assign" ],
            [  0, qr{\Q((void (*)())(XSFUNCTION))();},
                   "got XSFUNCTION call" ],
        ],
        [
            'INTERFACE with perl package name',
            Q(<<'EOF'),
                |X::Y
                |foo(X::Y a, char *b)
                |    INTERFACE: f1
EOF
            [  0, qr{\b\QdXSFUNCTION(X__Y)},
                   "got XSFUNCTION declaration" ],
            [  0, qr{\QXSFUNCTION = XSINTERFACE_FUNC(X__Y,cv,XSANY.any_dptr);},
                   "got XSFUNCTION assign" ],
            [  0, qr{\QRETVAL = ((X__Y (*)(X__Y, char *))(XSFUNCTION))(a, b);},
                   "got XSFUNCTION call" ],
        ],
        [
            'INTERFACE with C_ARGS',
            Q(<<'EOF'),
                |char *
                |foo(X::Y a, int b, char *c)
                |    INTERFACE: f1
                |    C_ARGS:  a,  c
EOF
            [  0, qr{\b\QdXSFUNCTION(char *)},
                   "got XSFUNCTION declaration" ],
            [  0, qr{\QXSFUNCTION = XSINTERFACE_FUNC(char *,cv,XSANY.any_dptr);},
                   "got XSFUNCTION assign" ],
            [  0, qr{\QRETVAL = ((char * (*)(X__Y, char *))(XSFUNCTION))(a,  c);},
                   "got XSFUNCTION call" ],
        ],

        # errors
        [
            'INTERFACE and ALIAS dont mix',
            Q(<<'EOF'),
                |int
                |foo()
                |    INTERFACE: f1
                |    ALIAS: a1 = 1
EOF
            [ERR,
            qr{\QError: only one of ALIAS and INTERFACE can be used per XSUB},
                   "got expected err" ],
        ],
        [
            'INTERFACE dup',
            Q(<<'EOF'),
                |int
                |foo()
                |    INTERFACE: f1 f1
EOF
            [ERR,
            qr{\QError: duplicate INTERFACE name: 'f1'},
                   "got expected err" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test NOT_IMPLEMENTED_YET pseudo-keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
        |TYPEMAP: <<EOF
        |INPUT
        |T_UV
        |    set_uint($var, $arg)
        |EOF
EOF

    my @test_fns = (
        [
            "NOT_IMPLEMENTED_YET basic",
            Q(<<'EOF'),
                |void
                |foo(int aaa, bbb, ccc)
                |    short bbb
                |    unsigned ccc
                |  NOT_IMPLEMENTED_YET
EOF
            [  0, qr{\QPerl_croak(aTHX_ "Foo::foo: not implemented yet");},
                    "has croak"   ],
            [  0, qr{\bint\s+aaa},             "has aaa decl"   ],
            [  0, qr{\bshort\s+bbb},           "has bbb decl"   ],
            [  0, qr{\bunsigned\s+ccc},        "has ccc decl"   ],
            [  0, qr{\Qset_uint(ccc, ST(2))},  "has ccc init"   ],
        ],
        [
            "NOT_IMPLEMENTED_YET no input part",
            Q(<<'EOF'),
                |void
                |foo()
                |  NOT_IMPLEMENTED_YET
EOF
            [  0, qr{\QPerl_croak(aTHX_ "Foo::foo: not implemented yet");},
                    "has croak"   ],
            [NOT, qr{NOT_IMPLEMENTED_YET},     "no NIY"         ],
        ],
        [
            "NOT_IMPLEMENTED_YET not special after C_ARGS",
            Q(<<'EOF'),
                |void
                |foo(aaa)
                |    int aaa
                |  C_ARGS: a,b,
                |  NOT_IMPLEMENTED_YET
EOF
            [NOT, qr{\QPerl_croak(aTHX_ "Foo::foo: not implemented yet");},
                    "doesn't has croak"   ],
            [  0, qr{\bint\s+aaa},                  "has aaa decl"         ],
            [  0, qr{a,b,\n\s+NOT_IMPLEMENTED_YET}, "NIY is part of C_ARGS"],
        ],
        [
            "NOT_IMPLEMENTED_YET not special after INIT",
            Q(<<'EOF'),
                |void
                |foo(aaa)
                |    int aaa
                |  INIT:
                |    ZZZ
                |  NOT_IMPLEMENTED_YET
EOF
            [NOT, qr{\QPerl_croak(aTHX_ "Foo::foo: not implemented yet");},
                    "doesn't has croak"   ],
            [  0, qr{\bint\s+aaa},                 "has aaa decl"     ],
            [  0, qr{ZZZ\n\s+NOT_IMPLEMENTED_YET}, "NIY is part of init code"          ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test OVERLOAD keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    # all known legal overloadable ops
    my @all_ops = qw(
        + - * / % ** << >> x .
        += -= *= /= %= **= <<= >>= x= .=
        < <= >  >= == !=
        <=> cmp
        lt le gt ge eq ne
        & &= | |= ^ ^= &. &.= |. |.= ^. ^.=
        neg ! ~ ~.
        ++ --
        atan2 cos sin exp abs log sqrt int
        bool "" 0+ qr
        <>
        -X
        ${} @{} %{} &{} *{}
        ~~
        nomethod =
    );

    my @test_fns = (
        [
            "OVERLOAD basic",
            Q(<<'EOF'),
                |void
                |foo()
                |    OVERLOAD:   cmp   <=>
                |                  + - *    /
                |    OVERLOAD:   >   <  >=
EOF
            [  0, qr{\Q"Foo::(*"},   "has Foo::(* method"   ],
            [  0, qr{\Q"Foo::(+"},   "has Foo::(+ method"   ],
            [  0, qr{\Q"Foo::(-"},   "has Foo::(- method"   ],
            [  0, qr{\Q"Foo::(/"},   "has Foo::(/ method"   ],
            [  0, qr{\Q"Foo::(<"},   "has Foo::(< method"   ],
            [  0, qr{\Q"Foo::(<=>"}, "has Foo::(<=> method" ],
            [  0, qr{\Q"Foo::(>"},   "has Foo::(> method"   ],
            [  0, qr{\Q"Foo::(>="},  "has Foo::(>= method"  ],
            [  0, qr{\Q"Foo::(cmp"}, "has Foo::(cmp method" ],
        ],

        [
            "OVERLOAD check all ops",
            Q(<<EOF),
                |void
                |foo()
                |    OVERLOAD: @all_ops
EOF
            map {
                  [  0, qr{\Q"Foo::($_"}, "$_: has Foo::($_ method"   ]
                } @all_ops
        ],

        [
            "OVERLOAD dup op",
            Q(<<'EOF'),
                |void
                |foo()
                |    OVERLOAD:   cmp cmp
EOF
            [ERR, qr{\QWarning: duplicate OVERLOAD op name: 'cmp'},
                "got expected error"   ],
        ],
        [
            "OVERLOAD unrecognised op",
            Q(<<'EOF'),
                |void
                |foo()
                |    OVERLOAD: []
EOF
            [ERR, qr{\QWarning: unrecognised OVERLOAD op name '[]' ignored},
                "got expected error"   ],
        ],

    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}


{
    # Test POSTCALL keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "POSTCALL basic",
            Q(<<'EOF'),
                |int
                |foo(int aaa)
                |  POSTCALL:
                |     YYY
EOF
            [  0, qr{\bint\s+aaa},                  "has aaa decl"      ],
            [  0, qr{^\s+\QRETVAL = foo(aaa);}m,    "has code body"     ],
            [  0, qr{^\s+YYY\n}m,                   "has postcall body" ],
            [  0, qr{aaa.*foo\(aaa\).*YYY.*TARGi}s, "in sequence"       ],
            [  0, qr{\#line 8 .*\n\s+YYY},          "correct #line"     ],
        ],
        [
             "POSTCALL empty",
             Q(<<'EOF'),
                 |void
                 |foo(int aaa)
                 |  POSTCALL:
EOF
            [  0, qr{\bint\s+aaa},                  "has aaa decl"      ],
            [  0, qr{^\s+\Qfoo(aaa);}m,             "has code body"     ],
            [  0, qr{\Qfoo(aaa);\E\n\#line 8 },     "correct #line"     ],
         ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test PPCODE keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "PPCODE basic",
            Q(<<'EOF'),
                |void
                |foo(int aaa)
                |  PPCODE:
                |     YYY
EOF
            [  0, qr{\bint\s+aaa},           "has aaa decl"   ],
            [  0, qr{YYY},                   "has code body"  ],
            [  0, qr{aaa.*YYY}s,             "in sequence"    ],
            [  0, qr{\#line 8 .*\n\s+YYY},   "correct #line"  ],
        ],
        [
            "PPCODE empty",
            Q(<<'EOF'),
                |void
                |foo(int aaa)
                |  PPCODE:
EOF
            [  0, qr{\bint\s+aaa},               "has aaa decl"   ],
            [  0, qr{aaa.*\n\s*;\s*\n\#line 8 }, "correct #line"  ],
        ],
        [
            "PPCODE trailing keyword",
            Q(<<'EOF'),
                |void
                |foo(int aaa)
                |  PPCODE:
                |     YYY
                |  OUTPUT:
                |     blah
EOF
            [ERR, qr{Error: PPCODE must be the last thing}, "got expected err"  ],
        ],
        [
            "PPCODE code tweaks",
            Q(<<'EOF'),
                |void
                |foo(int aaa)
                |  PPCODE:
                |     YYY
EOF
            [  0, qr{\QPERL_UNUSED_VAR(ax);},   "got PERL_UNUSED_VAR"    ],
            [  0, qr{\QSP -= items;},           "got SP -= items"        ],
            [NOT, qr{\QXSRETURN},               "no XSRETURN"            ],
            [  0, qr{\bPUTBACK\b.*\breturn\b}s, "got PUTBACK and return" ],
        ],

    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test PREINIT: keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "PREINIT basic",
            Q(<<'EOF'),
                |void
                |foo(aaa, bbb)
                |    int aaa
                |  PREINIT:
                |     XXX
                |     YYY
                |  INPUT:
                |     short bbb
                |  CODE:
                |     ZZZ
EOF
            [  0, qr{\bint\s+aaa},             "has aaa decl"   ],
            [  0, qr{^\s+XXX\n\s+YYY\n}m,      "has XXX, YYY"   ],
            [  0, qr{\bshort\s+bbb},           "has bbb decl"   ],
            [  0, qr{^\s+ZZZ\n}m,              "has ZZZ"        ],
            [  0, qr{int\s+aaa.*XXX.*YYY.*bbb.*ZZZ}s,"in sequence"    ],
        ],

    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test XSUB-scoped SCOPE keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
        |TYPEMAP: <<EOF
        |MyScopeInt        T_MYINT
        |
        |INPUT
        |T_MYINT
        |   $var = my_int($arg); /* SCOPE */
        |EOF
EOF

    my @test_fns = (
        [
            "file SCOPE: trailing text",
            Q(<<'EOF'),
                |SCOPE: EnAble blah # bloo +%
                |void
                |foo()
EOF
            [ERR, qr{\QError: SCOPE: invalid value 'EnAble blah # bloo +%' (should be ENABLE/DISABLE)}, "should die" ],
        ],
        [
            "xsub SCOPE: trailing text",
            Q(<<'EOF'),
                |void
                |foo()
                |SCOPE: EnAble blah # bloo +%
EOF
            [ERR, qr{\QError: SCOPE: invalid value 'EnAble blah # bloo +%' (should be ENABLE/DISABLE)}, "should die" ],
        ],
        [
            "xsub SCOPE: lower case",
            Q(<<'EOF'),
                |void
                |foo()
                |SCOPE: enable
EOF
            [ERR, qr{\QError: SCOPE: invalid value 'enable' (should be ENABLE/DISABLE)}, "should die" ],
        ],
        [
            "xsub SCOPE: semicolon",
            Q(<<'EOF'),
                |void
                |foo()
                |SCOPE: ENABLE;
EOF
            [ERR, qr{\QError: SCOPE: invalid value 'ENABLE;' (should be ENABLE/DISABLE)}, "should die" ],
        ],

        [
            "SCOPE: as file-scoped keyword",
            Q(<<'EOF'),
                |SCOPE: ENABLE
                |void
                |foo()
                |C_ARGS: a,b,c
EOF
            [  0, qr{ENTER;\s+{\s+\Qfoo(a,b,c);\E\s+}\s+LEAVE;},
                    "has ENTER/LEAVE" ],
        ],
        [
            "SCOPE: as xsub-scoped keyword",
            Q(<<'EOF'),
                |void
                |foo()
                |C_ARGS: a,b,c
                |SCOPE: ENABLE
EOF
            [  0, qr{ENTER;\s+{\s+\Qfoo(a,b,c);\E\s+}\s+LEAVE;},
                    "has ENTER/LEAVE" ],
        ],
        [
            "/* SCOPE */ in typemap",
            Q(<<'EOF'),
                |void
                |foo(i)
                | MyScopeInt i
EOF
            [  0, qr{ENTER;\s+{.+\s+}\s+LEAVE;}s, "has ENTER/LEAVE" ],
        ],
        [
            "xsub duplicate SCOPE",
            Q(<<'EOF'),
                |void
                |foo()
                |SCOPE: ENABLE
                |SCOPE: ENABLE
EOF
            [ERR, qr{\QError: only one SCOPE declaration allowed per XSUB},
                    "got expected error"],
        ],
        [
            "unrecognised file-scoped keyword",
            Q(<<'EOF'),
                |FOO_BAR:
EOF
            [ERR,
                qr{\QError: unrecognised keyword 'FOO_BAR' in (input), line 12\E\n},
                    "got expected error"],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test warnings for junk after a codeblock-ish keyword
    # and confirm that such junk is indeed ignored.
    # (BOOT is tested elsewhere as it's not an XSUB keyword)

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns;

    for my $kw (qw(
                    CLEANUP
                    CODE
                    INIT
                    POSTCALL
                    PPCODE
                    PREINIT
                ))
    {
        push @test_fns,
            [
                "Warn if junk after $kw'",
                Q(<<"EOF"),
                    |int foo()
                    |$kw: blah
                    |  codeline
EOF
                [  0, qr{\Q#line 7 "(input)"\E\n  codeline\n#line},
                "junk ignored" ],
                [ERR, qr{Warning: text after keyword ignored: 'blah'}, "" ],
            ];
    }

    test_many($preamble, 'XS_Foo_', \@test_fns);

    @test_fns = (
        [
            "Warn if junk after BOOT'",
            Q(<<"EOF"),
                |BOOT: blah
                |  codeline
EOF
            [ERR, qr{Warning: text after keyword ignored: 'blah'}, "" ],
        ],
    );

    test_many($preamble, undef, \@test_fns);
}


done_testing;

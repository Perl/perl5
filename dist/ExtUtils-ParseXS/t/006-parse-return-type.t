#!/usr/bin/perl
#
# 006-parse-return-type.t
#
# Test the parsing of the return type of an XSUB. This mainly concerned
# with looking up the type in a typemap and generating the appropriate
# C code to declare and return RETVAL.
#
# There is a separate test file for XSUB parameters, and some return type
# tests are there instead when they are testing the same things that the
# corresponding parameter tests are doing.
#
# Note that there is a separate test file for INPUT and OUTPUT XSUB
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
    # Test return type declarations

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
EOF

    my @test_fns = (
        [
            "NO_OUTPUT",
            Q(<<'EOF'),
                |NO_OUTPUT int
                |foo()
EOF
            [  0, qr/\QRETVAL = foo();/, "has autocall"     ],
            [NOT, qr/\bTARG/,            "no setting TARG"  ],
            [NOT, qr/\QST(0)/,           "no setting ST(0)" ],
        ],
        [
            "xsub decl on one line",
            Q(<<'EOF'),
                | int foo(A, int  B )
                |    char *A
EOF
            [  0, qr/^\s+char \*\s+A\s+=/m,  "has A decl"    ],
            [  0, qr/^\s+int\s+B\s+=/m,      "has B decl"    ],
            [  0, qr/\QRETVAL = foo(A, B);/, "has autocall"  ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test RETVAL with the dXSTARG optimisation. When the return type
    # corresponds to a simple sv_setXv($arg, $val) in the typemap,
    # use the OP_ENTERSUB's TARG if possible, rather than creating a new
    # mortal each time.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
        |TYPEMAP: <<EOF
        |const int     T_IV
        |const long    T_MYIV
        |const short   T_MYSHORT
        |undef_t       T_MYUNDEF
        |ivmg_t        T_MYIVMG
        |
        |INPUT
        |T_MYIV
        |    $var = ($type)SvIV($arg)
        |
        |OUTPUT
        |T_OBJECT
        |    sv_setiv($arg, (IV)$var);
        |
        |T_MYSHORT
        |    ${ "$var" eq "RETVAL" ? \"$arg = $var;" : \"sv_setiv($arg, $var);" }
        |
        |T_MYUNDEF
        |    sv_set_undef($arg);
        |
        |T_MYIVMG
        |    sv_setiv_mg($arg, (IV)RETVAL);
        |EOF
EOF

    my @test_fns = (
        [
            "dXSTARG int (IV)",
            Q(<<'EOF'),
                |int
                |foo()
EOF
            [  0, qr/\bdXSTARG;/,   "has targ def" ],
            [  0, qr/\bTARGi\b/,    "has TARGi" ],
            [NOT, qr/sv_newmortal/, "doesn't have newmortal" ],
        ],

        [
            # same as int, but via custom typemap entry
            "dXSTARG const int (IV)",
            Q(<<'EOF'),
                |const int
                |foo()
EOF
            [  0, qr/\bdXSTARG;/,   "has targ def" ],
            [  0, qr/\bTARGi\b/,    "has TARGi" ],
            [NOT, qr/sv_newmortal/, "doesn't have newmortal" ],
        ],

        [
            # same as int, but via custom typemap OUTPUT entry
            "dXSTARG const long (MYIV)",
            Q(<<'EOF'),
                |const int
                |foo()
EOF
            [  0, qr/\bdXSTARG;/,   "has targ def" ],
            [  0, qr/\bTARGi\b/,    "has TARGi" ],
            [NOT, qr/sv_newmortal/, "doesn't have newmortal" ],
        ],

        [
            "dXSTARG unsigned long (UV)",
            Q(<<'EOF'),
                |unsigned long
                |foo()
EOF
            [  0, qr/\bdXSTARG;/,   "has targ def" ],
            [  0, qr/\bTARGu\b/,    "has TARGu" ],
            [NOT, qr/sv_newmortal/, "doesn't have newmortal" ],
        ],

        [
            "dXSTARG time_t (NV)",
            Q(<<'EOF'),
                |time_t
                |foo()
EOF
            [  0, qr/\bdXSTARG;/,   "has targ def" ],
            [  0, qr/\bTARGn\b/,    "has TARGn" ],
            [NOT, qr/sv_newmortal/, "doesn't have newmortal" ],
        ],

        [
            "dXSTARG char (pvn)",
            Q(<<'EOF'),
                |char
                |foo()
EOF
            [  0, qr/\bdXSTARG;/,   "has targ def" ],
            [  0, qr/\bsv_setpvn\b/,"has sv_setpvn()" ],
            [NOT, qr/sv_newmortal/, "doesn't have newmortal" ],
        ],

        [
            "dXSTARG char * (PV)",
            Q(<<'EOF'),
                |char *
                |foo()
EOF
            [  0, qr/\bdXSTARG;/,   "has targ def" ],
            [  0, qr/\bsv_setpv\b/, "has sv_setpv" ],
            [  0, qr/\QST(0) = TARG;/, "has ST(0) = TARG" ],
            [NOT, qr/sv_newmortal/, "doesn't have newmortal" ],
        ],

        [
            "dXSTARG int (IV) with outlist",
            Q(<<'EOF'),
                |int
                |foo(OUTLIST int a, OUTLIST int b)
EOF
            [  0, qr/\bdXSTARG;/,      "has targ def" ],
            [  0, qr/\bXSprePUSH;/,    "has XSprePUSH" ],
            [NOT, qr/\bXSprePUSH\b.+\bXSprePUSH\b/s,
                                         "has only one XSprePUSH" ],

            [  0, qr/\bTARGi\b/,       "has TARGi" ],
            [  0, qr/\bsv_setiv\(RETVALSV.*sv_setiv\(RETVALSV/s,
                                         "has two setiv(RETVALSV,...)" ],

            [  0, qr/\bXSRETURN\(3\)/, "has XSRETURN(3)" ],
        ],

        # Test RETVAL with an overridden typemap template in OUTPUT
        [
            "RETVAL overridden typemap: non-TARGable",
            Q(<<'EOF'),
                |int
                |foo()
                |    OUTPUT:
                |        RETVAL my_sv_setiv(ST(0), RETVAL);
EOF
            [  0, qr/\bmy_sv_setiv\b/,   "has my_sv_setiv" ],
        ],

        [
            "RETVAL overridden typemap: TARGable",
            Q(<<'EOF'),
                |int
                |foo()
                |    OUTPUT:
                |        RETVAL sv_setiv(ST(0), RETVAL);
EOF
            # XXX currently the TARG optimisation isn't done
            # XXX when this is fixed, update the test
            [  0, qr/\bsv_setiv\b/,   "has sv_setiv" ],
        ],

        [
            "dXSTARG with variant typemap",
            Q(<<'EOF'),
                |void
                |foo(OUTLIST const short a)
EOF
            [  0, qr/\bdXSTARG;/,      "has targ def" ],
            [  0, qr/\bTARGi\b/,       "has TARGi" ],
            [NOT, qr/\bsv_setiv\(/,    "has NO sv_setiv" ],
            [  0, qr/\bXSRETURN\(1\)/, "has XSRETURN(1)" ],
        ],

        [
            "dXSTARG with sv_set_undef",
            Q(<<'EOF'),
                |void
                |foo(OUTLIST undef_t a)
EOF
            [  0, qr/\bdXSTARG;/,          "has targ def" ],
            [  0, qr/\bsv_set_undef\(/,    "has sv_set_undef" ],
        ],

        [
            "dXSTARG with sv_setiv_mg",
            Q(<<'EOF'),
                |ivmg_t
                |foo()
EOF
            [  0, qr/\bdXSTARG;/,          "has targ def" ],
            [  0, qr/\bTARGi\(/,           "has TARGi" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test RETVAL as a parameter. This isn't well documented as to
    # how it should be interpreted, so these tests are more about checking
    # current behaviour so that inadvertent changes are detected, rather
    # than approving the current behaviour.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (

        # First, with void return type.
        # Generally in this case, RETVAL is currently not special - it's
        # just another name for a parameter. If it doesn't have a type
        # specified, it's treated as a placeholder.

        [
            # XXX this generates an autocall using undeclared RETVAL,
            # which should be an error
            "void RETVAL no-type param autocall",
            Q(<<'EOF'),
                |void
                |foo(RETVAL, short abc)
EOF
            [  0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            [  0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [  0, qr/\Qfoo(RETVAL, abc)/,              "autocall" ],
            [  0, qr/\bXSRETURN_EMPTY\b/,              "ret empty" ],
        ],

        [
            "void RETVAL no-type param",
            Q(<<'EOF'),
                |void
                |foo(RETVAL, short abc)
                |    CODE:
                |        xyz
EOF
            [  0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            [  0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [  0, qr/\bXSRETURN_EMPTY\b/,              "ret empty" ],
        ],

        [
            "void RETVAL typed param autocall",
            Q(<<'EOF'),
                |void
                |foo(int RETVAL, short abc)
EOF
            [  0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            [  0, qr/\bint\s+RETVAL\s*=.*\QST(0)/,     "declare and init" ],
            [  0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [  0, qr/\Qfoo(RETVAL, abc)/,              "autocall" ],
            [  0, qr/\bXSRETURN_EMPTY\b/,              "ret empty" ],
        ],

        [
            "void RETVAL INPUT typed param autocall",
            Q(<<'EOF'),
                |void
                |foo(RETVAL, short abc)
                |   int RETVAL
EOF
            [  0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            [  0, qr/\bint\s+RETVAL\s*=.*\QST(0)/,     "declare and init" ],
            [  0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [  0, qr/\Qfoo(RETVAL, abc)/,              "autocall" ],
            [  0, qr/\bXSRETURN_EMPTY\b/,              "ret empty" ],
        ],

        [
            "void RETVAL typed param",
            Q(<<'EOF'),
                |void
                |foo(int RETVAL, short abc)
                |    CODE:
                |        xyz
EOF
            [  0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            [  0, qr/\bint\s+RETVAL\s*=.*\QST(0)/,     "declare and init" ],
            [  0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [  0, qr/\bXSRETURN_EMPTY\b/,              "ret empty" ],
        ],

        [
            "void RETVAL INPUT typed param",
            Q(<<'EOF'),
                |void
                |foo(RETVAL, short abc)
                |   int RETVAL
                |    CODE:
                |        xyz
EOF
            [  0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            [  0, qr/\bint\s+RETVAL\s*=.*\QST(0)/,     "declare and init" ],
            [  0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [  0, qr/\bXSRETURN_EMPTY\b/,              "ret empty" ],
        ],

        [
            "void RETVAL alien autocall",
            Q(<<'EOF'),
                |void
                |foo(short abc)
                |   int RETVAL = 99
EOF
            [  0, qr/_usage\(cv,\s*"abc"\)/,           "usage" ],
            [  0, qr/\bint\s+RETVAL\s*=\s*99/,         "declare and init" ],
            [  0, qr/short\s+abc\s*=.*\QST(0)/,        "abc is ST0" ],
            [  0, qr/\Qfoo(abc)/,                      "autocall" ],
            [  0, qr/\bXSRETURN_EMPTY\b/,              "ret empty" ],
        ],

        [
            "void RETVAL alien",
            Q(<<'EOF'),
                |void
                |foo(short abc)
                |   int RETVAL = 99
EOF
            [  0, qr/_usage\(cv,\s*"abc"\)/,           "usage" ],
            [  0, qr/\bint\s+RETVAL\s*=\s*99/,         "declare and init" ],
            [  0, qr/short\s+abc\s*=.*\QST(0)/,        "abc is ST0" ],
            [  0, qr/\bXSRETURN_EMPTY\b/,              "ret empty" ],
        ],


        # Next, with 'long' return type.
        # Generally, RETVAL is treated as a normal parameter, with
        # some bad behaviour (such as multiple definitions) when that
        # clashes with the implicit use of RETVAL

        [
            "long RETVAL no-type param autocall",
            Q(<<'EOF'),
                |long
                |foo(RETVAL, short abc)
EOF
            [  0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            # XXX RETVAL is passed uninitialised to the autocall fn
            [  0, qr/long\s+RETVAL;/,                  "declare no init" ],
            [  0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [  0, qr/\Qfoo(RETVAL, abc)/,              "autocall" ],
            [  0, qr/\b\QXSRETURN(1)/,                 "ret 1" ],
        ],

        [
            "long RETVAL no-type param",
            Q(<<'EOF'),
                |long
                |foo(RETVAL, short abc)
                |    CODE:
                |        xyz
EOF
            [  0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            [  0, qr/long\s+RETVAL;/,                  "declare no init" ],
            [  0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [  0, qr/\b\QXSRETURN(1)/,                 "ret 1" ],
        ],

        [
            "long RETVAL typed param autocall",
            Q(<<'EOF'),
                |long
                |foo(int RETVAL, short abc)
EOF
            [  0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            # duplicate or malformed declarations used to be emitted
            [NOT, qr/int\s+RETVAL;/,                   "no none init init" ],
            [NOT, qr/long\s+RETVAL;/,                  "no none init long" ],

            [  0, qr/\bint\s+RETVAL\s*=.*\QST(0)/,     "int  decl and init" ],
            [  0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [  0, qr/\bRETVAL\s*=\s*foo\(RETVAL, abc\)/,"autocall" ],
            [  0, qr/\b\QTARGi((IV)RETVAL, 1)/,        "TARGi" ],
            [  0, qr/\b\QXSRETURN(1)/,                 "ret 1" ],
        ],

        [
            "long RETVAL INPUT typed param autocall",
            Q(<<'EOF'),
                |long
                |foo(RETVAL, short abc)
                |   int RETVAL
EOF
            [  0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            [NOT, qr/long\s+RETVAL/,                   "no long decl" ],
            [  0, qr/\bint\s+RETVAL\s*=.*\QST(0)/,     "int  decl and init" ],
            [  0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [  0, qr/\bRETVAL\s*=\s*foo\(RETVAL, abc\)/,"autocall" ],
            [  0, qr/\b\QTARGi((IV)RETVAL, 1)/,         "TARGi" ],
            [  0, qr/\b\QXSRETURN(1)/,                  "ret 1" ],
        ],

        [
            "long RETVAL INPUT typed param autocall 2nd pos",
            Q(<<'EOF'),
                |long
                |foo(short abc, RETVAL)
                |   int RETVAL
EOF
            [  0, qr/_usage\(cv,\s*"abc,\s*RETVAL"\)/, "usage" ],
            [NOT, qr/long\s+RETVAL/,                   "no long decl" ],
            [  0, qr/\bint\s+RETVAL\s*=.*\QST(1)/,     "int  decl and init" ],
            [  0, qr/short\s+abc\s*=.*\QST(0)/,        "abc is ST0" ],
            [  0, qr/\bRETVAL\s*=\s*foo\(abc, RETVAL\)/,"autocall" ],
            [  0, qr/\b\QTARGi((IV)RETVAL, 1)/,         "TARGi" ],
            [  0, qr/\b\QXSRETURN(1)/,                  "ret 1" ],
        ],

        [
            "long RETVAL typed param",
            Q(<<'EOF'),
                |long
                |foo(int RETVAL, short abc)
                |    CODE:
                |        xyz
                |    OUTPUT:
                |        RETVAL
EOF
            [  0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            # duplicate or malformed declarations used to be emitted
            [NOT, qr/int\s+RETVAL;/,                "no none init init" ],
            [NOT, qr/long\s+RETVAL;/,               "no none init long" ],

            [  0, qr/\bint\s+RETVAL\s*=.*\QST(0)/,  "int  decl and init" ],
            [  0, qr/short\s+abc\s*=.*\QST(1)/,     "abc is ST1" ],
            [  0, qr/\b\QTARGi((IV)RETVAL, 1)/,     "TARGi" ],
            [  0, qr/\b\QXSRETURN(1)/,              "ret 1" ],
        ],

        [
            "long RETVAL INPUT typed param",
            Q(<<'EOF'),
                |long
                |foo(RETVAL, short abc)
                |    int RETVAL
                |    CODE:
                |        xyz
                |    OUTPUT:
                |        RETVAL
EOF
            [  0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            [NOT, qr/long\s+RETVAL/,                "no long declare" ],
            [  0, qr/\bint\s+RETVAL\s*=.*\QST(0)/,  "int  declare and init" ],
            [  0, qr/short\s+abc\s*=.*\QST(1)/,     "abc is ST1" ],
            [  0, qr/\b\QTARGi((IV)RETVAL, 1)/,     "TARGi" ],
            [  0, qr/\b\QXSRETURN(1)/,              "ret 1" ],
        ],

        [
            "long RETVAL alien autocall",
            Q(<<'EOF'),
                |long
                |foo(short abc)
                |   int RETVAL = 99
EOF
            [  0, qr/_usage\(cv,\s*"abc"\)/,        "usage" ],
            [  0, qr/\bint\s+RETVAL\s*=\s*99/,      "declare and init" ],
            [  0, qr/short\s+abc\s*=.*\QST(0)/,     "abc is ST0" ],
            [  0, qr/\bRETVAL\s*=\s*foo\(abc\)/,    "autocall" ],
            [  0, qr/\b\QXSRETURN(1)/,              "ret 1" ],
        ],

        [
            "long RETVAL alien",
            Q(<<'EOF'),
                |long
                |foo(abc, def)
                |   int def
                |   int RETVAL = 99
                |   int abc
                |  CODE:
                |    xyz
EOF
            [  0, qr/_usage\(cv,\s*"abc,\s*def"\)/, "usage" ],
            [  0, qr/\bint\s+RETVAL\s*=\s*99/,      "declare and init" ],
            [  0, qr/int\s+abc\s*=.*\QST(0)/,       "abc is ST0" ],
            [  0, qr/int\s+def\s*=.*\QST(1)/,       "def is ST1" ],
            [  0, qr/int\s+def.*int\s+RETVAL.*int\s+abc/s,  "ordering" ],
            [  0, qr/\b\QXSRETURN(1)/,              "ret 1" ],
        ],


        # Test NO_OUTPUT

        [
            "NO_OUTPUT autocall",
            Q(<<'EOF'),
                |NO_OUTPUT long
                |foo(int abc)
EOF
            [  0, qr/_usage\(cv,\s*"abc"\)/,        "usage" ],
            [  0, qr/long\s+RETVAL;/,               "long declare  no init" ],
            [  0, qr/int\s+abc\s*=.*\QST(0)/,       "abc is ST0" ],
            [  0, qr/\bRETVAL\s*=\s*foo\(abc\)/,    "autocall" ],
            [  0, qr/\bXSRETURN_EMPTY\b/,           "ret empty" ],
        ],

        [
            # NO_OUTPUT with void should be a NOOP, but check
            "NO_OUTPUT void autocall",
            Q(<<'EOF'),
                |NO_OUTPUT void
                |foo(int abc)
EOF
            [  0, qr/_usage\(cv,\s*"abc"\)/,        "usage" ],
            [NOT, qr/\s+RETVAL;/,                   "don't declare RETVAL" ],
            [  0, qr/int\s+abc\s*=.*\QST(0)/,       "abc is ST0" ],
            [  0, qr/^\s*foo\(abc\)/m,              "void autocall" ],
            [  0, qr/\bXSRETURN_EMPTY\b/,           "ret empty" ],
        ],

        [
            "NO_OUTPUT with RETVAL autocall",
            Q(<<'EOF'),
                |NO_OUTPUT long
                |foo(int RETVAL)
EOF
            [  0, qr/_usage\(cv,\s*"RETVAL"\)/,     "usage" ],
            [  0, qr/\bint\s+RETVAL\s*=/,           "declare and init" ],
            [  0, qr/\bRETVAL\s*=\s*foo\(RETVAL\)/, "autocall" ],
            [  0, qr/\bXSRETURN_EMPTY\b/,           "ret empty" ],
        ],

        [
            "NO_OUTPUT with CODE",
            Q(<<'EOF'),
                |NO_OUTPUT long
                |foo(int abc)
                |   CODE:
                |      xyz
EOF
            [  0, qr/_usage\(cv,\s*"abc"\)/,        "usage" ],
            [  0, qr/long\s+RETVAL;/,               "long declare  no init" ],
            [  0, qr/int\s+abc\s*=.*\QST(0)/,       "abc is ST0" ],
            [  0, qr/\bXSRETURN_EMPTY\b/,           "ret empty" ],
        ],

        [
            # NO_OUTPUT with void should be a NOOP, but check
            "NO_OUTPUT void with CODE",
            Q(<<'EOF'),
                |NO_OUTPUT void
                |foo(int abc)
                |   CODE:
                |      xyz
EOF
            [  0, qr/_usage\(cv,\s*"abc"\)/,        "usage" ],
            [NOT, qr/\s+RETVAL;/,                   "don't declare RETVAL" ],
            [  0, qr/int\s+abc\s*=.*\QST(0)/,       "abc is ST0" ],
            [  0, qr/\bXSRETURN_EMPTY\b/,           "ret empty" ],
        ],

        [
            "NO_OUTPUT with RETVAL and CODE",
            Q(<<'EOF'),
                |NO_OUTPUT long
                |foo(int RETVAL)
                |   CODE:
                |      xyz
EOF
            [  0, qr/_usage\(cv,\s*"RETVAL"\)/,     "usage" ],
            [  0, qr/\bint\s+RETVAL\s*=/,           "declare and init" ],
            [  0, qr/\bXSRETURN_EMPTY\b/,           "ret empty" ],
        ],


        [
            "NO_OUTPUT with CODE and OUTPUT",
            Q(<<'EOF'),
                |NO_OUTPUT long
                |foo(int abc)
                |   CODE:
                |      xyz
                |   OUTPUT:
                |      RETVAL
EOF
            [ERR, qr/Error: can't use RETVAL in OUTPUT when NO_OUTPUT declared/,  "OUTPUT err" ],
        ],

        [
            "NO_OUTPUT with RETVAL param and OUTPUT",
            Q(<<'EOF'),
                |NO_OUTPUT long
                |foo(int RETVAL)
                |   OUTPUT:
                |      RETVAL
EOF
            [ERR, qr/Error: can't use RETVAL in OUTPUT when NO_OUTPUT declared/,  "OUTPUT err" ],
        ],

        [
            "NO_OUTPUT with RETVAL param, CODE and OUTPUT",
            Q(<<'EOF'),
                |NO_OUTPUT long
                |foo(int RETVAL)
                |   CODE:
                |      xyz
                |   OUTPUT:
                |      RETVAL
EOF
            [ERR, qr/Error: can't use RETVAL in OUTPUT when NO_OUTPUT declared/,  "OUTPUT err" ],
        ],


        # Test duplicate RETVAL parameters

        [
            "void dup",
            Q(<<'EOF'),
                |void
                |foo(RETVAL, RETVAL)
EOF
            [ERR, qr/Error: duplicate definition of parameter 'RETVAL'/,  "" ],
        ],

        [
            "void dup typed",
            Q(<<'EOF'),
                |void
                |foo(int RETVAL, short RETVAL)
EOF
            [ERR, qr/Error: duplicate definition of parameter 'RETVAL'/,  "" ],
        ],

        [
            "void dup INPUT",
            Q(<<'EOF'),
                |void
                |foo(RETVAL, RETVAL)
                |   int RETVAL
EOF
            [ERR, qr/Error: duplicate definition of parameter 'RETVAL'/,  "" ],
        ],

        [
            "long dup",
            Q(<<'EOF'),
                |long
                |foo(RETVAL, RETVAL)
EOF
            [ERR, qr/Error: duplicate definition of parameter 'RETVAL'/,  "" ],
        ],

        [
            "long dup typed",
            Q(<<'EOF'),
                |long
                |foo(int RETVAL, short RETVAL)
EOF
            [ERR, qr/Error: duplicate definition of parameter 'RETVAL'/,  "" ],
        ],

        [
            "long dup INPUT",
            Q(<<'EOF'),
                |long
                |foo(RETVAL, RETVAL)
                |   int RETVAL
EOF
            [ERR, qr/Error: duplicate definition of parameter 'RETVAL'/,  "" ],
        ],


    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}

{
    # Test RETVAL return mixed types.
    # Where the return type of the XSUB differs from the declared type
    # of the RETVAL var. For backwards compatibility, we should use the
    # XSUB type when returning.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
        |TYPEMAP: <<EOF
        |my_type    T_MY_TYPE
        |
        |OUTPUT
        |T_MY_TYPE
        |    sv_set_my_type($arg, (my_type)$var);
        |EOF
EOF

    my @test_fns = (

        [
            "RETVAL mixed type",
            Q(<<'EOF'),
                |my_type
                |foo(int RETVAL)
EOF
            [  0, qr/int\s+RETVAL\s*=.*SvIV\b/,  "RETVAL is int" ],
            [  0, qr/sv_set_my_type\(/,          "return is my_type" ],
        ],

        [
            "RETVAL mixed type INPUT",
            Q(<<'EOF'),
                |my_type
                |foo(RETVAL)
                |    int RETVAL
EOF
            [  0, qr/int\s+RETVAL\s*=.*SvIV\b/,  "RETVAL is int" ],
            [  0, qr/sv_set_my_type\(/,          "return is my_type" ],
        ],

        [
            "RETVAL mixed type alien",
            Q(<<'EOF'),
                |my_type
                |foo()
                |  int RETVAL = 99;
EOF
            [  0, qr/int\s+RETVAL\s*=\s*99/,     "RETVAL is int" ],
            [  0, qr/sv_set_my_type\(/,          "return is my_type" ],
        ],

    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test weird packing facility: return type array(type,nitems)

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (

        [
            "array(int,5)",
            Q(<<'EOF'),
                |array(int,5)
                |foo()
EOF
            [  0, qr/int\s*\*\s+RETVAL;/,      "RETVAL is int*" ],
            [  0, qr/sv_setpvn\(.*,\s*5\s*\*\s*\Qsizeof(int));/,
                                                 "return packs 5 ints" ],
            [  0, qr/\bdXSTARG\b/,             "declares TARG" ],
            [  0, qr/sv_setpvn\(TARG\b/,       "uses TARG" ],

        ],

        [
            "array(int*, expr)",
            Q(<<'EOF'),
                |array(int*, FOO_SIZE)
                |foo()
EOF
            [  0, qr/int\s*\*\s*\*\s+RETVAL;/, "RETVAL is int**" ],
            [  0, qr/sv_setpvn\(.*,\s*FOO_SIZE\s*\*\s*sizeof\(int\s*\*\s*\)\);/,
                                                "return packs FOO_SIZE int*s" ],
        ],

        [
            "array() as param type",
            Q(<<'EOF'),
                |int
                |foo(abc)
                |    array(int,5) abc
EOF
            [ERR, qr/Could not find a typemap for C type/, " no find type" ],
        ],

        [
            "array() can be overriden by OUTPUT",
            Q(<<'EOF'),
                |array(int,5)
                |foo()
                |    OUTPUT:
                |        RETVAL my_setintptr(ST(0), RETVAL);
EOF
            [  0, qr/int\s*\*\s+RETVAL;/,             "RETVAL is int*" ],
            [  0, qr/\Qmy_setintptr(ST(0), RETVAL);/, "override honoured" ],
        ],

        [
            "array() in output override isn't special",
            Q(<<'EOF'),
                |short
                |foo()
                |    OUTPUT:
                |        RETVAL array(int,5)
EOF
            [  0, qr/short\s+RETVAL;/,      "RETVAL is short" ],
            [  0, qr/\Qarray(int,5)/,       "return expression is unchanged" ],
        ],

        [
            "array() OUT",
            Q(<<'EOF'),
                |int
                |foo(OUT array(int,5) AAA)
EOF
            [ERR, qr/\QError: can't use array(type,nitems) type for OUT parameter/,
                        "got err" ],
        ],

        [
            "array() OUTLIST",
            Q(<<'EOF'),
                |int
                |foo(OUTLIST array(int,5) AAA)
EOF
            [ERR, qr/\QError: can't use array(type,nitems) type for OUTLIST parameter/,
                    "got err" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


done_testing;

#!/usr/bin/perl
#
# 007-parse-input-output.t
#
# Test the parsing of the INPUT (and implied INPUT section) and OUTPUT
# keywords of an XSUB. This is sort of an extension to
# 005-parse-parameters.t.
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
    # Test INPUT: keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "INPUT bad line",
            Q(<<'EOF'),
                |int
                |foo(abc)
                |    int + foo;
EOF
            [ERR, qr/^\QError: invalid parameter declaration '    int + foo;'\E.* line 7\n/,   "got expected error" ],
        ],
        [
            "INPUT no length()",
            Q(<<'EOF'),
                |int
                |foo(abc)
                |    int length(abc)
EOF
            [ERR, qr/^\QError: length() not permitted in INPUT section\E.* line 7\n/,   "got expected error" ],
        ],
        [
            "INPUT dup",
            Q(<<'EOF'),
                |int
                |foo(abc, int def)
                |    int abc
                |    int abc
                |    int def
EOF
            [ERR, qr/^\QError: duplicate definition of parameter 'abc' ignored in\E.* line 8\n/m,
                                        "abc: got expected error" ],

            [ERR, qr/^\QError: duplicate definition of parameter 'def' ignored in\E.* line 9\n/m,
                                        "def: got expected error" ],
        ],



        # Tests for [=+;] initialisers on INPUT lines (including embedded
        # double quotes within the expression, which get evalled)

        [
            "INPUT '='",

            Q(<<'EOF'),
                |int
                |foo(abc)
                |int abc = ($var"$var\"$type);
EOF
            [  0, qr/^ \s+ int \s+ abc\ =\ \Q(abc"abc"int);\E $/mx,
                                        "typemap was expanded" ],

        ],
        [
            "INPUT ';'",
            Q(<<'EOF'),
                |int
                |foo(abc, long xyz)
                |int abc ; blah($var"$var\"$type);
EOF
            [  0, qr/^ \s+ int \s+ abc;$/mx,
                                        "declaration doesn't have init" ],
            [  0, qr/xyz .*\n.*\Qblah(abc"abc"int);\E$/msx,
                                        "init code deferred and present" ],

        ],
        [
            "INPUT '+'",
            Q(<<'EOF'),
                |int
                |foo(abc, long xyz)
                |int abc + blurg($var"$var\"$type);
EOF
            [  0, qr/^ \s+ int \s+ abc \s+ = \s+ \Q(int)SvIV(ST(0))\E\n; $/mx,
                                        "std typemap was used and expanded" ],
            [  0, qr/xyz .*\n.*\Qblurg(abc"abc"int);\E$/msx,
                                        "deferred code present" ],

        ],

        # Tests for [=+;] initialisers on INPUT lines mixed with
        # default values

        [
            "default value and INPUT '='",

            Q(<<'EOF'),
                |int
                |foo(abc = 111)
                |int abc = 777;
EOF
            [ TODO, qr/if\s*\(items < 1\)\n\s*abc = 111;\n\s*else \{\n\s*abc = 777;\n\}\n/,
                "",
                "default is lost in presence of initialiser",
            ],

        ],
        [
            "default value and INPUT ';'",
            Q(<<'EOF'),
                |int
                |foo(abc = 111, long xyz)
                |int abc ; 777;
EOF
            [  0, qr/^ \s+ int \s+ abc;$/mx,
                                        "declaration doesn't have init" ],
            [  0, qr/xyz .*\n.*^777;$/msx,
                                        "init code deferred and present" ],

        ],
        [
            "default value and INPUT '+'",
            Q(<<'EOF'),
                |int
                |foo(abc = 111, long xyz)
                |int abc + 777;
EOF
            [  0, qr/^ \s+ int \s+ abc;$/mx,
                                        "declaration doesn't have init" ],
            [  0, qr/
                           \Qif (items < 1)\E\n
                        \s+\Qabc = 111;\E\n
                        \s+\Qelse {\E\n
                        \s+\Qabc = (int)SvIV(ST(0))\E\n
                      /msx,
                "conditional init code present" ],

            [  0, qr/
                        \s+\Qabc = (int)SvIV(ST(0))\E\n
                        \s*;\n\s*\}\n777;
                      /msx,
                "deferred code present" ],
        ],

        # Tests for [=+;] initialisers on INPUT lines mixed with
        # NO_INIT default values

        [
            "NO_INIT default value and INPUT '='",

            Q(<<'EOF'),
                |int
                |foo(abc = NO_INIT)
                |int abc = 777;
EOF
            [ TODO, qr/if\s*\(items >= 1\)\n\s*abc = 777;\n\s*}/,
                "",
                "default is lost in presence of initialiser",
            ],

        ],
        [
            "NO_INIT default value and INPUT ';'",
            Q(<<'EOF'),
                |int
                |foo(abc = NO_INIT, long xyz)
                |int abc ; 777;
EOF
            [  0, qr/^ \s+ int \s+ abc;$/mx,
                                        "declaration doesn't have init" ],
            [  0, qr/xyz .*\n.*^777;$/msx,
                                        "init code deferred and present" ],

        ],
        [
            "NO_INIT default value and INPUT '+'",
            Q(<<'EOF'),
                |int
                |foo(abc = NO_INIT, long xyz)
                |int abc + 777;
EOF
            [  0, qr/^ \s+ int \s+ abc;$/mx,
                                        "declaration doesn't have init" ],
            [  0, qr/
                           \Qif (items >= 1) {\E\n
                        \s+\Qabc = (int)SvIV(ST(0))\E\n
                      /msx,
                "conditional init code present" ],

            [  0, qr/\s*;\n\s*\}\n777; /msx,
                "deferred code present" ],
        ],

        # Test for initialisers with unknown variable type.
        # This previously died.

        [
            "INPUT initialiser with unknown type",
            Q(<<'EOF'),
                |void foo(a, b, c)
                |    UnknownType1 a = NO_INIT
                |    UnknownType2 b = bar();
                |    UnknownType3 c = baz($arg);
EOF
            [  0, qr/UnknownType1\s+a;/mx, "a decl" ],
            [  0, qr/UnknownType2\s+\Qb = bar();\E/mx, "b decl" ],
            [  0, qr/UnknownType3\s+\Qc = baz(ST(2));\E/mx, "c decl" ],
        ],

        # Test 'alien' INPUT parameters: ones which are declared in an INPUT
        # section but don't appear in the XSUB's signature. This ought to be
        # a compile error, but people rely on it to declare and initialise
        # variables which ought to be in a PREINIT or CODE section.

        [
            "alien INPUT vars",
            Q(<<'EOF'),
                |void foo()
                |    long alien1
                |    int  alien2 = 123;
                |    # see perl #112776
                |    SV  *alien3 = sv_2mortal(newSV());
EOF
            [  0, qr/long\s+alien1;\n/,      "alien1 decl" ],
            [  0, qr/int\s+alien2 = 123;\n/, "alien2 decl" ],
            [  0, qr/SV \*\s+alien3 = \Qsv_2mortal(newSV());\E\n/, "alien3 decl" ],
        ],

        # Test for 'length(foo)' not legal in INPUT section

        [
            "alien INPUT vars",
            Q(<<'EOF'),
                |void foo(s)
                |    char *s
                |    int  length(s)
EOF
            [ERR, qr/\QError: length() not permitted in INPUT section/,
                "got expected err" ],
        ],

        # Test for "duplicate definition of argument" errors

        [
            "duplicate INPUT vars",
            Q(<<'EOF'),
                |void foo(abc)
                |    int abc;
                |    int abc;
EOF
            [ERR, qr/\QError: duplicate definition of parameter 'abc'/,
                "got expected err" ],
        ],
        [
            "duplicate INPUT and signature vars",
            Q(<<'EOF'),
                |void foo(int abc)
                |    int abc;
EOF
            [ERR, qr/\QError: duplicate definition of parameter 'abc'/,
                "got expected err" ],
        ],
        [
            "duplicate alien INPUT vars",
            Q(<<'EOF'),
                |void foo()
                |    int abc;
                |    int abc;
EOF
            [ERR, qr/\QError: duplicate definition of parameter 'abc'/,
                "got expected err" ],
        ],

        # Missing initialiser

        [
            "INPUT: missing '=' initialiser",
            Q(<<'EOF'),
                |void foo(abc)
                |    int abc =  
EOF
            [ERR, qr/\QError: missing '=' initialiser value/,
                "got expected err" ],
        ],
        [
            "INPUT: missing '=' initialiser with semicolon",
            Q(<<'EOF'),
                |void foo(abc)
                |    int abc =  ;
EOF
            [ERR, qr/\QError: missing '=' initialiser value/,
                "got expected err" ],
        ],
        [
            "INPUT: missing '+' initialiser",
            Q(<<'EOF'),
                |void foo(abc)
                |    int abc +  
EOF
            [ERR, qr/\QError: missing '+' initialiser value/,
                "got expected err" ],
        ],
        [
            "INPUT: missing '+' initialiser with semicolon",
            Q(<<'EOF'),
                |void foo(abc)
                |    int abc +  ;
EOF
            [ERR, qr/\QError: missing '+' initialiser value/,
                "got expected err" ],
        ],
        [
            "INPUT: NOT missing ';' initialiser",
            Q(<<'EOF'),
                |void foo(abc)
                |    int abc ;  
EOF
            # this is NOT an error
        ],
        [
            "INPUT: missing ';' initialiser with semicolon",
            Q(<<'EOF'),
                |void foo(abc)
                |    int abc ;  ;
EOF
            [ERR, qr/\QError: missing ';' initialiser value/,
                "got expected err" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test OUTPUT: keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
        |TYPEMAP: <<EOF
        |blah T_BLAH
        |EOF
        |
EOF

    my @test_fns = (
        [
            "OUTPUT RETVAL",
            Q(<<'EOF'),
                |int
                |foo(int a)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      RETVAL
EOF
            [NOT, qr/\bSvSETMAGIC\b/,   "no set magic" ],
            [  0, qr/\bTARGi\b/,        "has TARGi" ],
            [  0, qr/\QXSRETURN(1)/,    "has XSRETURN" ],
        ],

        [
            "OUTPUT RETVAL with set magic ignored",
            Q(<<'EOF'),
                |int
                |foo(int a)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      SETMAGIC: ENABLE
                |      RETVAL
EOF
            [NOT, qr/\bSvSETMAGIC\b/,   "no set magic" ],
            [  0, qr/\bTARGi\b/,        "has TARGi" ],
            [  0, qr/\QXSRETURN(1)/,    "has XSRETURN" ],
        ],

        [
            "OUTPUT RETVAL with code",
            Q(<<'EOF'),
                |int
                |foo(int a)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      RETVAL PUSHs(my_newsviv(RETVAL));
EOF
            [  0, qr/\QPUSHs(my_newsviv(RETVAL));/,   "uses code" ],
            [  0, qr/\QXSRETURN(1)/,                  "has XSRETURN" ],
        ],

        [
            "OUTPUT RETVAL with code and template-like syntax",
            Q(<<'EOF'),
                |int
                |foo(int a)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      RETVAL baz($arg,$val);
EOF
            # Check that the override code is *not* template-expanded.
            # This was probably originally an implementation error, but
            # keep that behaviour for now for backwards compatibility.
            [  0, qr'baz\(\$arg,\$val\);',            "vars not expanded" ],
        ],

        [
            "OUTPUT RETVAL with code on IN_OUTLIST param",
            Q(<<'EOF'),
                |int
                |foo(IN_OUTLIST int abc)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      RETVAL
                |      abc  my_set(ST[0], RETVAL);
EOF
            [  0, qr/\Qmy_set(ST[0], RETVAL)/,      "code used for st(0)" ],
            [  0, qr/\bXSprePUSH;/,                 "XSprePUSH" ],
            [NOT, qr/\bEXTEND\b/,                   "NO extend"       ],
            [  0, qr/\QTARGi((IV)RETVAL, 1);/,      "push RETVAL" ],
            [  0, qr/\QRETVALSV = sv_newmortal();/, "create mortal" ],
            [  0, qr/\Qsv_setiv(RETVALSV, (IV)abc);/, "code not used for st(1)" ],
            [  0, qr/\QXSRETURN(2)/,                "has XSRETURN" ],
        ],

        [
            "OUTPUT RETVAL with code and unknown type",
            Q(<<'EOF'),
                |blah
                |foo(int a)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      RETVAL PUSHs(my_newsviv(RETVAL));
EOF
            [  0, qr/blah\s+RETVAL;/,                 "decl" ],
            [  0, qr/\QPUSHs(my_newsviv(RETVAL));/,   "uses code" ],
            [  0, qr/\QXSRETURN(1)/,                  "has XSRETURN" ],
        ],

        [
            "OUTPUT vars with set magic mixture",
            Q(<<'EOF'),
                |int
                |foo(int aaa, int bbb, int ccc, int ddd)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      RETVAL
                |      aaa
                |      SETMAGIC: ENABLE
                |      bbb
                |      SETMAGIC: DISABLE
                |      ccc
                |      SETMAGIC: ENABLE
                |      ddd  my_set(xyz)
EOF
            [  0, qr/\b\QSvSETMAGIC(ST(0))/,       "set magic ST(0)" ],
            [  0, qr/\b\QSvSETMAGIC(ST(1))/,       "set magic ST(1)" ],
            [NOT, qr/\b\QSvSETMAGIC(ST(2))/,       "no set magic ST(2)" ],
            [  0, qr/\b\QSvSETMAGIC(ST(3))/,       "set magic ST(3)" ],
            [  0, qr/\b\Qsv_setiv(ST(0),\E.*aaa/,  "setiv(aaa)" ],
            [  0, qr/\b\Qsv_setiv(ST(1),\E.*bbb/,  "setiv(bbb)" ],
            [  0, qr/\b\Qsv_setiv(ST(2),\E.*ccc/,  "setiv(ccc)" ],
            [NOT, qr/\b\Qsv_setiv(ST(3)/,          "no setiv(ddd)" ],
            [  0, qr/\b\Qmy_set(xyz)/,             "myset" ],
            [  0, qr/\bTARGi\b.*RETVAL/,           "has TARGi(RETVAL,1)" ],
            [  0, qr/\QXSRETURN(1)/,               "has XSRETURN" ],
        ],

        [
            "OUTPUT vars with set magic mixture per-CASE",
            Q(<<'EOF'),
                |int
                |foo(int a, int b)
                |   CASE: X
                |    OUTPUT:
                |        a
                |        SETMAGIC: DISABLE
                |        b
                |   CASE: Y
                |    OUTPUT:
                |        a
                |        SETMAGIC: DISABLE
                |        b
EOF
            [  0, qr{\Qif (X)\E
                       .*
                       \QSvSETMAGIC(ST(0));\E
                       .*
                       \Qelse if (Y)\E
                       }sx,                          "X: set magic ST(0)" ],
            [NOT, qr{\Qif (X)\E
                       .*
                       \QSvSETMAGIC(ST(1));\E
                       .*
                       \Qelse if (Y)\E
                       }sx,                          "X: no magic ST(1)" ],
            [  0, qr{\Qelse if (Y)\E
                       .*
                       \QSvSETMAGIC(ST(0));\E
                       }sx,                          "Y: set magic ST(0)" ],
            [NOT, qr{\Qelse if (Y)\E
                       .*
                       \QSvSETMAGIC(ST(1));\E
                       }sx,                          "Y: no magic ST(1)" ],
        ],

        [
            "duplicate OUTPUT RETVAL",
            Q(<<'EOF'),
                |int
                |foo(int aaa)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      RETVAL
                |      RETVAL
EOF
            [ERR, qr/Error: duplicate OUTPUT parameter 'RETVAL'/, "" ],
        ],

        [
            "duplicate OUTPUT parameter",
            Q(<<'EOF'),
                |int
                |foo(int aaa)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      RETVAL
                |      aaa
                |      aaa
EOF
            [ERR, qr/Error: duplicate OUTPUT parameter 'aaa'/, "" ],
        ],

        [
            "RETVAL in CODE without OUTPUT section",
            Q(<<'EOF'),
                |int
                |foo()
                |    CODE:
                |      RETVAL = 99
EOF
            [ERR, qr/Warning: found a 'CODE' section which seems to be using 'RETVAL' but no 'OUTPUT' section/, "" ],
        ],

        [
            # This one *shouldn't* warn. For a void XSUB, RETVAL
            # is just another local variable.
            "void RETVAL in CODE without OUTPUT section",
            Q(<<'EOF'),
                |void
                |foo()
                |    PREINIT:
                |      int RETVAL;
                |    CODE:
                |      RETVAL = 99
EOF
            [ERR|NOT, qr/Warning: found a 'CODE' section which seems to be using 'RETVAL' but no 'OUTPUT' section/, "no warn" ],
        ],

        [
            "RETVAL in CODE without being in OUTPUT",
            Q(<<'EOF'),
                |int
                |foo(int aaa)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      aaa
EOF
            [ERR, qr/Warning: found a 'CODE' section which seems to be using 'RETVAL' but no 'OUTPUT' section/, "" ],
        ],

        [
            "RETVAL in CODE without OUTPUT section, multiple CASEs",
            Q(<<'EOF'),
                |int
                |foo()
                |  CASE: X
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      RETVAL
                |  CASE: Y
                |    CODE:
                |      RETVAL = 99
EOF
            [ERR, qr/Warning: found a 'CODE' section which seems to be using 'RETVAL' but no 'OUTPUT' section/, "" ],
        ],

        [
            "OUTPUT RETVAL not a parameter",
            Q(<<'EOF'),
                |void
                |foo(int aaa)
                |    CODE:
                |      xyz
                |    OUTPUT:
                |      RETVAL
EOF
            [ERR, qr/\QError: OUTPUT RETVAL not a parameter/, "" ],
        ],

        [
            "OUTPUT RETVAL IS a parameter",
            Q(<<'EOF'),
                |int
                |foo(int aaa)
                |    CODE:
                |      xyz
                |    OUTPUT:
                |      RETVAL
EOF
            [ERR|NOT, qr/\QError: OUTPUT RETVAL not a parameter/, "" ],
        ],

        [
            "OUTPUT foo not a parameter",
            Q(<<'EOF'),
                |void
                |foo(int aaa)
                |    CODE:
                |      xyz
                |    OUTPUT:
                |      bbb
EOF
            [ERR, qr/\QError: OUTPUT bbb not a parameter/, "" ],
        ],

        [
            "OUTPUT length(foo) not a parameter",
            Q(<<'EOF'),
                |void
                |foo(char* aaa, int length(aaa))
                |    CODE:
                |      xyz
                |    OUTPUT:
                |      length(aaa)
EOF
            [ERR, qr/\QError: OUTPUT length(aaa) not a parameter/, "" ],
        ],

        [
            "OUTPUT SETMAGIC bad arg",
            Q(<<'EOF'),
                |void
                |foo(int abc)
                |    OUTPUT:
                |      SETMAGIC: 1
EOF
            [ERR, qr{\QError: SETMAGIC: invalid value '1' (should be ENABLE/DISABLE)}, "" ],
        ],

        [
            "OUTPUT with IN_OUTLIST",
            Q(<<'EOF'),
                |char*
                |foo(IN_OUTLIST int abc)
                |    CODE:
                |        RETVAL=999
                |    OUTPUT:
                |        RETVAL
                |        abc
EOF
            # OUT var - update arg 0 on stack
            [  0, qr/\b\Qsv_setiv(ST(0),\E.*abc/,  "setiv(ST0, abc)" ],
            [  0, qr/\b\QSvSETMAGIC(ST(0))/,       "set magic ST(0)" ],
            # prepare stack for OUTLIST
            [  0, qr/\bXSprePUSH\b/,               "XSprePUSH" ],
            [NOT, qr/\bEXTEND\b/,                  "NO extend"       ],
            # OUTPUT: RETVAL: push return value on stack
            [  0, qr/\bsv_setpv\(\(SV\*\)TARG,\s*RETVAL\)/,"sv_setpv(TARG, RETVAL)" ],
            [  0, qr/\QST(0) = TARG;/,             "has ST(0) = TARG" ],
            # OUTLIST: push abc on stack
            [  0, qr/\QRETVALSV = sv_newmortal();/, "create mortal" ],
            [  0, qr/\b\Qsv_setiv(RETVALSV, (IV)abc);/,"sv_setiv(RETVALSV, abc)" ],
            [  0, qr/\b\QST(1) = RETVALSV;\E\s+\}\s+\Q++SP;/, "store RETVALSV"],
            # and return RETVAL and abc
            [  0, qr/\QXSRETURN(2)/,               "has XSRETURN" ],

            # should only be one SvSETMAGIC
            [NOT, qr/\bSvSETMAGIC\b.*\bSvSETMAGIC\b/s,"only one SvSETMAGIC" ],
        ],

        [
            "OUTPUT with no output typemap entry",
            Q(<<'EOF'),
                |void
                |foo(blah a)
                |    OUTPUT:
                |      a
EOF
            [ERR|NOT, qr/\QError: no OUTPUT definition for type 'blah', typekind 'T_BLAH'\E.*line 11/,
                    "got expected error" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


done_testing;

#!/usr/bin/perl
#
# 005-parse-parameters.t
#
# Test the parsing of an individual parameter within the signature of an
# XSUB declaration.
#
# This concerned both with syntax, and some semantics, such as the
# processing of a parameter's type.
#
# There is a separate test file for XSUB return types, but some return
# type tests are here instead when they are testing same things that
# the corresponding parameter tests are doing.
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
    # Test very basic type lookups

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "known type",
            Q(<<'EOF'),
                |void
                |foo(int abc)
EOF
            [  0, qr/^\s+int\s+abc\s+=\s+\Q(int)SvIV(ST(0))/m, "" ],
        ],
        [
            "unknown type",
            Q(<<'EOF'),
                |void
                |foo(blah abc)
EOF
            [ERR, qr/Could not find a typemap for C type 'blah'/, " " ],
        ],
        [
            "custom type",
            Q(<<'EOF'),
                |TYPEMAP: <<EOF
                |myint   T_MYINT
                |INPUT
                |T_MYINT
                |  $var = ($type)MySvIV($arg)
                |EOF
                |
                |void
                |foo(myint abc)
EOF
            [  0, qr/^\s+myint\s+abc\s+=\s+\Q(myint)MySvIV(ST(0))/m, "" ],
        ],
        [
            "custom type with no template",
            Q(<<'EOF'),
                |TYPEMAP: <<EOF
                |myint   T_MYINT
                |EOF
                |
                |void
                |foo(myint abc)
EOF
            [ERR, qr/Error: no INPUT definition for type 'myint', typekind 'T_MYINT'/m, "" ],
        ],

        [
            "known return type",
            Q(<<'EOF'),
                |int
                |foo()
EOF
            [  0, qr/^\s+int\s+RETVAL\b/m, "decl" ],
            [  0, qr/\bTARGi\b/m,          "set" ],
        ],
        [
            "unknown return type",
            Q(<<'EOF'),
                |blah
                |foo()
EOF
            [ERR, qr/Could not find a typemap for C type 'blah'/, " " ],
        ],
        [
            "custom return type",
            Q(<<'EOF'),
                |TYPEMAP: <<EOF
                |myint   T_MYINT
                |OUTPUT
                |T_MYINT
                |  my_sv_setiv($arg, ($type)$var);
                |EOF
                |
                |myint
                |foo()
EOF
            [  0, qr/^\s+myint\s+RETVAL\b/m, "decl" ],
            [  0, qr/\b\Qmy_sv_setiv(RETVALSV, (myint)RETVAL)/m,  "set" ],
        ],
        [
            "custom return type with no template",
            Q(<<'EOF'),
                |TYPEMAP: <<EOF
                |myint   T_MYINT
                |EOF
                |
                |myint
                |foo(abc)
EOF
            [ERR, qr/Error: no OUTPUT definition for type 'myint'/m, "" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test very basic Perlish type lookups

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
        |TYPEMAP: <<EOF
        |X::Y   T_XY
        |P::Q   T_PQ
        |
        |INPUT
        |T_XY
        |  $var = ($type)MyXY($arg)
        |
        |OUTPUT
        |T_XY
        |  my_setxy($arg, ($type)$var);
        |
        |EOF
EOF

    my @test_fns = (
        [
            "known Perlish type",
            Q(<<'EOF'),
                |void
                |foo(X::Y abc)
EOF
            [  0, qr/^\s+X__Y\s+abc\s+=\s+\Q(X__Y)MyXY(ST(0))/m, "" ],
        ],
        [
            "unknown Perlish type",
            Q(<<'EOF'),
                |void
                |foo(X::Blah abc)
EOF
            [ERR, qr/Could not find a typemap for C type 'X::Blah'/, "" ],
        ],
        [
            "Perlish type with no template",
            Q(<<'EOF'),
                |void
                |foo(P::Q abc)
EOF
            [ERR, qr/Error: no INPUT definition for type 'P::Q'/m, "" ],
        ],

        [
            "known Perlish return type",
            Q(<<'EOF'),
                |X::Y
                |foo()
EOF
            [  0, qr/^\s+X__Y\s+RETVAL\b/m, "decl" ],
            [  0, qr/\b\Qmy_setxy(RETVALSV, (X__Y)RETVAL);/m, "set" ],
        ],
        [
            "unknown Perlish return type",
            Q(<<'EOF'),
                |X::Blah
                |foo()
EOF
            [ERR, qr/Could not find a typemap for C type 'X::Blah'/, " " ],
        ],
        [
            "Perlish return type with no template",
            Q(<<'EOF'),
                |P::Q
                |foo()
EOF
            [ERR, qr/Error: no OUTPUT definition for type 'P::Q'/m, "" ],
        ],

    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # misc checks for length() pseudo-parameter

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
EOF

    my @test_fns = (
        [
            "length() basic",
            Q(<<'EOF'),
                |void
                |foo(char *s, int length(s))
EOF
            [  0, qr{^\s+STRLEN\s+STRLEN_length_of_s;}m,  "decl STRLEN" ],
            [  0, qr{^\s+int\s+XSauto_length_of_s;}m,     "decl int"    ],

            [  0, qr{^ \s+ \Qchar *\E \s+
                        \Qs = (char *)SvPV(ST(0), STRLEN_length_of_s)}xm,
                                                            "decl s"      ],

            [  0, qr{^\s+\QXSauto_length_of_s = STRLEN_length_of_s}m,
                                                            "assign"     ],

            [  0, qr{^\s+\Qfoo(s, XSauto_length_of_s);}m, "autocall"   ],
        ],
        [
            "length() len type not in typemap allowed",
            Q(<<'EOF'),
                |void
                |foo(char *s, blah ** length(s))
EOF
            [  0, qr{^\s+\Qblah **\E\s+XSauto_length_of_s;}m, "decl xsauto" ],

        ],
        [
            # Some CPAN modules do their own explicit length-setting.
            # Check that such usage continues to work. See the discussion
            # in PR #23479
            "length() explict STRLEN_ use",
            Q(<<'EOF'),
                |TYPEMAP: <<EOF
                |byte_t  T_B
                |INPUT
                |T_B
                |  $var = SvPVutf8($arg,STRLEN_length_of_$var)
                |EOF
                |
                |void
                |foo(byte_t s, size_t length(s))
EOF
            [  0,
                qr{^\s+byte_t\s+s\s*=\s*\QSvPVutf8(ST(0),STRLEN_length_of_s)}m,
                "decl/init s" ],
        ],
        [
            # Work with typemaps for non-T_PV stuff which return
            # templates which could be modified to work with length().
            "length() modifiable typemap",
            Q(<<'EOF'),
                |TYPEMAP: <<EOF
                |byte_t  T_B
                |INPUT
                |T_B
                |  $var = SvPVutf8_nolen_abc($arg)
                |EOF
                |
                |void
                |foo(byte_t s, size_t length(s))
EOF
            [  0,
                qr{^\s+byte_t\s+s\s*=\s*\QSvPVutf8_abc(ST(0), STRLEN_length_of_s)}m,
                "decl/init s" ],
        ],
        [
            # .. but die if the typemap can't be modified
            "length() unrecognised typemap",
            Q(<<'EOF'),
                |TYPEMAP: <<EOF
                |byte_t  T_B
                |INPUT
                |T_B
                |  $var = SvPVutf8abc($arg)
                |EOF
                |
                |void
                |foo(byte_t s, size_t length(s))
EOF
            [ERR, qr{\QError: can't modify input typemap for length(s)\E.*line 13},
                   "got expected error" ],
        ],

        [
            "length() default value",
            Q(<<'EOF'),
                |void
                |foo(char *s, int length(s) = 0)
EOF
            [ERR, qr{\QError: default value not allowed on length() parameter 's'\E.*line 6},
                   "got expected error" ],
        ],
        [
            "length() NO_INIT",
            Q(<<'EOF'),
                |void
                |foo(char *s, int length(s) = NO_INIT)
EOF
            [ERR, qr{\QError: default value not allowed on length() parameter 's'\E.*line 6},
                   "got expected error" ],
        ],
        [
            "length() default value of string var",
            Q(<<'EOF'),
                |void
                |foo(int length(s), char *s = "")
EOF
            [ERR, qr{\QError: default value for s not allowed when length(s) also present\E.*line 6},
                   "got expected error" ],
        ],
        [
            "length() default value of string var, not T_PV",
            Q(<<'EOF'),
                |void
                |foo(int length(s), char **s = "")
EOF
            [ERR, qr{\QError: default value for s not allowed when length(s) also present\E.*line 6},
                   "got expected error" ],
        ],
        [
            "length() no matching var",
            Q(<<'EOF'),
                |void
                |foo(int length(s))
EOF
            [ERR, qr{\QError: length() on non-parameter 's'\E.*line 6},
                   "got expected error" ],
        ],
        [
            "length() on placeholder var",
            Q(<<'EOF'),
                |void
                |foo(s, int length(s))
EOF
            [ERR, qr{\QError: length() on placeholder parameter 's'\E.*line 6},
                   "got expected error" ],
        ],
        [
            "length() no type",
            Q(<<'EOF'),
                |void
                |foo(char *s, length(s))
EOF
            [ERR, qr{\QError: length(s) doesn't have a type specified\E.*line 6},
                   "got expected error" ],
        ],

        # Ban IN_OUT etc. A couple of these sort-of could make sense,
        # but aren't particularly useful, and the semantics aren't
        # obvious. So ban the 'might work' ones as well as the 'makes no
        # sense' ones.
        [
            "IN length()",
            Q(<<'EOF'),
                |void
                |foo(char *s, IN int length(s))
EOF
            [ERR, qr{\QError: 'IN' modifier can't be used with length(s)\E.*line 6},
                   "got expected error" ],
        ],
        [
            "OUT length()",
            Q(<<'EOF'),
                |void
                |foo(char *s, OUT int length(s))
EOF
            [ERR, qr{\QError: 'OUT' modifier can't be used with length(s)\E.*line 6},
                   "got expected error" ],
        ],
        [
            "IN_OUT length()",
            Q(<<'EOF'),
                |void
                |foo(char *s, IN_OUT int length(s))
EOF
            [ERR, qr{\QError: 'IN_OUT' modifier can't be used with length(s)\E.*line 6},
                   "got expected error" ],
        ],
        [
            "OUTLIST length()",
            Q(<<'EOF'),
                |void
                |foo(char *s, OUTLIST int length(s))
EOF
            [ERR, qr{\QError: 'OUTLIST' modifier can't be used with length(s)\E.*line 6},
                   "got expected error" ],
        ],
        [
            "IN_OUTLIST length()",
            Q(<<'EOF'),
                |void
                |foo(char *s, IN_OUTLIST int length(s))
EOF
            [ERR, qr{\QError: 'IN_OUTLIST' modifier can't be used with length(s)\E.*line 6},
                   "got expected error" ],
        ],

        # Ban OUT* on the corresponding parameter var. Currently we can't
        # retrieve the length without also setting the char* var.

        # IN* variants ok
        [
            "IN s, length(s)",
            Q(<<'EOF'),
                |void
                |foo(IN char *s, int length(s))
EOF
            # no error expected
        ],
        [
            "IN_OUT s, length(s)",
            Q(<<'EOF'),
                |void
                |foo(IN_OUT char *s, int length(s))
EOF
            # no error expected
        ],
        [
            "IN_OUTLIST s, length(s)",
            Q(<<'EOF'),
                |void
                |foo(IN_OUTLIST char *s, int length(s))
EOF
            # no error expected
        ],

        # non-IN* variants not ok
        [
            "OUT s, length(s)",
            Q(<<'EOF'),
                |void
                |foo(OUT char *s, int length(s))
EOF
            [ERR, qr{\QError: 'OUT' modifier on 's' can't be used with length()\E.*line 6},
                   "got expected error" ],
        ],
        [
            "OUTLIST s, length(s)",
            Q(<<'EOF'),
                |void
                |foo(OUTLIST char *s, int length(s))
EOF
            [ERR, qr{\QError: 'OUTLIST' modifier on 's' can't be used with length()\E.*line 6},
                   "got expected error" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test OUTLIST etc

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |TYPEMAP: <<EOF
        |mybool        T_MYBOOL
        |
        |OUTPUT
        |T_MYBOOL
        |    ${"$var" eq "RETVAL" ? \"$arg = boolSV($var);" : \"sv_setsv($arg, boolSV($var));"}
        |EOF
EOF

    my @test_fns = (
        [
            "IN OUT",
            Q(<<'EOF'),
                |void
                |foo(IN int A, IN_OUT int B, OUT int C, OUTLIST int D, IN_OUTLIST int E)
EOF
            [  0, qr/\Qusage(cv,  "A, B, C, E")/,    "usage"    ],

            [  0, qr/int\s+A\s*=\s*\(int\)SvIV\s*/,  "A decl"   ],
            [  0, qr/int\s+B\s*=\s*\(int\)SvIV\s*/,  "B decl"   ],
            [  0, qr/int\s+C\s*;/,                   "C decl"   ],
            [  0, qr/int\s+D\s*;/,                   "D decl"   ],
            [  0, qr/int\s+E\s*=\s*\(int\)SvIV\s*/,  "E decl"   ],

            [  0, qr/\Qfoo(A, &B, &C, &D, &E)/,      "autocall" ],

            [  0, qr/sv_setiv.*ST\(1\).*\bB\b/,      "set B"    ],
            [  0, qr/\QSvSETMAGIC(ST(1))/,           "set magic B" ],
            [  0, qr/sv_setiv.*ST\(2\).*\bC\b/,      "set C"    ],
            [  0, qr/\QSvSETMAGIC(ST(2))/,           "set magic C" ],

            [NOT, qr/\bEXTEND\b/,                    "NO extend"       ],

            [  0, qr/\b\QTARGi((IV)D, 1);\E\s+\QST(0) = TARG;\E\s+\}\s+\Q++SP;/, "set D"    ],
            [  0, qr/\b\Qsv_setiv(RETVALSV, (IV)E);\E\s+\QST(1) = RETVALSV;\E\s+\}\s+\Q++SP;/, "set E"    ],
        ],

        # The same set of tests, but this time the types of the variables
        # are specified in INPUT lines rather than in the signature.
        [
            "IN OUT using INPUT",
            Q(<<'EOF'),
                |void
                |foo(IN A, IN_OUT B, OUT C, OUTLIST D, IN_OUTLIST E)
                |  int A
                |  int B
                |  int C
                |  int D
                |  int E
EOF
            [  0, qr/\Qusage(cv,  "A, B, C, E")/,    "usage"    ],

            [  0, qr/int\s+A\s*=\s*\(int\)SvIV\s*/,  "A decl"   ],
            [  0, qr/int\s+B\s*=\s*\(int\)SvIV\s*/,  "B decl"   ],
            [  0, qr/int\s+C\s*;/,                   "C decl"   ],
            [  0, qr/int\s+D\s*;/,                   "D decl"   ],
            [  0, qr/int\s+E\s*=\s*\(int\)SvIV\s*/,  "E decl"   ],

            [  0, qr/\Qfoo(A, &B, &C, &D, &E)/,      "autocall" ],

            [  0, qr/sv_setiv.*ST\(1\).*\bB\b/,      "set B"    ],
            [  0, qr/\QSvSETMAGIC(ST(1))/,           "set magic B" ],
            [  0, qr/sv_setiv.*ST\(2\).*\bC\b/,      "set C"    ],
            [  0, qr/\QSvSETMAGIC(ST(2))/,           "set magic C" ],

            [NOT, qr/\bEXTEND\b/,                    "NO extend"       ],

            [  0, qr/\b\QTARGi((IV)D, 1);\E\s+\QST(0) = TARG;\E\s+\}\s+\Q++SP;/, "set D"    ],
            [  0, qr/\b\Qsv_setiv(RETVALSV, (IV)E);\E\s+\QST(1) = RETVALSV;\E\s+\}\s+\Q++SP;/, "set E"    ],
        ],

        # Various types of OUTLIST where the param is the only value to
        # be returned. Includes some types which might be optimised.

        [
            "OUTLIST void/bool",
            Q(<<'EOF'),
                |void
                |foo(OUTLIST bool A)
EOF
            [  0, qr/\bXSprePUSH;/,                    "XSprePUSH"       ],
            [NOT, qr/\bEXTEND\b/,                      "NO extend"       ],
            [  0, qr/\b\QRETVALSV = sv_newmortal();/ , "create new mortal" ],
            [  0, qr/\b\Qsv_setsv(RETVALSV, boolSV(A));/, "set RETVALSV"   ],
            [  0, qr/\b\QST(0) = RETVALSV;\E\s+\}\s+\Q++SP;/, "store RETVALSV"],
            [  0, qr/\b\QXSRETURN(1);/,                "XSRETURN(1)"     ],
        ],
        [
            "OUTLIST void/mybool",
            Q(<<'EOF'),
                |void
                |foo(OUTLIST mybool A)
EOF
            [  0, qr/\bXSprePUSH;/,                    "XSprePUSH"       ],
            [NOT, qr/\bEXTEND\b/,                      "NO extend"       ],
            [  0, qr/\b\QRETVALSV = sv_newmortal();/ , "create new mortal" ],
            [  0, qr/\b\Qsv_setsv(RETVALSV, boolSV(A));/, "set RETVALSV"   ],
            [  0, qr/\b\QST(0) = RETVALSV;\E\s+\}\s+\Q++SP;/, "store RETVALSV"],
            [  0, qr/\b\QXSRETURN(1);/,                "XSRETURN(1)"     ],
        ],
        [
            "OUTLIST void/int",
            Q(<<'EOF'),
                |void
                |foo(OUTLIST int A)
EOF
            [  0, qr/\bXSprePUSH;/,                    "XSprePUSH"       ],
            [NOT, qr/\bEXTEND\b/,                      "NO extend"       ],
            [NOT, qr/\bsv_newmortal\b;/,               "NO new mortal"   ],
            [  0, qr/\bdXSTARG;/,                      "dXSTARG"         ],
            [  0, qr/\b\QTARGi((IV)A, 1);/,            "set TARG"        ],
            [  0, qr/\b\QST(0) = TARG;\E\s+\}\s+\Q++SP;/, "store TARG"   ],
            [  0, qr/\b\QXSRETURN(1);/,                "XSRETURN(1)"     ],
        ],
        [
            "OUTLIST void/char*",
            Q(<<'EOF'),
                |void
                |foo(OUTLIST char* A)
EOF
            [  0, qr/\bXSprePUSH;/,                    "XSprePUSH"       ],
            [NOT, qr/\bEXTEND\b/,                      "NO extend"       ],
            [NOT, qr/\bsv_newmortal\b;/,               "NO new mortal"   ],
            [  0, qr/\bdXSTARG;/,                      "dXSTARG"         ],
            [  0, qr/\b\Qsv_setpv((SV*)TARG, A);/,     "set TARG"        ],
            [  0, qr/\b\QST(0) = TARG;\E\s+\}\s+\Q++SP;/, "store TARG"   ],
            [  0, qr/\b\QXSRETURN(1);/,                "XSRETURN(1)"     ],
        ],

        # Various types of OUTLIST where the param is the second value to
        # be returned. Includes some types which might be optimised.

        [
            "OUTLIST int/bool",
            Q(<<'EOF'),
                |int
                |foo(OUTLIST bool A)
EOF
            [  0, qr/\bXSprePUSH;/,                    "XSprePUSH"       ],
            [  0, qr/\b\QEXTEND(SP,2);/,               "extend 2"        ],
            [  0, qr/\b\QTARGi((IV)RETVAL, 1);/,       "TARGi RETVAL"    ],
            [  0, qr/\b\QST(0) = TARG;\E\s+\Q++SP;/,   "store RETVAL,SP++" ],
            [  0, qr/\b\QRETVALSV = sv_newmortal();/ , "create new mortal" ],
            [  0, qr/\b\Qsv_setsv(RETVALSV, boolSV(A));/, "set RETVALSV"   ],
            [  0, qr/\b\QST(1) = RETVALSV;\E\s+\}\s+\Q++SP;/, "store RETVALSV"],
            [  0, qr/\b\QXSRETURN(2);/,                "XSRETURN(2)"     ],
        ],
        [
            "OUTLIST int/mybool",
            Q(<<'EOF'),
                |int
                |foo(OUTLIST mybool A)
EOF
            [  0, qr/\bXSprePUSH;/,                    "XSprePUSH"       ],
            [  0, qr/\b\QEXTEND(SP,2);/,               "extend 2"        ],
            [  0, qr/\b\QTARGi((IV)RETVAL, 1);/,       "TARGi RETVAL"    ],
            [  0, qr/\b\QST(0) = TARG;\E\s+\Q++SP;/,   "store RETVAL,SP++" ],
            [  0, qr/\b\QRETVALSV = sv_newmortal();/ , "create new mortal" ],
            [  0, qr/\b\Qsv_setsv(RETVALSV, boolSV(A));/, "set RETVALSV"   ],
            [  0, qr/\b\QST(1) = RETVALSV;\E\s+\}\s+\Q++SP;/, "store RETVALSV"],
            [  0, qr/\b\QXSRETURN(2);/,                "XSRETURN(2)"     ],
        ],
        [
            "OUTLIST int/int",
            Q(<<'EOF'),
                |int
                |foo(OUTLIST int A)
EOF
            [  0, qr/\bXSprePUSH;/,                    "XSprePUSH"       ],
            [  0, qr/\b\QEXTEND(SP,2);/,               "extend 2"        ],
            [  0, qr/\b\QTARGi((IV)RETVAL, 1);/,       "TARGi RETVAL"    ],
            [  0, qr/\b\QST(0) = TARG;\E\s+\Q++SP;/,   "store RETVAL,SP++" ],
            [  0, qr/\b\QRETVALSV = sv_newmortal();/ , "create new mortal" ],
            [  0, qr/\b\Qsv_setiv(RETVALSV, (IV)A);/,  "set RETVALSV"   ],
            [  0, qr/\b\QST(1) = RETVALSV;\E\s+\}\s+\Q++SP;/, "store RETVALSV"],
            [  0, qr/\b\QXSRETURN(2);/,                "XSRETURN(2)"     ],
        ],
        [
            "OUTLIST int/char*",
            Q(<<'EOF'),
                |int
                |foo(OUTLIST char* A)
EOF
            [  0, qr/\bXSprePUSH;/,                    "XSprePUSH"       ],
            [  0, qr/\b\QEXTEND(SP,2);/,               "extend 2"        ],
            [  0, qr/\b\QTARGi((IV)RETVAL, 1);/,       "TARGi RETVAL"    ],
            [  0, qr/\b\QST(0) = TARG;\E\s+\Q++SP;/,   "store RETVAL,SP++" ],
            [  0, qr/\b\QRETVALSV = sv_newmortal();/ , "create new mortal" ],
            [  0, qr/\b\Qsv_setpv((SV*)RETVALSV, A);/, "set RETVALSV"   ],
            [  0, qr/\b\QST(1) = RETVALSV;\E\s+\}\s+\Q++SP;/, "store RETVALSV"],
            [  0, qr/\b\QXSRETURN(2);/,                "XSRETURN(2)"     ],
        ],
        [
            "OUTLIST int/opt int",
            Q(<<'EOF'),
                |int
                |foo(IN_OUTLIST int A = 0)
EOF
            [  0, qr/\bXSprePUSH;/,                    "XSprePUSH"       ],
            [  0, qr/\b\QEXTEND(SP,2);/,               "extend 2"        ],
            [  0, qr/\b\QTARGi((IV)RETVAL, 1);/,       "TARGi RETVAL"    ],
            [  0, qr/\b\QST(0) = TARG;\E\s+\Q++SP;/,   "store RETVAL,SP++" ],
            [  0, qr/\b\QRETVALSV = sv_newmortal();/ , "create new mortal" ],
            [  0, qr/\b\Qsv_setiv(RETVALSV, (IV)A);/,  "set RETVALSV"   ],
            [  0, qr/\b\QST(1) = RETVALSV;\E\s+\}\s+\Q++SP;/, "store RETVALSV"],
            [  0, qr/\b\QXSRETURN(2);/,                "XSRETURN(2)"     ],
        ],
        [
            "OUTLIST with OUTPUT override",
            Q(<<'EOF'),
                |void
                |foo(IN_OUTLIST int A)
                |    OUTPUT:
                |        A    setA(ST[99], A);
EOF
            [NOT, qr/\bEXTEND\b/,                      "NO extend"       ],
            [  0, qr/\b\QsetA(ST[99], A);/,            "set ST[99]"      ],
            [  0, qr/\b\QTARGi((IV)A, 1);/,            "set ST[0]"       ],
            [  0, qr/\b\QXSRETURN(1);/,                "XSRETURN(1)"     ],
        ],
        [
            "OUTLIST with multiple CASES",
            Q(<<'EOF'),
                 |void
                 |foo(OUTLIST int a, OUTLIST int b)
                 |    CASE: A
                 |        CODE:
                 |            AAA
                 |    CASE: B
                 |        CODE:
                 |            BBB
EOF
            [  0, qr{\bdXSTARG; .* \bdXSTARG;}xs,       "two dXSTARG"    ],
            [  0, qr{   \b\QEXTEND(SP,2);\E
                       .* \b\QEXTEND(SP,2);\E }xs,        "two EXTEND(2)"  ],
            [  0, qr{\b\QST(0) = \E .* \b\QST(0) = }xs, "two ST(0)"      ],
            [  0, qr{\b\QST(1) = \E .* \b\QST(1) = }xs, "two ST(1)"      ],
            [  0, qr/\b\QXSRETURN(2);/,                 "XSRETURN(2)"    ],
            [NOT, qr{XSRETURN.*XSRETURN}xs,             "<2 XSRETURNs"   ],
        ],
        [
            "OUTLIST with multiple CASES and void hack",
            Q(<<'EOF'),
                 |void
                 |foo(OUTLIST int a, OUTLIST int b)
                 |    CASE: A
                 |        CODE:
                 |            ST(0) = 1;
                 |    CASE: B
                 |        CODE:
                 |            ST(0) = 2;
EOF
            [  0, qr{\bdXSTARG; .* \bdXSTARG;}xs,       "two dXSTARG"    ],
            [  0, qr{   \b\QEXTEND(SP,3);\E
                       .* \b\QEXTEND(SP,3);\E }xs,        "two EXTEND(3)"  ],
            [  0, qr{\b\QST(0) = 1\E .* \QST(0) = 2}xs, "two ST(0)"      ],
            [  0, qr{   \b\QST(1) = TARG\E
                       .* \b\QST(1) = TARG}xs,            "two ST(1)"      ],
            [  0, qr{   \b\QST(2) = RETVAL\E
                       .* \b\QST(2) = RETVAL}xs,          "two ST(2)"      ],
            [  0, qr/\b\QXSRETURN(3);/,                 "XSRETURN(3)"    ],
            [NOT, qr{XSRETURN.*XSRETURN}xs,             "<2 XSRETURNs"   ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}

{
    # Test OUTLIST on 'assign' format typemaps.
    #
    # Test code for returning the value of OUTLIST vars for typemaps of
    # the form
    #
    #   $arg = $val;
    # or
    #   $arg = newFoo($arg);
    #
    # Includes whether RETVALSV ha been optimised away.
    #
    # Some of the typemaps don't expand to the 'assign' form yet for
    # OUTLIST vars; we test those too.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |TYPEMAP: <<EOF
        |
        |svref_fix   T_SVREF_REFCOUNT_FIXED
        |mysvref_fix T_MYSVREF_REFCOUNT_FIXED
        |mybool      T_MYBOOL
        |
        |OUTPUT
        |T_SV
        |    $arg = $var;
        |
        |T_MYSVREF_REFCOUNT_FIXED
        |    $arg = newRV_noinc((SV*)$var);
        |
        |T_MYBOOL
        |    $arg = boolSV($var);
        |
        |EOF
EOF

    my @test_fns = (
        [
            # This uses 'SV*' (handled specially by EU::PXS) but with the
            # output code overridden to use the direct $arg = $var assign,
            # which is normally only used for RETVAL return
            "OUTLIST T_SV",
            Q(<<'EOF'),
                |int
                |foo(OUTLIST SV * A)
EOF
            [NOT, qr/\bRETVALSV\b/,                        "NO RETVALSV"    ],
            [  0, qr/\b\QA = sv_2mortal(A);/,              "mortalise A"    ],
            [  0, qr/\b\QST(1) = A;/,                      "store A"        ],
        ],

        [
            "OUTLIST T_SVREF",
            Q(<<'EOF'),
                |int
                |foo(OUTLIST SVREF A)
EOF
            [  0, qr/SV\s*\*\s*RETVALSV;/,                 "RETVALSV"       ],
            [  0, qr/\b\QRETVALSV = newRV((SV*)A)/,        "newREF(A)"      ],
            [  0, qr/\b\QRETVALSV = sv_2mortal(RETVALSV);/,"mortalise RSV"  ],
            [  0, qr/\b\QST(1) = RETVALSV;/,               "store RETVALSV" ],
        ],

        [
            # this one doesn't use assign for OUTLIST
            "OUTLIST T_SVREF_REFCOUNT_FIXED",
            Q(<<'EOF'),
                |int
                |foo(OUTLIST svref_fix A)
EOF
            [  0, qr/SV\s*\*\s*RETVALSV;/,                 "RETVALSV"       ],
            [  0, qr/\b\QRETVALSV = sv_newmortal();/ ,     "new mortal"     ],
            [  0, qr/\b\Qsv_setrv_noinc(RETVALSV, (SV*)A);/,"setrv()"       ],
            [  0, qr/\b\QST(1) = RETVALSV;/,               "store RETVALSV" ],
        ],
        [
            # while this one uses assign
            "OUTLIST T_MYSVREF_REFCOUNT_FIXED",
            Q(<<'EOF'),
                |int
                |foo(OUTLIST mysvref_fix A)
EOF
            [  0, qr/SV\s*\*\s*RETVALSV;/,                 "RETVALSV"       ],
            [  0, qr/\b\QRETVALSV = newRV_noinc((SV*)A)/,  "newRV(A)"       ],
            [  0, qr/\b\QRETVALSV = sv_2mortal(RETVALSV);/,"mortalise RSV"  ],
            [  0, qr/\b\QST(1) = RETVALSV;/,               "store RETVALSV" ],
        ],

        [
            # this one doesn't use assign for OUTLIST
            "OUTLIST T_BOOL",
            Q(<<'EOF'),
                |int
                |foo(OUTLIST bool A)
EOF
            [  0, qr/SV\s*\*\s*RETVALSV;/,                 "RETVALSV"       ],
            [  0, qr/\b\QRETVALSV = sv_newmortal();/ ,     "new mortal"     ],
            [  0, qr/\b\Qsv_setsv(RETVALSV, boolSV(A));/,  "setsv(boolSV())"],
            [  0, qr/\b\QST(1) = RETVALSV;/,               "store RETVALSV" ],
        ],
        [
            # while this one uses assign
            "OUTLIST T_MYBOOL",
            Q(<<'EOF'),
                |int
                |foo(OUTLIST mybool A)
EOF
            [NOT, qr/\bRETVALSV\b/,                        "NO RETVALSV"    ],
            [  0, qr/\b\QST(1) = boolSV(A)/,               "store boolSV(A)"],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test function pointer args and return values

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
        |TYPEMAP: <<EOF
        |int (*)(char *, long) T_FP
        |INPUT
        |T_FP
        |    $var = get_fn_ptr($arg)
        |OUTPUT
        |T_FP
        |    set_fn_ptr($var, $arg)
        |
        |EOF
EOF

    my @test_fns = (
        [
            "function pointer arg type",
            Q(<<'EOF'),
                |short
                |foo(int (*)(char *, long) p)
EOF
            [  0, qr/\Qint (* p )(char *, long) = get_fn_ptr(ST(0))/,
                        "var decl" ],
        ],
        [
            "function pointer arg type, INPUT",
            Q(<<'EOF'),
                |short
                |foo(p)
                |    int (*)(char *, long) p
EOF
            [  0, qr/\Qint (* p )(char *, long) = get_fn_ptr(ST(0))/,
                        "var decl" ],
        ],
        [
            "function pointer return type",
            Q(<<'EOF'),
                |int (*)(char *, long)
                |foo(short s)
EOF
            [  0, qr/\Qint ( * RETVAL  )(char * , long);/,
                        "RETVAL decl" ],
            [  0, qr/set_fn_ptr\(RETVAL,.*\)/, "RETVAL set value" ],
        ],

    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test placeholders - various semi-official ways to to mark an
    # argument as 'unused'.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (

        [
            "placeholder: typeless param with CODE",
            Q(<<'EOF'),
                |int
                |foo(int AAA, BBB, int CCC)
                |   CODE:
                |      XYZ;
EOF
            [  0, qr/_usage\(cv,\s*"AAA, BBB, CCC"\)/,      "usage" ],
            [  0, qr/\bint\s+AAA\s*=\s*.*\Q(ST(0))/,        "AAA is ST(0)" ],
            [  0, qr/\bint\s+CCC\s*=\s*.*\Q(ST(2))/,        "CCC is ST(2)" ],
            [NOT, qr/\bBBB;/,                               "no BBB decl" ],
        ],

        [
            "placeholder: typeless param bodiless",
            Q(<<'EOF'),
                |int
                |foo(int AAA, BBB, int CCC)
EOF
            [  0, qr/_usage\(cv,\s*"AAA, BBB, CCC"\)/,      "usage" ],
            # Note that autocall uses the BBB var even though it isn't
            # declared. It would be up to the coder to use C_ARGS, or add
            # such a var via PREINIT.
            [  0, qr/\bRETVAL\s*=\s*\Qfoo(AAA, BBB, CCC);/, "autocall" ],
            [  0, qr/\bint\s+AAA\s*=\s*.*\Q(ST(0))/,        "AAA is ST(0)" ],
            [  0, qr/\bint\s+CCC\s*=\s*.*\Q(ST(2))/,        "CCC is ST(2)" ],
            [NOT, qr/\bBBB;/,                               "no BBB decl" ],
        ],

        [
            # this is the only IN/OUT etc one which works, since IN is the
            # default.
            "placeholder: typeless IN param with CODE",
            Q(<<'EOF'),
                |int
                |foo(int AAA, IN BBB, int CCC)
                |   CODE:
                |      XYZ;
EOF
            [  0, qr/_usage\(cv,\s*"AAA, BBB, CCC"\)/,      "usage" ],
            [  0, qr/\bint\s+AAA\s*=\s*.*\Q(ST(0))/,        "AAA is ST(0)" ],
            [  0, qr/\bint\s+CCC\s*=\s*.*\Q(ST(2))/,        "CCC is ST(2)" ],
            [NOT, qr/\bBBB;/,                               "no BBB decl" ],
        ],


        [
            "placeholder: typeless OUT param with CODE",
            Q(<<'EOF'),
                |int
                |foo(int AAA, OUT BBB, int CCC)
                |   CODE:
                |      XYZ;
EOF
            [ERR, qr/Error: can't determine output type for 'BBB'/, "got type err" ],
        ],

        [
            "placeholder: typeless IN_OUT param with CODE",
            Q(<<'EOF'),
                |int
                |foo(int AAA, IN_OUT BBB, int CCC)
                |   CODE:
                |      XYZ;
EOF
            [ERR, qr/Error: can't determine output type for 'BBB'/, "got type err" ],
        ],

        [
            "placeholder: typeless OUTLIST param with CODE",
            Q(<<'EOF'),
                |int
                |foo(int AAA, OUTLIST BBB, int CCC)
                |   CODE:
                |      XYZ;
EOF
            [ERR, qr/Error: can't determine output type for 'BBB'/, "got type err" ],
        ],

        [
            # a placeholder with a default value may not seem to make much
            # sense, but it allows an argument to still be passed (or
            # not), even if it;s no longer used.
            "placeholder: typeless default param with CODE",
            Q(<<'EOF'),
                |int
                |foo(int AAA, BBB = 888, int CCC = 999)
                |   CODE:
                |      XYZ;
EOF
            [  0, qr/_usage\(cv,\s*"AAA, BBB = 888, CCC\s*= 999"\)/,"usage" ],
            [  0, qr/\bint\s+AAA\s*=\s*.*\Q(ST(0))/,        "AAA is ST(0)" ],
            [  0, qr/\bCCC\s*=\s*.*\Q(ST(2))/,              "CCC is ST(2)" ],
            [NOT, qr/\bBBB;/,                               "no BBB decl" ],
            [NOT, qr/\b888\s*;/,                            "no 888 usage" ],
        ],

        [
            "placeholder: allow SV *",
            Q(<<'EOF'),
                |int
                |foo(int AAA, SV *, int CCC)
                |   CODE:
                |      XYZ;
EOF
            [  0, qr/_usage\(cv,\s*\Q"AAA, SV *, CCC")/,    "usage" ],
            [  0, qr/\bint\s+AAA\s*=\s*.*\Q(ST(0))/,        "AAA is ST(0)" ],
            [  0, qr/\bint\s+CCC\s*=\s*.*\Q(ST(2))/,        "CCC is ST(2)" ],
        ],

        [
            # Bodiless XSUBs can't use SV* as a placeholder ...
            "placeholder: SV *, bodiless",
            Q(<<'EOF'),
                |int
                |foo(int AAA, SV    *, int CCC)
EOF
            [ERR, qr/Error: parameter 'SV \*' not valid as a C argument/,
                                                           "got arg err" ],
        ],

        [
            # ... unless they use C_ARGS to define how the C fn should
            # be called.
            "placeholder: SV *, bodiless C_ARGS",
            Q(<<'EOF'),
                |int
                |foo(int AAA, SV    *, int CCC)
                |    C_ARGS: AAA, CCC
EOF
            [  0, qr/_usage\(cv,\s*\Q"AAA, SV *, CCC")/,    "usage" ],
            [  0, qr/\bint\s+AAA\s*=\s*.*\Q(ST(0))/,        "AAA is ST(0)" ],
            [  0, qr/\bint\s+CCC\s*=\s*.*\Q(ST(2))/,        "CCC is ST(2)" ],
            [  0, qr/\bRETVAL\s*=\s*\Qfoo(AAA, CCC);/,      "autocall" ],
        ],


    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test weird packing facility: DO_ARRAY_ELEM

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
        |TYPEMAP: <<EOF
        |intArray *        T_ARRAY
        |longArray *       T_ARRAY
        |
        |myiv              T_IV
        |myivArray *       T_ARRAY
        |
        |blah              T_BLAH
        |blahArray *       T_ARRAY
        |
        |nosuchtypeArray * T_ARRAY
        |
        |shortArray *      T_DAE
        |NoInputArray *    T_DAE
        |NoInput           T_Noinput
        |
        |NooutputArray *   T_ARRAY
        |Nooutput          T_Nooutput
        |
        |INPUT
        |T_BLAH
        |   $var = my_get_blah($arg);
        |
        |T_DAE
        |   IN($var,$type,$ntype,$subtype,$arg,$argoff){DO_ARRAY_ELEM}
        |
        |OUTPUT
        |T_BLAH
        |   my_set_blah($arg, $var);
        |
        |T_DAE
        |   OUT($var,$type,$ntype,$subtype,$arg){DO_ARRAY_ELEM}
        |
        |EOF
EOF

    my @test_fns = (

        [
            "T_ARRAY long input",
            Q(<<'EOF'),
                |char *
                |foo(longArray * abc)
EOF
            [  0, qr/longArray\s*\*\s*abc;/,      "abc is longArray*" ],
            [  0, qr/abc\s*=\s*longArrayPtr\(/,   "longArrayPtr called" ],
            [  0, qr/abc\[ix_abc.*\]\s*=\s*.*\QSvIV(ST(ix_abc))/,
                                                    "abc[i] set" ],
            [NOT, qr/DO_ARRAY_ELEM/,              "no DO_ARRAY_ELEM" ],
        ],
        [
            "T_ARRAY long output",
            Q(<<'EOF'),
                |longArray *
                |foo()
EOF
            [  0, qr/longArray\s*\*\s*RETVAL;/,   "RETVAL is longArray*" ],
            [NOT, qr/longArrayPtr/,               "longArrayPtr NOT called" ],
            [  0, qr/\Qsv_setiv(ST(ix_RETVAL), (IV)RETVAL[ix_RETVAL]);/,
                                                    "ST(i) set" ],
            [NOT, qr/DO_ARRAY_ELEM/,              "no DO_ARRAY_ELEM" ],
        ],

        [
            "T_ARRAY myiv input",
            Q(<<'EOF'),
                |char *
                |foo(myivArray * abc)
EOF
            [  0, qr/myivArray\s*\*\s*abc;/,      "abc is myivArray*" ],
            [  0, qr/abc\s*=\s*myivArrayPtr\(/,   "myivArrayPtr called" ],
            [  0, qr/abc\[ix_abc.*\]\s*=\s*.*\QSvIV(ST(ix_abc))/,
                                                    "abc[i] set" ],
            [NOT, qr/DO_ARRAY_ELEM/,              "no DO_ARRAY_ELEM" ],
        ],
        [
            "T_ARRAY myiv output",
            Q(<<'EOF'),
                |myivArray *
                |foo()
EOF
            [  0, qr/myivArray\s*\*\s*RETVAL;/,   "RETVAL is myivArray*" ],
            [NOT, qr/myivArrayPtr/,               "myivArrayPtr NOT called" ],
            [  0, qr/\Qsv_setiv(ST(ix_RETVAL), (IV)RETVAL[ix_RETVAL]);/,
                                                    "ST(i) set" ],
            [NOT, qr/DO_ARRAY_ELEM/,              "no DO_ARRAY_ELEM" ],
        ],

        [
            "T_ARRAY blah input",
            Q(<<'EOF'),
                |char *
                |foo(blahArray * abc)
EOF
            [  0, qr/blahArray\s*\*\s*abc;/,      "abc is blahArray*" ],
            [  0, qr/abc\s*=\s*blahArrayPtr\(/,   "blahArrayPtr called" ],
            [  0, qr/abc\[ix_abc.*\]\s*=\s*.*\Qmy_get_blah(ST(ix_abc))/,
                                                    "abc[i] set" ],
            [NOT, qr/DO_ARRAY_ELEM/,              "no DO_ARRAY_ELEM" ],
        ],
        [
            "T_ARRAY blah output",
            Q(<<'EOF'),
                |blahArray *
                |foo()
EOF
            [  0, qr/blahArray\s*\*\s+RETVAL;/,   "RETVAL is blahArray*" ],
            [NOT, qr/blahArrayPtr/,               "blahArrayPtr NOT called" ],
            [  0, qr/\Qmy_set_blah(ST(ix_RETVAL), RETVAL[ix_RETVAL]);/,
                                                    "ST(i) set" ],
            [NOT, qr/DO_ARRAY_ELEM/,              "no DO_ARRAY_ELEM" ],
        ],

        [
            "T_ARRAY nosuchtype input",
            Q(<<'EOF'),
                |char *
                |foo(nosuchtypeArray * abc)
EOF
            [ERR, qr/Could not find a typemap for C type 'nosuchtype'/,
                                                    "no such type" ],
        ],
        [
            "T_ARRAY nosuchtype output",
            Q(<<'EOF'),
                |nosuchtypeArray *
                |foo()
EOF
            [ERR, qr/Could not find a typemap for C type 'nosuchtype'/,
                                                    "no such type" ],
        ],

        # test DO_ARRAY_ELEM in a typemap other than T_ARRAY.
        #
        # XXX It's not clear whether DO_ARRAY_ELEM should be processed
        # in typemap definitions generally, rather than just in the
        # T_ARRAY definition. Currently it is, but DO_ARRAY_ELEM isn't
        # documented, and was clearly put into place as a hack to make
        # T_ARRAY work. So these tests represent the *current*
        # behaviour, but don't necessarily endorse that behaviour. These
        # tests ensure that any change in behaviour is deliberate rather
        # than accidental.
        [
            "T_DAE input",
            Q(<<'EOF'),
                |char *
                |foo(shortArray * abc)
EOF
            [  0, qr/shortArray\s*\*\s*abc;/,      "abc is shortArray*" ],
            # calling fooArrayPtr() is part of the T_ARRAY typemap,
            # not part of the general mechanism
            [NOT, qr/shortArrayPtr\(/,             "no shortArrayPtr call" ],
            [  0, qr/\{\s*abc\[ix_abc.*\]\s*=\s*.*\QSvIV(ST(ix_abc))\E\s*\n?\s*\}/,
                                                    "abc[i] set" ],
            [  0, qr/\QIN(abc,shortArray *,shortArrayPtr,short,ST(0),0)/,
                                                    "template vars ok" ],
            [NOT, qr/DO_ARRAY_ELEM/,              "no DO_ARRAY_ELEM" ],
        ],
        [
            "T_DAE output",
            Q(<<'EOF'),
                |shortArray *
                |foo()
EOF
            [  0, qr/shortArray\s*\*\s*RETVAL;/,  "RETVAL is shortArray*" ],
            [NOT, qr/shortArrayPtr\(/,            "shortArrayPtr NOT called" ],
            [  0, qr/\Qsv_setiv(ST(ix_RETVAL), (IV)RETVAL[ix_RETVAL]);/,
                                                    "ST(i) set" ],
            [  0, qr/\QOUT(RETVAL,shortArray *,shortArrayPtr,short,ST(0))/,
                                                    "template vars ok" ],
            [NOT, qr/DO_ARRAY_ELEM/,              "no DO_ARRAY_ELEM" ],
        ],
        [
            "T_DAE bad input",
            Q(<<'EOF'),
                |int
                |foo(NoInputArray * abc)
EOF
            [ERR, qr/\QError: no INPUT definition for subtype 'NoInput', typekind 'T_Noinput' found in\E.*line 40/,
                                                    "got expected error" ],
        ],

        # Use overridden return code with an OUTPUT line.
        [
            "T_ARRAY override output",
            Q(<<'EOF'),
                |intArray *
                |foo()
                |    OUTPUT:
                |      RETVAL my_intptr_set(ST(0), RETVAL[0]);
EOF
            [  0, qr/intArray\s*\*\s*RETVAL;/,   "RETVAL is intArray*" ],
            [NOT, qr/intArrayPtr/,               "intArrayPtr NOT called" ],
            [  0, qr/\Qmy_intptr_set(ST(0), RETVAL[0]);/, "ST(0) set" ],
            [NOT, qr/DO_ARRAY_ELEM/,              "no DO_ARRAY_ELEM" ],
        ],

        # for OUT and OUTLIST arguments, don't process DO_ARRAY_ELEM
        [
            "T_ARRAY OUT",
            Q(<<'EOF'),
                |int
                |foo(OUT intArray * abc)
EOF
            [ERR, qr/Error: can't use typemap containing DO_ARRAY_ELEM for OUT parameter/,
                    "gives err" ],
        ],
        [
            "T_ARRAY OUT",
            Q(<<'EOF'),
                |int
                |foo(OUTLIST intArray * abc)
EOF
            [ERR, qr/Error: can't use typemap containing DO_ARRAY_ELEM for OUTLIST parameter/,
                    "gives err" ],
        ],

        [
            "T_ARRAY no output typemap entry",
            Q(<<'EOF'),
                |NooutputArray *
                |foo()
EOF
            [ERR, qr/\QError: no OUTPUT definition for subtype 'Nooutput', typekind 'T_Nooutput'\E.*line 40/,
                    "gives expected error" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


done_testing;

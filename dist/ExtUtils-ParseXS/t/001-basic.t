#!/usr/bin/perl

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
    # Basic test of using a string ref as the input file

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "using string ref as input file",
            Q(<<'EOF'),
                |void f(int a)
                |    CODE:
                |        mycode;
EOF
            # We should have got some content, and the generated '#line' lines
            # should be sensible rather than '#line 1 SCALAR(0x...)'.
            [  0, qr/XS_Foo_f/,               "fn name"      ],
            [  0, qr/#line \d+ "\(input\)"/,  "input #line"  ],
            [  0, qr/#line \d+ "\(output\)"/, "output #line" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


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
    # Test for C++ XSUB support: in particular,
    # - an XSUB function including a class in its name implies C++
    # - implicit CLASS/THIS first arg
    # - new and DESTROY methods handled specially
    # - 'static' return type implies class method
    # - 'const' can follow signature
    #

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |TYPEMAP: <<EOF
        |X::Y *        T_OBJECT
        |const X::Y *  T_OBJECT
        |
        |INPUT
        |T_OBJECT
        |    $var = my_in($arg);
        |
        |OUTPUT
        |T_OBJECT
        |    my_out($arg, $var)
        |EOF
        |
EOF

    my @test_fns = (
        # [
        #     "common prefix for test descriptions",
        #     [ ... lines to be ...
        #       ... used as ...
        #       ... XSUB body...
        #     ],
        #     [ check_stderr, expect_nomatch, qr/expected/, "test description"],
        #     [ ... and more tests ..]
        #     ....
        # ]

        [
            # test something that isn't actually C++
            "C++: plain new",
            Q(<<'EOF'),
                |X::Y*
                |new(int aaa)
EOF
            [  0, qr/usage\(cv,\s+"aaa"\)/,                "usage"    ],
            [  0, qr/\Qnew(aaa)/,                          "autocall" ],
        ],

        [
            # test something static that isn't actually C++
            "C++: plain static new",
            Q(<<'EOF'),
                |static X::Y*
                |new(int aaa)
EOF
            [  0, qr/usage\(cv,\s+"aaa"\)/,                "usage"    ],
            [  0, qr/\Qnew(aaa)/,                          "autocall" ],
            [ERR, qr/Warning: ignoring 'static' type modifier:/, "warning" ],
        ],

        [
            # test something static that isn't actually C++ nor new
            "C++: plain static foo",
            Q(<<'EOF'),
                |static X::Y*
                |foo(int aaa)
EOF
            [  0, qr/usage\(cv,\s+"aaa"\)/,                "usage"    ],
            [  0, qr/\Qfoo(aaa)/,                          "autocall" ],
            [ERR, qr/Warning: ignoring 'static' type modifier:/, "warning" ],
        ],

        [
            "C++: new",
            Q(<<'EOF'),
                |X::Y*
                |X::Y::new(int aaa)
EOF
            [  0, qr/usage\(cv,\s+"CLASS, aaa"\)/,         "usage"    ],
            [  0, qr/char\s*\*\s*CLASS = \Q(char *)SvPV_nolen(ST(0))\E/,
                                                           "var decl" ],
            [  0, qr/\Qnew X::Y(aaa)/,                     "autocall" ],
        ],

        [
            "C++: static new",
            Q(<<'EOF'),
                |static X::Y*
                |X::Y::new(int aaa)
EOF
            [  0, qr/usage\(cv,\s+"CLASS, aaa"\)/,         "usage"    ],
            [  0, qr/char\s*\*\s*CLASS\b/,                 "var decl" ],
            [  0, qr/\QX::Y(aaa)/,                         "autocall" ],
        ],

        [
            "C++: fff",
            Q(<<'EOF'),
                |void
                |X::Y::fff(int bbb)
EOF
            [  0, qr/usage\(cv,\s+"THIS, bbb"\)/,          "usage"    ],
            [  0, qr/X__Y\s*\*\s*THIS\s*=\s*my_in/,        "var decl" ],
            [  0, qr/\QTHIS->fff(bbb)/,                    "autocall" ],
        ],

        [
            "C++: ggg",
            Q(<<'EOF'),
                |static int
                |X::Y::ggg(int ccc)
EOF
            [  0, qr/usage\(cv,\s+"CLASS, ccc"\)/,         "usage"    ],
            [  0, qr/char\s*\*\s*CLASS\b/,                 "var decl" ],
            [  0, qr/\QX::Y::ggg(ccc)/,                    "autocall" ],
        ],

        [
            "C++: hhh",
            Q(<<'EOF'),
                |int
                |X::Y::hhh(int ddd) const
EOF
            [  0, qr/usage\(cv,\s+"THIS, ddd"\)/,          "usage"    ],
            [  0, qr/const X__Y\s*\*\s*THIS\s*=\s*my_in/,  "var decl" ],
            [  0, qr/\QTHIS->hhh(ddd)/,                    "autocall" ],
        ],

        [
            "C++: only const",
            Q(<<'EOF'),
                |void
                |foo() const
EOF
            [ERR, qr/\QError: const modifier only allowed on XSUBs which are C++ methods/,
                "got expected err" ],
        ],

        # autocall variants with const

        [
            "C++: static const",
            Q(<<'EOF'),
                |static int
                |X::Y::foo() const
EOF
            [  0, qr/\QRETVAL = X::Y::foo()/,
                "autocall doesn't have const" ],
        ],

        [
            "C++: static new const",
            Q(<<'EOF'),
                |static int
                |X::Y::new() const
EOF
            [  0, qr/\QRETVAL = X::Y()/,
                "autocall doesn't have const" ],
        ],

        [
            "C++: const",
            Q(<<'EOF'),
                |int
                |X::Y::foo() const
EOF
            [  0, qr/\QRETVAL = THIS->foo()/,
                "autocall doesn't have const" ],
        ],

        [
            "C++: new const",
            Q(<<'EOF'),
                |int
                |X::Y::new() const
EOF
            [  0, qr/\QRETVAL = new X::Y()/,
                "autocall doesn't have const" ],
        ],

        [
            "",
            Q(<<'EOF'),
                |int
                |X::Y::f1(THIS, int i)
EOF
            [ERR, qr/\QError: duplicate definition of parameter 'THIS' /,
                 "C++: f1 dup THIS" ],
        ],

        [
            "",
            Q(<<'EOF'),
                |int
                |X::Y::f2(int THIS, int i)
EOF
            [ERR, qr/\QError: duplicate definition of parameter 'THIS' /,
                 "C++: f2 dup THIS" ],
        ],

        [
            "",
            Q(<<'EOF'),
                |int
                |X::Y::new(int CLASS, int i)
EOF
            [ERR, qr/\QError: duplicate definition of parameter 'CLASS' /,
                 "C++: new dup CLASS" ],
        ],

        [
            "C++: f3",
            Q(<<'EOF'),
                |int
                |X::Y::f3(int i)
                |    OUTPUT:
                |        THIS
EOF
            [  0, qr/usage\(cv,\s+"THIS, i"\)/,            "usage"    ],
            [  0, qr/X__Y\s*\*\s*THIS\s*=\s*my_in/,        "var decl" ],
            [  0, qr/\QTHIS->f3(i)/,                       "autocall" ],
            [  0, qr/^\s*\Qmy_out(ST(0), THIS)/m,          "set st0"  ],
        ],

        [
            # allow THIS's type to be overridden ...
            "C++: f4: override THIS type",
            Q(<<'EOF'),
                |int
                |X::Y::f4(int i)
                |    int THIS
EOF
            [  0, qr/usage\(cv,\s+"THIS, i"\)/,       "usage"    ],
            [  0, qr/int\s*THIS\s*=\s*\(int\)/,       "var decl" ],
            [NOT, qr/X__Y\s*\*\s*THIS/,               "no class var decl" ],
            [  0, qr/\QTHIS->f4(i)/,                  "autocall" ],
        ],

        [
            #  ... but not multiple times
            "C++: f5: dup override THIS type",
            Q(<<'EOF'),
                |int
                |X::Y::f5(int i)
                |    int THIS
                |    long THIS
EOF
            [ERR, qr/\QError: duplicate definition of parameter 'THIS'/,
                    "dup err" ],
        ],

        [
            #  don't allow THIS in sig, with type
            "C++: f6: sig THIS type",
            Q(<<'EOF'),
                |int
                |X::Y::f6(int THIS)
EOF
            [ERR, qr/\QError: duplicate definition of parameter 'THIS'/,
                    "dup err" ],
        ],

        [
            #  don't allow THIS in sig, without type
            "C++: f7: sig THIS no type",
            Q(<<'EOF'),
                |int
                |X::Y::f7(THIS)
EOF
            [ERR, qr/\QError: duplicate definition of parameter 'THIS'/,
                    "dup err" ],
        ],

        [
            # allow CLASS's type to be overridden ...
            "C++: new: override CLASS type",
            Q(<<'EOF'),
                |int
                |X::Y::new(int i)
                |    int CLASS
EOF
            [  0, qr/usage\(cv,\s+"CLASS, i"\)/,      "usage"    ],
            [  0, qr/int\s*CLASS\s*=\s*\(int\)/,      "var decl" ],
            [NOT, qr/char\s*\*\s*CLASS/,              "no char* var decl" ],
            [  0, qr/\Qnew X::Y(i)/,                  "autocall" ],
        ],

        [
            #  ... but not multiple times
            "C++: new dup override CLASS type",
            Q(<<'EOF'),
                |int
                |X::Y::new(int i)
                |    int CLASS
                |    long CLASS
EOF
            [ERR, qr/\QError: duplicate definition of parameter 'CLASS'/,
                    "dup err" ],
        ],

        [
            #  don't allow CLASS in sig, with type
            "C++: new sig CLASS type",
            Q(<<'EOF'),
                |int
                |X::Y::new(int CLASS)
EOF
            [ERR, qr/\QError: duplicate definition of parameter 'CLASS'/,
                    "dup err" ],
        ],

        [
            #  don't allow CLASS in sig, without type
            "C++: new sig CLASS no type",
            Q(<<'EOF'),
                |int
                |X::Y::new(CLASS)
EOF
            [ERR, qr/\QError: duplicate definition of parameter 'CLASS'/,
                    "dup err" ],
        ],

        [
            "C++: DESTROY",
            Q(<<'EOF'),
                |void
                |X::Y::DESTROY()
EOF
            [  0, qr/usage\(cv,\s+"THIS"\)/,               "usage"    ],
            [  0, qr/X__Y\s*\*\s*THIS\s*=\s*my_in/,        "var decl" ],
            [  0, qr/delete\s+THIS;/,                      "autocall" ],
        ]
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


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
            [ TODO, qr/if\(items < 2\)\n\s*abc = 111;\n\s*else \{\n\s*abc = `777;\n\}\n/,
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
            [ TODO, qr/if\(items >= 1\)\n\s*abc = 777;\n\s*}/,
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
    # Test OVERLOAD keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

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
            "OVERLOAD dup op",
            Q(<<'EOF'),
                |void
                |foo()
                |    OVERLOAD:   cmp cmp
EOF
            [ERR, qr{\QWarning: duplicate OVERLOAD op name: 'cmp'},
                "got expected error"   ],
        ],

    );

    test_many($preamble, 'boot_Foo', \@test_fns);
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
                [ERR, qr{Warning: text after keyword ignored: 'blah'},
                        "should die" ],
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
            [ERR, qr{Warning: text after keyword ignored: 'blah'},
                    "should die" ],
        ],
    );

    test_many($preamble, undef, \@test_fns);
}




done_testing;

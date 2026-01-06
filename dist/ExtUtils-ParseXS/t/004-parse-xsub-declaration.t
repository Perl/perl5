#!/usr/bin/perl
#
# 004-parse-xsub-declaration.t
#
# Test the parsing of an XSUB declaration.
#
# This test file essentially covers the first two lines of an XSUB. But
# note that there are separate test files for the detailed testing of
# individual parameter and return type syntax and semantics.
#
# The tests in this file are more concerned with the processing of the
# signature as a whole: e.g. the splitting into individual parameters but
# not the subsequent processing of them; default values and arg count
# checking; generating a usage string; generating the args to pass to an
# autocall; generating the prototype string for the XSUB.
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
    # Test XSUB declarations.
    # Generates errors which don't result in an XSUB being emitted,
    # so use 'undef' in the test_many() call to not strip down output

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
EOF

    my @test_fns = (
        [
            "extern C",
            Q(<<'EOF'),
                |extern "C"   int
                |foo()
EOF
            [  0, qr/^extern "C"\nXS_EUPXS\(XS_Foo_foo\);/m,
                    "has extern decl" ],
        ],
        [
            "defn too short",
            Q(<<'EOF'),
                |int
EOF
            [ERR, qr{
                \QError: unrecognised line: 'int' in (input), line 5\E\n
                \Q  (possible start of a truncated XSUB definition?)\E\n
                }x,
            "got err" ],
        ],
        [
            "defn not parseable 1",
            Q(<<'EOF'),
                |int
                |foo(aaa
                |    CODE:
                |        AAA
EOF
            [ERR, qr/\QError: cannot parse function definition from 'foo(aaa' in\E.*line 6/,
                    "got err" ],
        ],
        [
            "defn not parseable 2",
            Q(<<'EOF'),
                |int
                |fo o(aaa)
EOF
            [ERR, qr/\QError: cannot parse function definition from 'fo o(aaa)' in\E.*line 6/,
                    "got err" ],
        ],

        # note that  issuing this warning is somewhat controversial:
        # see GH 19661. But while we continue to warn, test that we get a
        # warning.
        [
            "dup fn warning",
            Q(<<'EOF'),
                |int
                |foo(aaa)
                |
                |int
                |foo(aaa)
EOF
            [ERR, qr/\QWarning: duplicate function definition 'foo' detected in\E.*line 9/,
                    "got warn" ],
        ],
        [
            "dup fn warning",
            Q(<<'EOF'),
                |#if X
                |int
                |foo(aaa)
                |
                |#else
                |int
                |foo(aaa)
                |#endif
EOF
            [ERR|NOT, qr/\QWarning: duplicate function definition/,
                    "no warning" ],
        ],

        [
            "unparseable params",
            Q(<<'EOF'),
                |int foo(char *s = "abc\",)")
EOF
            [ERR, qr/\QWarning: cannot parse parameter list/,
                    "got warning" ],
        ],
    );

    test_many($preamble, undef, \@test_fns);
}


{
    # check that suitable "usage: " error strings are generated
    #
    # Note that some distros include a test of their usage strings which
    # are sensitive to variations in white space, so these tests confirm
    # that the exact white space is preserved, especially with regards to
    # space (or not) around the '=' of a default value.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
EOF

    my @test_fns = (
        [
            "general usage msg",
            Q(<<'EOF'),
                |void
                |foo(a, char *b,  int length(b), int d =  999, ...)
                |    long a
EOF
            [  0, qr/usage\(cv,\s+"a, b, d=  999, ..."\)/,     ""    ],
        ],

        # check that type and IN/OUT class etc are stripped out.
        [
            "more usage msg",
            Q(<<'EOF'),
            |int
            |foo(  a   ,  char   * b  , OUT  int  c  ,  OUTLIST int  d   ,    \
            |      IN_OUT char * * e    =   1  + 2 ,   long length(b)   ,    \
            |      char* f="abc"  ,     g  =   0  ,   ...     )
EOF
            [  0, qr{usage\(cv,\s+\Q"a, b, c, e=   1  + 2, f=\E\\"abc\\"\Q, g  =   0, ...")},
                "" ],
        ]
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # check that args to an auto-called C function are correct

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
EOF

    my @test_fns = (
        [
            "autocall args normal",
            Q(<<'EOF'),
                |void
                |foo( OUT int  a,   b   , char   *  c , int length(c), OUTLIST int d, IN_OUTLIST int e)
                |    long &b
                |    int alien
EOF
            [  0, qr/\Qfoo(&a, &b, c, XSauto_length_of_c, &d, &e)/,  ""  ],
        ],
        [
            "autocall args normal",
            Q(<<'EOF'),
                |void
                |foo( OUT int  a,   b   , char   *  c , size_t length(c) )
                |    long &b
                |    int alien
EOF
            [  0, qr/\Qfoo(&a, &b, c, XSauto_length_of_c)/,     ""    ],
        ],

        [
            "autocall args C_ARGS",
            Q(<<'EOF'),
                |void
                |foo( int  a,   b   , char   *  c  )
                |    C_ARGS:     a,   b   , bar,  c? c : "boo!"    
                |    INPUT:
                |        long &b
EOF
            [  0, qr/\Qfoo(a,   b   , bar,  c? c : "boo!")/,     ""    ],
        ],

        [
            "autocall args empty C_ARGS",
            Q(<<'EOF'),
                |void
                |foo(int  a)
                |    C_ARGS:
EOF
            [  0, qr/\Qfoo()/,  "" ],
        ],

        [
            # Whether this is sensible or not is another matter.
            # For now, just check that it works as-is.
            "autocall args C_ARGS multi-line",
            Q(<<'EOF'),
                |void
                |foo( int  a,   b   , char   *  c  )
                |    C_ARGS: a,
                |        b   , bar,
                |        c? c : "boo!"
                |    INPUT:
                |        long &b
EOF
            [  0, qr/\(a,\n        b   , bar,\n\Q        c? c : "boo!")/,
              ""  ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test prototypes

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: ENABLE
        |
        |TYPEMAP: <<EOF
        |X::Y *        T_OBJECT
        |const X::Y *  T_OBJECT \&
        |
        |P::Q *        T_OBJECT @
        |const P::Q *  T_OBJECT %
        |
        |foo_t         T_IV @
        |bar_t         T_IV %
        |
        |INPUT
        |T_OBJECT
        |    $var = my_in($arg);
        |
        |OUTPUT
        |T_OBJECT
        |    my_out($arg, $var)
        |EOF
EOF

    my @test_fns = (
        [
            "auto-generated proto basic",
            Q(<<'EOF'),
                |void
                |foo(int a, int b, int c)
EOF
            [  0, qr/"\$\$\$"/, "" ],
        ],

        [
            "auto-generated proto basic with default",
            Q(<<'EOF'),
                |void
                |foo(int a, int b, int c = 0)
EOF
            [  0, qr/"\$\$;\$"/, "" ],
        ],

        [
            "auto-generated proto complex",
            Q(<<'EOF'),
                |void
                |foo(char *A, int length(A), int B, OUTLIST int C, int D)
EOF
            [  0, qr/"\$\$\$"/, "" ],
        ],

        [
            "auto-generated proto  complex with default",
            Q(<<'EOF'),
                |void
                |foo(char *A, int length(A), int B, IN_OUTLIST int C, int D = 0)
EOF
            [  0, qr/"\$\$\$;\$"/, "" ],
        ],

        [
            "auto-generated proto with ellipsis",
            Q(<<'EOF'),
                |void
                |foo(char *A, int length(A), int B, OUT int C, int D, ...)
EOF
            [  0, qr/"\$\$\$\$;\@"/, "" ],
        ],

        [
            "auto-generated proto with default and ellipsis",
            Q(<<'EOF'),
                |void
                |foo(char *A, int length(A), int B, IN_OUT int C, int D = 0, ...)
EOF
            [  0, qr/"\$\$\$;\$\@"/, "" ],
        ],

        [
            "auto-generated proto with default and ellipsis and THIS",
            Q(<<'EOF'),
                |void
                |X::Y::foo(char *A, int length(A), int B, IN_OUT int C, int D = 0, ...)
EOF
            [  0, qr/"\$\$\$\$;\$\@"/, "" ],
        ],

        [
            "auto-generated proto with overridden THIS type",
            Q(<<'EOF'),
                |void
                |P::Q::foo()
                |    const P::Q * THIS
EOF
            [  0, qr/"%"/, "" ],
        ],

        [
            "explicit prototype",
            Q(<<'EOF'),
                |void
                |foo(int a, int b, int c = 0)
                |    PROTOTYPE: $@%;$
EOF
            [  0, qr/"\$\@%;\$"/, "" ],
        ],

        [
            "explicit prototype with whitespace",
            Q(<<'EOF'),
                |void
                |foo(int a, int b, int c)
                |    PROTOTYPE:     $   $    @   
EOF
            [  0, qr/"\$\$\@"/, "" ],
        ],

        [
            "explicit prototype with backslash etc",
            Q(<<'EOF'),
                |void
                |foo(int a, int b, int c = 0)
                |    PROTOTYPE: \$\[@%]
EOF
            # Note that the emitted C code will have escaped backslashes,
            # so the actual C code looks something like:
            #    newXS_some_variant(..., "\\$\\[@%]");
            # and so the regex below has to escape each backslash and
            # meta char its trying to match:
            [  0, qr/" \\  \\  \$  \\  \\ \[  \@  \%  \] "/x, "" ],
        ],

        [
            # XXX The parsing code for the PROTOTYPE keyword treats the
            # keyword as multi-line and uses the last seen value.
            # Almost certainly a coding error, but preserve the behaviour
            # for now.
            "explicit multiline prototype",
            Q(<<'EOF'),
                |void
                |foo(int a, int b, int c)
                |    PROTOTYPE:
                |           
                |       DISABLE
                |
                |       %%%%%%
                |
                |       $$@
                |
                |    C_ARGS: x,y,z
EOF
            [  0, qr/"\$\$\@"/, "" ],
        ],


        [
            "explicit empty prototype",
            Q(<<'EOF'),
                |void
                |foo(int a, int b, int c = 0)
                |    PROTOTYPE:
EOF
            [  0, qr/newXS.*, ""/, "" ],
        ],

        [
            "explicit ENABLE prototype",
            Q(<<'EOF'),
                |void
                |foo(int a, int b, int c)
                |    PROTOTYPE: ENABLE
EOF
            [  0, qr/"\$\$\$"/, "" ],
        ],

        [
            "explicit DISABLE prototype",
            Q(<<'EOF'),
                |void
                |foo(int a, int b, int c)
                |    PROTOTYPE: DISABLE
EOF
            [NOT, qr/"\$\$\$"/, "" ],
        ],

        [
            "multiple prototype",
            Q(<<'EOF'),
                |void
                |foo(int a, int b, int c)
                |    PROTOTYPE: $$$
                |    PROTOTYPE: $$$
EOF
            [ERR, qr/Error: only one PROTOTYPE definition allowed per xsub/, "" ],
        ],

        [
            "explicit invalid prototype",
            Q(<<'EOF'),
                |void
                |foo(int a, int b, int c)
                |    PROTOTYPE: ab
EOF
            [ERR, qr/Error: invalid prototype 'ab'/, "" ],
        ],

        [
            "not overridden by typemap",
            Q(<<'EOF'),
                |void
                |foo(X::Y * a, int b, int c = 0)
EOF
            [  0, qr/"\$\$;\$"/, "" ],
        ],

        [
            "overridden by typemap",
            Q(<<'EOF'),
                |void
                |foo(const X::Y * a, int b, int c = 0)
EOF
            [  0, qr/" \\ \\ \& \$ ; \$ "/x, "" ],
        ],

        [
            # shady but legal - placeholder
            "auto-generated proto with no type",
            Q(<<'EOF'),
                |void
                |foo(a, b, c = 0)
EOF
            [  0, qr/"\$\$;\$"/, ""  ],
        ],

        [
            "auto-generated proto with backcompat SV* placeholder",
            Q(<<'EOF'),
                |void
                |foo(int a, SV*, char *c = "")
                |C_ARGS: a, c
EOF
            [  0, qr/"\$\$;\$"/, ""  ],
        ],
        [
            "CASE with variant prototype char",
            Q(<<'EOF'),
                |void
                |foo(abc)
                |    CASE: X
                |       foo_t abc
                |    CASE: Y
                |       int   abc
                |    CASE: Z
                |       bar_t abc
EOF
            [  0, qr/newXS.*"%"/, "has %" ],
            [ERR, qr/Warning: prototype for 'abc' varies: '\@' versus '\$' .*line 28/,
                    "got 'varies' warning 1" ],
            [ERR, qr/Warning: prototype for 'abc' varies: '\$' versus '%' .*line 30/,
                    "got 'varies' warning 2" ],
        ],
    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}


{
    # Basic tests of XSUB signature error processing

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "bad sig under -nofoo flags",
            Q(<<'EOF'),
                |void
                |foo(+++)
EOF
            [ERR, qr{\QError: unparseable XSUB parameter: '+++},
                    "unparseable" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Basic tests of XSUB signature error processing
    # under -noargtypes, -noinout

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "bad sig under -nofoo flags",
            Q(<<'EOF'),
                |void
                |foo(char* a, int length(a), IN c, +++)
EOF
            [ERR, qr{\QError: parameter type not allowed under -noargtypes},
                    "-noargtypes" ],
            [ERR, qr{\QError: length() pseudo-parameter not allowed under -noargtypes},
                    "-noargtypes length" ],
            [ERR, qr{\QError: parameter IN/OUT modifier not allowed under -noinout},
                    "-noinout" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns, [ argtypes => 0, inout => 0 ]);
}


{
    # Test default parameter values and ellipses

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (

        # Basic int default
        [
            "default i = 0",
            Q(<<'EOF'),
                |void
                |foo(int i = 0)
EOF
            [  0, qr/^\s+int\s+i;$/m,        "i delcared" ],

            [  0, qr{\s+\Qif (items < 1)\E\n
                       \s+\Qi = 0;\E\n
                       \s+\Qelse {\E\n
                       \s+\Qi = (int)SvIV(ST(0))\E\n
                       \s*;\n
                       \s+}\n
                       }x,
                    "init" ],
        ],

        # Basic char default
        [
            "default c = 'x'",
            Q(<<'EOF'),
                |void
                |foo(unsigned char c = 'x')
EOF
            [  0, qr/^\s+unsigned char\s+c;$/m,        "c delcared" ],

            [  0, qr{\s+\Qif (items < 1)\E\n
                       \s+\Qc = 'x';\E\n
                       \s+\Qelse {\E\n
                       \s+\Qc = (unsigned char)SvUV(ST(0))\E\n
                       \s*;\n
                       \s+}\n
                       }x,
                    "init" ],
        ],

        # Basic string default
        [
            'default s = "abc"',
            Q(<<'EOF'),
                |void
                |foo(char *s = "abc")
EOF
            [  0, qr/^\s+char \*\s+s;$/m,        "s delcared" ],

            [  0, qr{\s+\Qif (items < 1)\E\n
                       \s+\Qs = "abc";\E\n
                       \s+\Qelse {\E\n
                       \s+\Qs = (char *)SvPV_nolen(ST(0))\E\n
                       \s*;\n
                       \s+}\n
                       }x,
                    "init" ],
        ],

        # mixed quote string default
        [
            'default s = "\'abc\'"',
            Q(<<'EOF'),
                |void
                |foo(char *s = "'abc'")
EOF
            [  0, qr/^\s+char \*\s+s;$/m,        "s delcared" ],

            [  0, qr{\s+\Qif (items < 1)\E\n
                       \s+\Qs = "'abc'";\E\n
                       \s+\Qelse {\E\n
                       \s+\Qs = (char *)SvPV_nolen(ST(0))\E\n
                       \s*;\n
                       \s+}\n
                       }x,
                    "init" ],
        ],

        # Check that default expressions are template-expanded. Whether
        # this is sensible or not, Dynaloader and other distributions rely
        # on it
        [
            'default expression expanded',
            Q(<<'EOF'),
                |void
                |foo(char *s = "$Package")
EOF
            [  0, qr/^\s+s\s+=\s+"Foo"/m,        "expanded" ],
        ],

        # foo =
        [
            'default missing value',
            Q(<<'EOF'),
                |void
                |foo(char *s = )
EOF
            [ERR, qr/Error: missing default value expression for 's'/m,
                    "got expected err" ],

        ],

        # Ellipses

        [
            "empty ellipsis",
            Q(<<'EOF'),
                |void
                |foo(...)
EOF
            [NOT, qr{if.*items}, "no checks" ],
        ],

        [
            "ellipsis with 1 arg",
            Q(<<'EOF'),
                |void
                |foo(int i, ...)
EOF
            [  0, qr{\s+\Qif (items < 1)\E\n
                       \s+\Qcroak_xs_usage(cv,  "i, ...");\E\n
                       }x,
                    "check" ],
        ],
        [
            "ellipsis with 1 arg, 1 default arg",
            Q(<<'EOF'),
                |void
                |foo(int i, int j = 0, ...)
EOF
            [  0, qr{\s+\Qif (items < 1)\E\n
                       \s+\Qcroak_xs_usage(cv,  "i, j= 0, ...");\E\n
                       }x,
                    "check" ],
            [  0, qr[\s+\Qif (items < 2)\E\n
                       \s+\Qj = 0;\E\n
                       \s+\Qelse {\E\n
                       \s+\Qj = (int)SvIV(ST(1))\E\n
                       ]x,
                    "init" ],
        ],
        [
            "ellipsis with an ellipsis in default arg value",
            Q(<<'EOF'),
                |void
                |foo(char *s = "...", int j = 0, ...)
EOF
            [NOT, qr{croak_xs_usage}, "no check" ],
            [  0, qr[\s+\Qif (items < 1)\E\n
                       \s+\Qs = "...";\E\n
                       \s+\Qelse {\E\n
                       \s+\Qs = (char *)SvPV_nolen(ST(0))\E\n
                       ]x,
                    "init s" ],
            [  0, qr[\s+\Qif (items < 2)\E\n
                       \s+\Qj = 0;\E\n
                       \s+\Qelse {\E\n
                       \s+\Qj = (int)SvIV(ST(1))\E\n
                       ]x,
                    "init j" ],
            [  0, qr{\Qfoo(s, j)}, "autocall args" ],
        ],
        [
            "stuff after an ellipsis",
            Q(<<'EOF'),
                |void
                |foo(..., int i)
EOF
            [ERR, qr{\QError: further XSUB parameter seen after ellipsis},
                    "saw error" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


done_testing;

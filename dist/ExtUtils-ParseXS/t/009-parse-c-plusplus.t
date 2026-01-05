#!/usr/bin/perl
#
# 009-parse-c-plusplus.t
#
# Test the parsing of the support for C++ classes in an XSUB.
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


done_testing;

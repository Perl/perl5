#!/usr/bin/perl
#
# 002-parse-file-scope.t:
#
# Test the parsing of XS file-scoped syntax, apart from keywords (which
# are tested in 003-parse-file-scope-keywords.t)
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
    # Test POD

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "POD at EOF doesn't warn",
            Q(<<'EOF'),
                |void foo()
                |
                |=pod
                |=cut
EOF

            [  0, qr{XS}, "no undef warning" ],
        ],
        [
            "line continuation directly after POD",
            Q(<<'EOF'),
                |=pod
                |=cut
                |void foo(int i, \
                |         int j)
EOF

            [  0, qr{XS}, "no errs" ],
        ],
    );

    test_many($preamble, undef, \@test_fns);
}

{
    # Test standard C file preamble
    # check that a few standard lines are present

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "C preamble",
            Q(<<'EOF'),
                |void foo()
EOF

            [  0, qr{#ifndef PERL_UNUSED_VAR}, "PERL_UNUSED_VAR" ],
            [  0, qr{#ifndef PERL_ARGS_ASSERT_CROAK_XS_USAGE},
                        "PERL_ARGS_ASSERT_CROAK_XS_USAGE" ],
            [  0, qr{#ifdef newXS_flags}, "newXS_flags" ],
        ],
    );

    test_many($preamble, undef, \@test_fns);
}

{
    # An XS file without a MODULE line should warn, but
    # still emit the C code in the C part of the file (the whole file
    # contents in this case).

    my $preamble = '';

    my @test_fns = (
        [
            "No MODULE line",
            Q(<<'EOF'),
                |foo
                |bar
EOF

            [  0, qr{#line 1 ".*"\nfoo\nbar\n#line 13 ".*"}, "all C present" ],
            [ERR, qr{Warning: no MODULE line found in XS file \(input\)\n},
                    "got expected MODULE warning"  ],
        ],
    );

    test_many($preamble, undef, \@test_fns);
}


{
    # Test C-preprocessor parsing

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "CPP basic",
            Q(<<'EOF'),
                |#ifdef USE_SHORT
                |
                |short foo()
                |
                |#elif USE_LONG
                |
                |long foo()
                |
                |#else
                |
                |int foo()
                |
                |#endif
EOF
            [  0, qr{
                        ^ \#ifdef\ USE_SHORT \n
                        ^ \#define\ XSubPPtmpAAAA\ 1 \n

                         .*

                        ^ \s* short \s+ RETVAL; \s* \n

                         .*

                        ^ \#elif\ USE_LONG \n
                        ^ \#define\ XSubPPtmpAAAB\ 1 \n

                         .*

                        ^ \s* long \s+ RETVAL; \s* \n

                         .*

                        ^ \#else \n
                        ^ \#define\ XSubPPtmpAAAC\ 1 \n

                         .*

                        ^ \s* int \s+ RETVAL; \s* \n

                         .*
                        ^ \#endif \n

                      }smx,
                "has corrrect XSubPPtmpAAAA etc definitions"
            ],

            [  0, qr{
                        ^ \#if\ XSubPPtmpAAAA \n
                        .* newXS .*
                        ^ \#endif \n
                        ^ \#if\ XSubPPtmpAAAB \n
                        .* newXS .*
                        ^ \#endif \n
                        ^ \#if\ XSubPPtmpAAAC \n
                        .* newXS .*
                        ^ \#endif \n

                      }smx,
                "has corrrect XSubPPtmpAAAA etc boot usage"
            ],
        ],

        [
            "CPP basic, tightly cuddled",
            Q(<<'EOF'),
                |#ifdef USE_SHORT
                |short foo()
                |#elif USE_LONG
                |long foo()
                |#else
                |int foo()
                |#endif
EOF
            [  0, qr{
                        ^ \#ifdef\ USE_SHORT \n
                        ^ \#define\ XSubPPtmpAAAA\ 1 \n

                         .*

                        ^ \s* short \s+ RETVAL; \s* \n

                         .*

                        ^ \#elif\ USE_LONG \n
                        ^ \#define\ XSubPPtmpAAAB\ 1 \n

                         .*

                        ^ \s* long \s+ RETVAL; \s* \n

                         .*

                        ^ \#else \n
                        ^ \#define\ XSubPPtmpAAAC\ 1 \n

                         .*

                        ^ \s* int \s+ RETVAL; \s* \n

                         .*
                        ^ \#endif \n

                      }smx,
                "has corrrect XSubPPtmpAAAA etc definitions"
            ],

            [  0, qr{
                        ^ \#if\ XSubPPtmpAAAA \n
                        .* newXS .*
                        ^ \#endif \n
                        ^ \#if\ XSubPPtmpAAAB \n
                        .* newXS .*
                        ^ \#endif \n
                        ^ \#if\ XSubPPtmpAAAC \n
                        .* newXS .*
                        ^ \#endif \n

                      }smx,
                "has corrrect XSubPPtmpAAAA etc boot usage"
            ],
        ],

        [
            "CPP two independent branches",
            Q(<<'EOF'),
                |#ifdef USE_SHORT
                |short foo()
                |#endif
                |#if USE_LONG
                |long foo()
                |#endif
EOF
            [  0, qr{
                        ^ \#ifdef\ USE_SHORT \n
                        ^ \#define\ XSubPPtmpAAAA\ 1 \n
                         .*
                        ^ \s* short \s+ RETVAL; \s* \n
                         .*
                        ^ \#endif \n
                        ^ \#if\ USE_LONG \n
                        ^ \#define\ XSubPPtmpAAAB\ 1 \n
                         .*
                        ^ \s* long \s+ RETVAL; \s* \n
                         .*
                        ^ \#endif \n
                      }smx,
                    "ifdefs in order"  ],
        ],

        [
            "CPP one branch, one main",
            Q(<<'EOF'),
                |#ifdef USE_SHORT
                |short foo()
                |#endif
                |long foo()
EOF
            [  0, qr{
                        ^ \#ifdef\ USE_SHORT \n
                        ^ \#define\ XSubPPtmpAAAA\ 1 \n
                         .*
                        ^ \s* short \s+ RETVAL; \s* \n
                         .*
                        ^ \#endif \n
                         .*
                        ^ \s* long \s+ RETVAL; \s* \n
                      }smx,
                    "ifdefs in order"  ],
        ],

        [
            "CPP two in one branch",
            Q(<<'EOF'),
                |#ifdef USE_SHORT
                |short foo()
                |
                |long foo()
                |#endif
EOF
            [ERR, qr{Warning: duplicate function definition},
                    "got expected warning"  ],
        ],

        [
            "CPP two in main",
            Q(<<'EOF'),
                |short foo()
                |
                |long foo()
EOF
            [ERR, qr{Warning: duplicate function definition},
                    "got expected warning"  ],
        ],

        [
            "CPP nested conditions",
            Q(<<'EOF'),
                |#ifdef C1
                |
                |short foo()
                |
                |#ifdef C2
                |
                |long foo()
                |
                |#endif
                |
                |int foo()
                |
                |#endif
EOF
            [ERR, qr{Warning: duplicate function definition},
                    "got expected warning"  ],
        ],

        [
            "CPP nested conditions, different fns",
            Q(<<'EOF'),
                |#ifdef C1
                |
                |short foo()
                |
                |#ifdef C2
                |
                |long bar()
                |
                |#endif
                |
                |int baz()
                |
                |#endif
EOF
            [  0, qr{
                        ^ \#ifdef\ C1 \n
                        ^ \#define\ XSubPPtmpAAAB\ 1 \n
                         .*
                        ^ \s* short \s+ RETVAL; \s* \n
                         .*
                        ^ \#ifdef\ C2 \n
                        ^ \#define\ XSubPPtmpAAAA\ 1 \n
                         .*
                        ^ \s* long \s+ RETVAL; \s* \n
                         .*
                        ^ \#endif \n
                         .*
                        ^ \s* int \s+ RETVAL; \s* \n
                         .*
                        ^ \#endif \n
                      }smx,
                    "ifdefs in order"  ],
        ],

        [
            "CPP with indentation",
            Q(<<'EOF'),
                |#ifdef C1
                |#  ifdef C2
                |long bar()
                |#  endif
                |#endif
EOF
            [  0, qr{
                        ^ \#ifdef\ C1 \n
                        ^ \#define\ XSubPPtmpAAAB\ 1 \n
                        ^ \s* \n
                        ^ \#\ \ ifdef\ C2 \n
                        ^ \#define\ XSubPPtmpAAAA\ 1 \n
                         .*
                        ^ \s* long \s+ RETVAL; \s* \n
                         .*
                        ^ \#\ \ endif \n
                        ^ \#endif \n
                      }smx,
                    "ifdefs in order"  ],
        ],

        [
            "CPP: trivial branch",
            Q(<<'EOF'),
                |#ifdef C1
                |#define BLAH1
                |#endif
EOF
            [NOT, qr{XSubPPtmpAAA}, "no guard"  ],
        ],

        [
            "CPP: guard and other CPP ordering",
            Q(<<'EOF'),
                |#ifdef C1
                |#define BLAH1
                |
                |short foo()
                |
                |#endif
EOF

            [  0, qr{
                        ^ \#ifdef\ C1 \n
                         .*
                        ^ \#define\ XSubPPtmpAAAA\ 1 \n
                         .*
                        ^ \#define\ BLAH1\n
                         .*
                        ^ \s* short \s+ RETVAL; \s* \n
                         .*
                        ^ \#endif \n
                      }smx,
                    "ifdefs in order"  ],
        ],

        [
            "CPP balanced else",
            Q(<<'EOF'),
                |#else
                |
                |short foo()
EOF
            [ERR, qr{Error: '#else' with no matching '#if'},
                    "got expected err"  ],
        ],

        [
            "CPP balanced if",
            Q(<<'EOF'),
                |#ifdef
                |
                |short foo()
EOF
            [ERR, qr{Error: Unterminated '#ifdef' from line 5 in .* line 7},
                    "got expected err"  ],
        ],

        [
            "indented file-scoped keyword",
            Q(<<'EOF'),
                |#define FOO 1
                |  BOOT:
EOF
            [ERR, qr{\QError: file-scoped keywords should not be indented\E
                       \Q in (input), line 5\E}x,
                    "got expected err"  ],
        ],
        [
            "stray CPP / indented XSUB",
            Q(<<'EOF'),
                |#define FOO
                |  int
EOF
            [ERR, qr{
                    \QError: file-scoped directives must not be indented\E
                    \Q in (input), line 5\E\n
                    \Q  (If this line is supposed to be part of an XSUB\E
                  }x,
                "got expected err"  ],
        ],


    );

    test_many($preamble, undef, \@test_fns);
}



done_testing;

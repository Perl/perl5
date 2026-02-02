#!/usr/bin/perl
#
# 001-parse-basic.t
#
# Test the parsing of an XSUB.
#
# This is the first 0xx file and doesn't really test much except that the
# testing framework itself seems to work.
#
# The tests in this file, and indeed in all 0xx-parse-foo.t files, only
# test parsing, and not compilation or execution of the C code. For the
# latter, see 3xx-run-foo.t files.
#

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


done_testing;

#!/usr/bin/perl -w
use strict;
use warnings;
use autodie::hints;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Copy qw(copy move cp mv);

use Test::More 'no_plan';

use constant NO_SUCH_FILE  => "this_file_had_better_not_exist";
use constant NO_SUCH_FILE2 => "this_file_had_better_not_exist_xyzzy";

use constant PERL510 => ( $] >= 5.010 );

use Hints_test qw(
    fail_on_empty fail_on_false fail_on_undef
);

use autodie qw(fail_on_empty fail_on_false fail_on_undef);

diag("Sub::Identify ", exists( $INC{'Sub/Identify.pm'} ) ? "is" : "is not",
     " loaded");

my $hints = "autodie::hints";

# Basic hinting tests

is( $hints->sub_fullname(\&copy), 'File::Copy::copy' , "Id: copy" );
is( $hints->sub_fullname(\&cp),   'File::Copy::copy' , "Id: cp"   );

is( $hints->sub_fullname(\&move), 'File::Copy::move' , "Id: move" );
is( $hints->sub_fullname(\&mv),   'File::Copy::move' , "Id: mv"   );

if (PERL510) {
    ok( $hints->get_hints_for(\&copy)->{scalar}->(0) ,
        "copy() hints should fail on 0 for scalars."
    );
}

# Scalar context test

eval {
    use autodie qw(copy);

    my $scalar_context = copy(NO_SUCH_FILE, NO_SUCH_FILE2);
};

isnt("$@", "", "Copying in scalar context should throw an error.");
isa_ok($@, "autodie::exception");

# List context test.

eval {
    use autodie qw(copy);

    my @list_context = copy(NO_SUCH_FILE, NO_SUCH_FILE2);
};

isnt("$@", "", "Copying in list context should throw an error.");
isa_ok($@, "autodie::exception");

# Tests on loaded funcs.

my %tests = (

    # Test code             # Exception expected?

    'fail_on_empty()'       => 1,
    'fail_on_empty(0)'      => 0,
    'fail_on_empty(undef)'  => 0,
    'fail_on_empty(1)'      => 0,

    'fail_on_false()'       => 1,
    'fail_on_false(0)'      => 1,
    'fail_on_false(undef)'  => 1,
    'fail_on_false(1)'      => 0,

    'fail_on_undef()'       => 1,
    'fail_on_undef(0)'      => 0,
    'fail_on_undef(undef)'  => 1,
    'fail_on_undef(1)'      => 0,

);

# On Perl 5.8, autodie doesn't correctly propagate into string evals.
# The following snippet forces the use of autodie inside the eval if
# we really really have to.  For 5.10+, we don't want to include this
# fix, because the tests will act as a canary if we screw up string
# eval propagation.

my $perl58_fix = (
    $] >= 5.010 ?
    "" :
    "use autodie qw(fail_on_empty fail_on_false fail_on_undef); "
);

while (my ($test, $exception_expected) = each %tests) {
    eval "
        $perl58_fix
        my \@array = $test;
    ";


    if ($exception_expected) {
        isnt("$@", "", $test);
    }
    else {
        is($@, "", $test);
    }
}

1;

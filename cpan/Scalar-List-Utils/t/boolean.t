#!./perl

use strict;
use warnings;

use Scalar::Util ();
use Test::More  (grep { /isbool/ } @Scalar::Util::EXPORT_FAIL)
    ? (skip_all => 'isbool is not supported on this perl')
    : (tests => 15);

Scalar::Util->import("isbool");

# basic constants
{
    ok(isbool(!!0), 'false is boolean');
    ok(isbool(!!1), 'true is boolean');

    ok(!isbool(0), '0 is not boolean');
    ok(!isbool(1), '1 is not boolean');
    ok(!isbool(""), '"" is not boolean');
}

# variables
{
    my $falsevar = !!0;
    my $truevar  = !!1;

    ok(isbool($falsevar), 'false var is boolean');
    ok(isbool($truevar),  'true var is boolean');

    my $str = "$truevar";
    my $num = $truevar + 0;

    ok(!isbool($str), 'stringified true is not boolean');
    ok(!isbool($num), 'numified true is not boolean');

    ok(isbool($truevar), 'true var remains boolean after stringification and numification');
}

# aggregate members
{
    my %hash = ( false => !!0, true => !!1 );

    ok(isbool($hash{false}), 'false HELEM is boolean');
    ok(isbool($hash{true}),  'true HELEM is boolean');

    # We won't test AELEM but it's likely to be the same
}

{
    my $var;
    package Foo { sub TIESCALAR { bless {}, shift } sub FETCH { $var } }

    tie my $tied, "Foo";

    $var = 1;
    ok(!isbool($tied), 'tied var should not yet be boolean');

    $var = !!1;
    ok(isbool($tied), 'tied var should now be boolean');

    my $copy = $tied;
    ok(isbool($copy), 'copy of tied var should also be boolean');
}

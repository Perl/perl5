#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = qw(../lib);
}

use strict;
use warnings;

BEGIN {
    # this is sucky because threads.pm has to be loaded before Test::Builder
    use Config;
    if ( $Config{usethreads} ) {
	require threads; threads->import;
	require Test::More; Test::More->import( tests => 14 );
    } else {
	require Test::More;
	Test::More->import( skip_all => "threads aren't enabled in your perl" )
    }
}

use Tie::RefHash;

tie my %hash, "Tie::RefHash";

my $r1 = {};
my $r2 = [];
my $v1 = "foo";

$hash{$r1} = "hash";
$hash{$r2} = "array";
$hash{$v1} = "string";

is( $hash{$v1}, "string", "fetch by string before clone ($v1)" );
is( $hash{$r1}, "hash", "fetch by ref before clone ($r1)" );
is( $hash{$r2}, "array", "fetch by ref before clone ($r2)" );

my $th = threads->create(sub {
    is( scalar keys %hash, 3, "key count is OK" );

    ok( exists $hash{$v1}, "string key exists ($v1)" );
    is( $hash{$v1}, "string", "fetch by string" );

    ok( exists $hash{$r1}, "ref key exists ($r1)" );
    is( $hash{$r1}, "hash", "fetch by ref" );

    ok( exists $hash{$r2}, "ref key exists ($r2)" );
    is( $hash{$r2}, "array", "fetch by ref" );

    is_deeply( [ sort keys %hash ], [ sort $r1, $r2, $v1 ], "keys are ok" );
});

$th->join;

is( $hash{$v1}, "string", "fetch by string after clone, orig thread ($v1)" );
is( $hash{$r1}, "hash", "fetch by ref after clone ($r1)" );
is( $hash{$r2}, "array", "fetch by ref after clone ($r2)" );

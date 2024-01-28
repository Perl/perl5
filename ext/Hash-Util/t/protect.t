use strict;
use warnings;
use Test::More;

use Hash::Util qw(protect_hash
                  protect_hash_recursive
                  protect_hashkeys);
{

    my %hash = ( foo => 1, baz => 2, bop => 3, ary => [] );
    protect_hash(%hash);
    my $type = "protected hash";

    ok(!eval { $hash{xxx} = 1 },        "assignment to unknown key in $type dies");
    ok(!eval { $hash{foo} = 1 },        "assignment to existing key in $type dies");
    ok( eval { my $y = $hash{yyy}; 1 }, "read from unknown key in $type does not die");
    ok( eval { my $y = $hash{baz}; 1 }, "read from existing key in $type does not die");
    ok(!eval { $hash{ary}= [ "other" ] }, "assignment to array in $type dies" );
    ok( eval { push @{$hash{ary}}, "test"; 1}, "pushing into array in $type does not die");
}
{

    my %hash = ( foo => 1, baz => 2, bop => 3, ary => [],
                 subhash => { sk => 1, sa => [ "x" ] } );
    protect_hash_recursive(%hash);
    my $type = "recursively protected hash";

    ok(!eval { $hash{xxx} = 1 },        "assignment to unknown key in $type dies");
    ok(!eval { $hash{foo} = 1 },        "assignment to existing key in $type dies");
    ok( eval { my $y = $hash{yyy}; 1 }, "read from unknown key in $type does not die");
    ok( eval { my $y = $hash{baz}; 1 }, "read from existing key in $type does not die");
    ok(!eval { $hash{ary}= [ "other" ]; 1 }, "assignment to array in $type dies" );
    ok(!eval { push @{$hash{ary}}, "test"; 1}, "pushing into array in $type does die");
    ok(!eval { push @{$hash{subhash}{sa}}, "test"; 1}, "pushing into sub array in $type does die");
    ok(!eval { $hash{subhash}{sk}++; 1}, "plus-plus of sub key in $type does die");
}

done_testing();


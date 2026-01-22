#!perl
# tests the numeric sv_num[lg][te]() APIs

use Test::More;
use XS::APItest;
use strict;

# +0 overloading with large numbers and using fallback
package MyBigNum {
    use overload
      "0+" => sub { $_[0][0] },
      fallback => 1;
}

my $nan = eval {
    no warnings "experimental";
    builtin::nan();
};

my @values =
    (
    [ ~0 ],
    [ ~0-1 ],
    [ -int(~0/2) ],
    [ 1.001 ],
    [ 1.002 ],
    [ bless([ ~0 ], "MyBigNum"), "bignum ~0" ],
    [ bless([ ~0 ], "MyBigNum"), "bignum ~0 #2" ],
    [ bless([ ~0-1 ], "MyBigNum"), "bignum ~0-1" ],
    [ undef(), "undef" ],
    defined $nan ? (  [ $nan, "NaN" ] ) : (),
   );

for my $x (@values) {
    for my $y (@values) {
        for my $func ( [ "le", sub { $_[0] <= $_[1] }, \&sv_numle ],
                       [ "lt", sub { $_[0] <  $_[1] }, \&sv_numlt ],
                       [ "ge", sub { $_[0] >= $_[1] }, \&sv_numge ],
                       [ "gt", sub { $_[0] >  $_[1] }, \&sv_numgt ]) {
            my ($op, $native, $api) = @$func;
            my $lname = $x->[1] // $x->[0];
            my $rname = $y->[1] // $y->[0];
            is($api->($x->[0], $x->[1]), $native->($x->[0], $x->[1]),
               "$lname $op $rname");
        }
    }
}

done_testing;

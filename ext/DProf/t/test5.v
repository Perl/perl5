# perl

use V;

dprofpp( '-T' );
$expected =
qq{main::foo1
   main::bar
      main::yeppers
main::foo2
   main::bar
      main::yeppers
};
report 1, sub { $expected eq $results };


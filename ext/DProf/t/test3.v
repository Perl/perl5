# perl

use V;

dprofpp( '-T' );
$e1 = $expected =
qq{main::bar
main::baz
   main::bar
   main::foo
};
report 1, sub { $expected eq $results };

dprofpp('-TF');
$e2 = $expected =
qq{main::bar
main::baz
   main::bar
   main::foo
};
report 2, sub { $expected eq $results };

dprofpp( '-t' );
$expected = $e1;
report 3, sub { 1 };

dprofpp('-tF');
$expected = $e2;
report 4, sub { $expected eq $results };

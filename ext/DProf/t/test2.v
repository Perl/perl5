# perl

use V;

dprofpp( '-T' );
$expected =
qq{main::bar
main::bar
main::baz
   main::bar
   main::bar
   main::bar
   main::foo
      main::bar
main::foo
   main::bar
};
report 1, sub { $expected eq $results };

dprofpp('-TF');
report 2, sub { $expected eq $results };

dprofpp( '-t' );
$expected =
qq{main::bar (2x)
main::baz
   main::bar (3x)
   main::foo
      main::bar
main::foo
   main::bar
};
report 3, sub { $expected eq $results };

dprofpp('-tF');
report 4, sub { $expected eq $results };

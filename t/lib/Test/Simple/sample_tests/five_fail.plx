require Test::Simple;

push @INC, 't', '.';
require Catch;
my($out, $err) = Catch::caught();

Test::Simple->import(tests => 5);

ok(0);
ok(0);
ok('');
ok(0);
ok(0);

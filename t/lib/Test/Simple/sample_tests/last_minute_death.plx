require Test::Simple;

push @INC, 't', '.';
require Catch;
my($out, $err) = Catch::caught();

Test::Simple->import(tests => 5);
close STDERR;

ok(1);
ok(1);
ok(1);
ok(1);
ok(1);

die "Almost there...";

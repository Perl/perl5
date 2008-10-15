require Test::Simple;
# $Id: /mirror/googlecode/test-more/t/lib/Test/Simple/sample_tests/success.plx 57943 2008-08-18T02:09:22.275428Z brooklyn.kid51  $

push @INC, 't/lib';
require Test::Simple::Catch;
my($out, $err) = Test::Simple::Catch::caught();

Test::Simple->import(tests => 5);

ok(1);
ok(5, 'yep');
ok(3, 'beer');
ok("wibble", "wibble");
ok(1);

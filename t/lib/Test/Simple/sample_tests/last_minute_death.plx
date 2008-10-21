require Test::Simple;
# $Id: /mirror/googlecode/test-more/t/lib/Test/Simple/sample_tests/last_minute_death.plx 57943 2008-08-18T02:09:22.275428Z brooklyn.kid51  $

push @INC, 't/lib';
require Test::Simple::Catch;
my($out, $err) = Test::Simple::Catch::caught();

Test::Simple->import(tests => 5);

require Dev::Null;
tie *STDERR, 'Dev::Null';

ok(1);
ok(1);
ok(1);
ok(1);
ok(1);

$! = 0;
die "This is a test";

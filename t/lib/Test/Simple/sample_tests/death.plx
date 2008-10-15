require Test::Simple;
# $Id: /mirror/googlecode/test-more/t/lib/Test/Simple/sample_tests/death.plx 57943 2008-08-18T02:09:22.275428Z brooklyn.kid51  $

push @INC, 't/lib';
require Test::Simple::Catch;
my($out, $err) = Test::Simple::Catch::caught();

require Dev::Null;

Test::Simple->import(tests => 5);
tie *STDERR, 'Dev::Null';

ok(1);
ok(1);
ok(1);
die "This is a test";

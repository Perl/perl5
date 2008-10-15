# ID 20020716.013, the exit code would become 0 if the test died
# $Id: /mirror/googlecode/test-more/t/lib/Test/Simple/sample_tests/pre_plan_death.plx 57943 2008-08-18T02:09:22.275428Z brooklyn.kid51  $
# before a plan.

require Test::Simple;

push @INC, 't/lib';
require Test::Simple::Catch;
my($out, $err) = Test::Simple::Catch::caught();

close STDERR;
die "Knife?";

Test::Simple->import(tests => 3);

ok(1);
ok(1);
ok(1);

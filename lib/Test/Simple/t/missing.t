# Can't use Test.pm, that's a 5.005 thing.
package My::Test;

print "1..2\n";

my $test_num = 1;
# Utility testing functions.
sub ok ($;$) {
    my($test, $name) = @_;
    print "not " unless $test;
    print "ok $test_num";
    print " - $name" if defined $name;
    print "\n";
    $test_num++;
}


package main;

require Test::Simple;

push @INC, 'lib/Test/Simple/';
require Catch;
my($out, $err) = Catch::caught();

Test::Simple->import(tests => 5);

ok(1, 'Foo');
ok(0, 'Bar');

END {
    My::Test::ok($$out eq <<OUT);
1..5
ok 1 - Foo
not ok 2 - Bar
OUT

    My::Test::ok($$err eq <<ERR);
#     Failed test ($0 at line 29)
# Looks like you planned 5 tests but only ran 2.
ERR

    exit 0;
}

# Can't use Test.pm, that's a 5.005 thing.
package My::Test;

# This feature requires a fairly new version of Test::Harness
BEGIN {
    require Test::Harness;
    if( $Test::Harness::VERSION < 1.20 ) {
        print "1..0\n";
        exit(0);
    }
}

print "1..2\n";

my $test_num = 1;
# Utility testing functions.
sub ok ($;$) {
    my($test, $name) = @_;
    my $ok = '';
    $ok .= "not " unless $test;
    $ok .= "ok $test_num";
    $ok .= " - $name" if defined $name;
    $ok .= "\n";
    print $ok;
    $test_num++;
}


package main;

require Test::Simple;

push @INC, 't/lib';
require Test::Simple::Catch::More;
my($out, $err) = Test::Simple::Catch::More::caught();


Test::Simple->import('no_plan');

ok(1, 'foo');


END {
    My::Test::ok($$out eq <<OUT);
ok 1 - foo
1..1
OUT

    My::Test::ok($$err eq <<ERR);
ERR

    # Prevent Test::Simple from exiting with non zero
    exit 0;
}

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

# Can't use Test.pm, that's a 5.005 thing.
package My::Test;

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

require Test::More;
Test::More->import;
my($out, $err);

BEGIN {
    require Test::Harness;
}

if( $Test::Harness::VERSION < 1.20 ) {
    plan(skip_all => 'Need Test::Harness 1.20 or up');
}
else {
    push @INC, '../t/lib';
    require Test::Simple::Catch;
    ($out, $err) = Test::Simple::Catch::caught();
    plan('no_plan');
}

pass('Just testing');
ok(1, 'Testing again');

END {
    My::Test::ok($$out eq <<OUT);
ok 1 - Just testing
ok 2 - Testing again
1..2
OUT

    My::Test::ok($$err eq '');
}

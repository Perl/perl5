use strict;

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
require Test::More;

push @INC, 'lib/Test/More/';
require Catch;
my($out, $err) = Catch::caught();

Test::More->import('skip_all');


END {
    My::Test::ok($$out eq "1..0\n");
    My::Test::ok($$err eq "");
}

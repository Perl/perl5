# qr// was introduced in 5.004-devel.  Skip this test if we're not
# of high enough version.
BEGIN { 
    if( $] < 5.005 ) {
        print "1..0\n";
        exit(0);
    }
}


# There was a bug with like() involving a qr// not failing properly.
# This tests against that.

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

Test::More->import(tests => 1);

eval q{ like( "foo", qr/that/, 'is foo like that' ); };


END {
    My::Test::ok($$out eq <<OUT, 'failing output');
1..1
not ok 1 - is foo like that
OUT

    my $err_re = <<ERR;
#     Failed test \\(.*\\)
#                   'foo'
#     doesn't match '\\(\\?-xism:that\\)'
# Looks like you failed 1 tests of 1\\.
ERR


    My::Test::ok($$err =~ /^$err_re$/, 'failing errors');

    exit(0);
}

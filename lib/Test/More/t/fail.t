use strict;

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

@INC = ('../lib', 'lib/Test/More');
require Catch;
my($out, $err) = Catch::caught();

Test::More->import(tests => 8);

ok( 0, 'failing' );
is(  "foo", "bar", 'foo is bar?');
isnt("foo", "foo", 'foo isnt foo?' );
isn't("foo", "foo",'foo isn\'t foo?' );

like( "foo", '/that/',  'is foo like that' );

fail('fail()');

use_ok('Hooble::mooble::yooble');
require_ok('ALL::YOUR::BASE::ARE::BELONG::TO::US::wibble');

END {
    My::Test::ok($$out eq <<OUT, 'failing output');
1..8
not ok 1 - failing
not ok 2 - foo is bar?
not ok 3 - foo isnt foo?
not ok 4 - foo isn't foo?
not ok 5 - is foo like that
not ok 6 - fail()
not ok 7 - use Hooble::mooble::yooble;
not ok 8 - require ALL::YOUR::BASE::ARE::BELONG::TO::US::wibble;
OUT

    my $err_re = <<ERR;
#     Failed test ($0 at line 31)
#     Failed test ($0 at line 32)
#          got: 'foo'
#     expected: 'bar'
#     Failed test ($0 at line 33)
#     it should not be 'foo'
#     but it is.
#     Failed test ($0 at line 34)
#     it should not be 'foo'
#     but it is.
#     Failed test ($0 at line 36)
#                   'foo'
#     doesn't match '/that/'
#     Failed test ($0 at line 38)
ERR

   my $filename = quotemeta $0;
   my $more_err_re = <<ERR;
#     Failed test \\($filename at line 40\\)
#     Tried to use 'Hooble::mooble::yooble'.
#     Error:  Can't locate Hooble.* in \\\@INC .*

#     Failed test \\($filename at line 41\\)
#     Tried to require 'ALL::YOUR::BASE::ARE::BELONG::TO::US::wibble'.
#     Error:  Can't locate ALL.* in \\\@INC .*

# Looks like you failed 8 tests of 8.
ERR

    My::Test::ok($$err =~ /^\Q$err_re\E$more_err_re$/, 'failing errors');

    exit(0);
}

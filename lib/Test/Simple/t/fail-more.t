#!perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use strict;
use lib '../t/lib';

require Test::Simple::Catch;
my($out, $err) = Test::Simple::Catch::caught();


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

    return $test;
}


package main;

require Test::More;
Test::More->import(tests => 12);

# Preserve the line numbers.
#line 38
ok( 0, 'failing' );
is(  "foo", "bar", 'foo is bar?');
isnt("foo", "foo", 'foo isnt foo?' );
isn't("foo", "foo",'foo isn\'t foo?' );

like( "foo", '/that/',  'is foo like that' );

fail('fail()');

can_ok('Mooble::Hooble::Yooble', qw(this that));
isa_ok(bless([], "Foo"), "Wibble");
isa_ok(42,    "Wibble", "My Wibble");
isa_ok(undef, "Wibble", "Another Wibble");

use_ok('Hooble::mooble::yooble');
require_ok('ALL::YOUR::BASE::ARE::BELONG::TO::US::wibble');

END {
    My::Test::ok($$out eq <<OUT, 'failing output');
1..12
not ok 1 - failing
not ok 2 - foo is bar?
not ok 3 - foo isnt foo?
not ok 4 - foo isn't foo?
not ok 5 - is foo like that
not ok 6 - fail()
not ok 7 - Mooble::Hooble::Yooble->can(...)
not ok 8 - The object isa Wibble
not ok 9 - My Wibble isa Wibble
not ok 10 - Another Wibble isa Wibble
not ok 11 - use Hooble::mooble::yooble;
not ok 12 - require ALL::YOUR::BASE::ARE::BELONG::TO::US::wibble;
OUT

    my $err_re = <<ERR;
#     Failed test ($0 at line 38)
#     Failed test ($0 at line 39)
#          got: 'foo'
#     expected: 'bar'
#     Failed test ($0 at line 40)
#     it should not be 'foo'
#     but it is.
#     Failed test ($0 at line 41)
#     it should not be 'foo'
#     but it is.
#     Failed test ($0 at line 43)
#                   'foo'
#     doesn't match '/that/'
#     Failed test ($0 at line 45)
#     Failed test ($0 at line 47)
#     Mooble::Hooble::Yooble->can('this') failed
#     Mooble::Hooble::Yooble->can('that') failed
#     Failed test ($0 at line 48)
#     The object isn't a 'Wibble'
#     Failed test ($0 at line 49)
#     My Wibble isn't a reference
#     Failed test ($0 at line 50)
#     Another Wibble isn't defined
ERR

   my $filename = quotemeta $0;
   my $more_err_re = <<ERR;
#     Failed test \\($filename at line 52\\)
#     Tried to use 'Hooble::mooble::yooble'.
#     Error:  Can't locate Hooble.* in \\\@INC .*
#     Failed test \\($filename at line 53\\)
#     Tried to require 'ALL::YOUR::BASE::ARE::BELONG::TO::US::wibble'.
#     Error:  Can't locate ALL.* in \\\@INC .*
# Looks like you failed 12 tests of 12.
ERR

    unless( My::Test::ok($$err =~ /^\Q$err_re\E$more_err_re$/, 
                         'failing errors') ) {
        print map "# $_", $$err;
    }

    exit(0);
}

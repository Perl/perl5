use strict;

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

    return $test;
}


package main;

require Test::More;

push @INC, '../t/lib';
require Test::Simple::Catch::More;
my($out, $err) = Test::Simple::Catch::More::caught();

Test::More->import(tests => 10);

# Preserve the line numbers.
#line 31
ok( 0, 'failing' );
is(  "foo", "bar", 'foo is bar?');
isnt("foo", "foo", 'foo isnt foo?' );
isn't("foo", "foo",'foo isn\'t foo?' );

like( "foo", '/that/',  'is foo like that' );

fail('fail()');

can_ok('Mooble::Hooble::Yooble', qw(this that));
isa_ok(bless([], "Foo"), "Wibble");

use_ok('Hooble::mooble::yooble');
require_ok('ALL::YOUR::BASE::ARE::BELONG::TO::US::wibble');

END {
    My::Test::ok($$out eq <<OUT, 'failing output');
1..10
not ok 1 - failing
not ok 2 - foo is bar?
not ok 3 - foo isnt foo?
not ok 4 - foo isn't foo?
not ok 5 - is foo like that
not ok 6 - fail()
not ok 7 - Mooble::Hooble::Yooble->can(...)
not ok 8 - object->isa('Wibble')
not ok 9 - use Hooble::mooble::yooble;
not ok 10 - require ALL::YOUR::BASE::ARE::BELONG::TO::US::wibble;
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
#     Failed test ($0 at line 40)
#     Mooble::Hooble::Yooble->can('this') failed
#     Mooble::Hooble::Yooble->can('that') failed
#     Failed test ($0 at line 41)
#     The object isn't a 'Wibble'
ERR

   my $filename = quotemeta $0;
   my $more_err_re = <<ERR;
#     Failed test \\($filename at line 43\\)
#     Tried to use 'Hooble::mooble::yooble'.
#     Error:  Can't locate Hooble.* in \\\@INC .*

#     Failed test \\($filename at line 44\\)
#     Tried to require 'ALL::YOUR::BASE::ARE::BELONG::TO::US::wibble'.
#     Error:  Can't locate ALL.* in \\\@INC .*

# Looks like you failed 10 tests of 10.
ERR

    unless( My::Test::ok($$err =~ /^\Q$err_re\E$more_err_re$/, 
                         'failing errors') ) {
        print map "# $_", $$err;
    }

    exit(0);
}

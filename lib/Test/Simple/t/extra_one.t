#!/usr/bin/perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}

use strict;

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
}


package main;

require Test::Simple;
Test::Simple->import(tests => 1);
ok(1);
ok(1);
ok(1);

END {
    My::Test::ok($$out eq <<OUT);
1..1
ok 1
ok 2
ok 3
OUT

    My::Test::ok($$err eq <<ERR);
# Looks like you planned 1 test but ran 2 extra.
ERR

    # Prevent Test::Simple from existing with non-zero
    exit 0;
}

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
use strict;

use vars qw($Total_tests);

my $loaded;
my $test_num = 1;
BEGIN { $| = 1; $^W = 1; }
END {print "not ok $test_num\n" unless $loaded;}
print "1..$Total_tests\n";
use base;
$loaded = 1;
print "ok $test_num - Compiled\n";
$test_num++;
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
sub ok ($$) {
    my($test, $name) = @_;
    print "not " unless $test;
    print "ok $test_num";
    print " - $name" if defined $name;
    print "\n";
    $test_num++;
}

sub eqarray  {
    my($a1, $a2) = @_;
    return 0 unless @$a1 == @$a2;
    my $ok = 1;
    for (0..$#{$a1}) { 
        unless($a1->[$_] eq $a2->[$_]) {
        $ok = 0;
        last;
        }
    }
    return $ok;
}

# Change this to your # of ok() calls + 1
BEGIN { $Total_tests = 17 }

use vars qw( $W );
BEGIN {
    $W = 0;
    $SIG{__WARN__} = sub {
        if ($_[0] =~ /^Hides field '.*?' in base class/) {
            $W++;
        }
        else {
            warn $_[0];
        }
    };
}

package B1;
use fields qw(b1 b2 b3);

package B2;
use fields '_b1';
use fields qw(b1 _b2 b2);

sub new { bless [], shift }

package B3;
use fields qw(b4 _b5 b6 _b7);

package D1;
use base 'B1';
use fields qw(d1 d2 d3);

package D2;
use base 'B1';
use fields qw(_d1 _d2);
use fields qw(d1 d2);

package D3;
use base 'B2';
use fields qw(b1 d1 _b1 _d1);  # hide b1

package D4;
use base 'D3';
use fields qw(_d3 d3);

package M;
sub m {}

package D5;
use base qw(M B2);

# Test that multiple inheritance fails.
package D6;
eval {
    'base'->import(qw(B2 M B3));
};
::ok($@ =~ /can't multiply inherit %FIELDS/i, 'No multiple field inheritance');

package Foo::Bar;
use base 'B1';

package Foo::Bar::Baz;
use base 'Foo::Bar';
use fields qw(foo bar baz);

package main;

my %EXPECT = (
              B1 => [qw(b1 b2 b3)],
              B2 => [qw(_b1 b1 _b2 b2)],
              B3 => [qw(b4 _b5 b6 _b7)],
              D1 => [qw(d1 d2 d3 b1 b2 b3)],
              D2 => [qw(b1 b2 b3 _d1 _d2 d1 d2)],
              D3 => [qw(b1 b2 d1 _b1 _d1)],
              D4 => [qw(b1 b2 d1 _d3 d3)],
              M  => [qw()],
              D5 => [qw(b1 b2)],
              'Foo::Bar'        => [qw(b1 b2 b3)],
              'Foo::Bar::Baz'   => [qw(b1 b2 b3 foo bar baz)],
             );

while(my($class, $efields) = each %EXPECT) {
    no strict 'refs';
    my @fields = keys %{$class.'::FIELDS'};
    
    ::ok( eqarray([sort @$efields], [sort @fields]), 
                                                  "%FIELDS check:  $class" );
}

# Did we get the appropriate amount of warnings?
::ok($W == 1, 'got the right warnings');


# Break multiple inheritance with a field name clash.
package E1;
use fields qw(yo this _lah meep 42);

package E2;
use fields qw(_yo ahhh this);

eval {
    package Broken;

    # The error must occur at run time for the eval to catch it.
    require base;
    'base'->import(qw(E1 E2));
};
::ok( $@ && $@ =~ /Can't multiply inherit %FIELDS/i,
                                               'Again, no multi inherit' );


package No::Version;

use vars qw($Foo);
sub VERSION { 42 }

package Test::Version;

use base qw(No::Version);
::ok( $No::Version::VERSION =~ /set by base\.pm/,          '$VERSION bug' );


package Test::SIGDIE;

{ 
    local $SIG{__DIE__} = sub { 
        ::ok(0, 'sigdie not caught, this test should not run') 
    };
    eval {
      'base'->import(qw(Huh::Boo));
    };

    ::ok($@ =~ /^Base class package "Huh::Boo" is empty./, 
         'Base class empty error message');

}

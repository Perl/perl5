# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

my $Has_PH = $] < 5.009;

$SIG{__WARN__} = sub { return if $_[0] =~ /^Pseudo-hashes are deprecated/ };

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
use fields;
$loaded = 1;
print "ok $test_num\n";
$test_num++;
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
sub ok ($;$) {
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
BEGIN { $Total_tests = 10 }


package Foo;

use fields qw(_no Pants who _up_yours);
use fields qw(what);

sub new { fields::new(shift) }
sub magic_new { bless [] }  # Doesn't 100% work, perl's problem.

package main;

ok( eqarray( [sort keys %Foo::FIELDS], 
             [sort qw(_no Pants who _up_yours what)] ) 
  );

sub show_fields {
    my($base, $mask) = @_;
    no strict 'refs';
    my $fields = \%{$base.'::FIELDS'};
    return grep { ($fields::attr{$base}[$fields->{$_}] & $mask) == $mask} 
                keys %$fields;
}

ok( eqarray( [sort &show_fields('Foo', fields::PUBLIC)],
             [sort qw(Pants who what)]) );
ok( eqarray( [sort &show_fields('Foo', fields::PRIVATE)],
             [sort qw(_no _up_yours)]) );

# We should get compile time failures field name typos
eval q(my Foo $obj = Foo->new; $obj->{notthere} = "");

my $error = $Has_PH ? 'No such(?: [\w-]+)? field "notthere"'
                    : q[Attempt to access disallowed key 'notthere' in a ].
                      q[restricted hash at ];
ok( $@ && $@ =~ /^$error/i );


foreach (Foo->new) {
    my Foo $obj = $_;
    my %test = ( Pants => 'Whatever', _no => 'Yeah',
                 what  => 'Ahh',      who => 'Moo',
                 _up_yours => 'Yip' );

    $obj->{Pants} = 'Whatever';
    $obj->{_no}   = 'Yeah';
    @{$obj}{qw(what who _up_yours)} = ('Ahh', 'Moo', 'Yip');

    while(my($k,$v) = each %test) {
        ok($obj->{$k} eq $v);
    }
}

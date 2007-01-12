#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;
use warnings;

our @tests = (
    # /k     Pattern   PRE     MATCH   POST
    [ 'k',   "456",    "123-", "456",  "-789"],
    [ '',    "(456)",  "123-", "456",  "-789"],
    [ '',    "456",    undef,  undef,  undef ],
);

plan tests => 4 * @tests + 2;
my $W = "";

$SIG{__WARN__} = sub { $W.=join("",@_); };
sub _u($$) { "$_[0] is ".(defined $_[1] ? "'$_[1]'" : "undef") }

$_ = '123-456-789';
foreach my $test (@tests) {
    my ($k, $pat,$l,$m,$r) = @$test;
    my $test_name = "/$pat/$k";
    my $ok = ok($k ? /$pat/k : /$pat/, $test_name);
    SKIP: {
        skip "/$pat/$k failed to match", 3
            unless $ok;
        is(${^PREMATCH},  $l,_u "$test_name: ^PREMATCH",$l);
        is(${^MATCH},     $m,_u "$test_name: ^MATCH",$m );
        is(${^POSTMATCH}, $r,_u "$test_name: ^POSTMATCH",$r );
    }
}
is($W,"","No warnings should be produced");
ok(!defined ${^MATCH}, "No /k in scope so ^MATCH is undef");

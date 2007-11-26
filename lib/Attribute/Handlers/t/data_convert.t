#!/usr/bin/perl -w

# Test attribute data conversion using examples from the docs

BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 8;

package LoudDecl;
use Attribute::Handlers;

sub Loud :ATTR {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;

    ::is_deeply( $data, $referent->(), *{$symbol}{NAME} );
}


sub test1 :Loud(till=>ears=>are=>bleeding) {
    [qw(till ears are bleeding)]
}

sub test2 :Loud(['till','ears','are','bleeding']) {
    [qw(till ears are bleeding)]
}

sub test3 :Loud(qw/till ears are bleeding/) {
    [qw(till ears are bleeding)]
}

sub test4 :Loud(qw/my, ears, are, bleeding/) {
    [('my,', 'ears,', 'are,', 'bleeding')]
}

sub test5 :Loud(till,ears,are,bleeding) {
    [qw(till ears are bleeding)]
}

sub test6 :Loud("turn it up to 11, man!") {
    'turn it up to 11, man!';
}

::ok !defined eval q{
    sub test7 :Loud(my,ears,are,bleeding) {}
}, 'test7';

::ok !defined eval q{
    sub test8 :Loud(qw/my ears are bleeding) {}
}, 'test8';

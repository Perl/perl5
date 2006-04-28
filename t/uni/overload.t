#!perl -w

BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        @INC = '../lib';
    }
}

use Test::More tests => 8;

package UTF8Field;
use strict;

use overload '""' => 'stringify';

sub new {
    my $class = shift;
    return bless [shift, 0], $class;
}

sub stringify {
    my $self = shift;
    $self->[1] = ! $self->[1];
    if ($self->[1]) {
	utf8::downgrade($self->[0]);
    } else {
	utf8::upgrade($self->[0]);
    }
    $self->[0];
}

package main;

# Bug 34297
foreach my $t ("ASCII", "B\366se") {
    my $length = length $t;

    my $u = UTF8Field->new($t);
    is (length $u, $length, "length of '$t'");
    is (length $u, $length, "length of '$t'");
    is (length $u, $length, "length of '$t'");
    is (length $u, $length, "length of '$t'");
}

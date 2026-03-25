#!/usr/bin/perl

use v5.42;
use feature 'class';
no warnings 'experimental::class';

use Test::More;

## -----------------------------------------------------------------------------
## TODO: move these to a lib somewhere
## -----------------------------------------------------------------------------

role Eq {
    method equal_to;

    method not_equal_to ($other) {
        not $self->equal_to($other);
    }
}

role Comparable :does(Eq) {
    method compare;
    method equal_to ($other) {
        $self->compare($other) == 0;
    }

    method greater_than ($other)  {
        $self->compare($other) == 1;
    }

    method less_than  ($other) {
        $self->compare($other) == -1;
    }

    method greater_than_or_equal_to ($other)  {
        $self->greater_than($other) || $self->equal_to($other);
    }

    method less_than_or_equal_to ($other)  {
        $self->less_than($other) || $self->equal_to($other);
    }
}

role Printable {
    method to_string;
}

## -----------------------------------------------------------------------------

# all terms can be printed and compared for equality ...
role Term :does(Printable, Eq) {}

class Sym :does(Term) {
    field $ident :param :reader;

    method equal_to ($other) { $ident eq $other->ident }
    method to_string { $ident }
}

# literal types have a value associated with them
role Literal :does(Term) {
    field $value :param :reader;
}

class Bool :does(Literal) {
    method equal_to ($other) { $self->value == $other->value }
    method to_string { $self->value ? 'true' : 'false' }
}

# numbers and strings can also be compared (lt, gt, etc.)
class Str :does(Literal, Comparable) {
    method compare ($other) { $self->value cmp $other->value }
    method to_string { $self->value }
}

class Num :does(Literal, Comparable) {
    method compare ($other) { $self->value <=> $other->value }
    method to_string { "".$self->value }
}

# lists can be empty (Nil) or contain things (Cons)
role List :does(Term) {
    method is_nil;
}

class Nil :does(List) {
    method is_nil { true }

    method equal_to ($other) { $other isa Nil }
    method to_string { "()" }
}

class Cons :does(List) {
    field $head :param :reader;
    field $tail :param :reader //= Nil->new();

    method is_nil { false }

    method equal_to ($other) {
        $head->equal_to($other->head)
            && $tail->equal_to($other->tail)
    }

    method to_string {
        sprintf '(%s %s)' => $head->to_string, $tail->to_string;
    }
}

## ....

my $cons1 = Cons->new(
    head => Sym->new( ident => '+' ),
    tail => Cons->new(
        head => Num->new( value => 10 ),
        tail => Cons->new(
            head => Num->new( value => 20 ),
        ),
    )
);

my $cons2 = Cons->new(
    head => Sym->new( ident => '+' ),
    tail => Cons->new(
        head => Num->new( value => 10 ),
        tail => Cons->new(
            head => Num->new( value => 20 ),
        ),
    )
);

foreach my $c ($cons1, $cons2) {
    isa_ok($c, 'Cons');
    ok($c->DOES($_), "... does ${_}") foreach qw[
        List
        Term
        Eq
        Printable
    ];
    isa_ok($c->head, 'Sym');
    ok($c->head->DOES($_), "... does ${_}") foreach qw[
        Term
        Eq
        Printable
    ];
    isa_ok($c->tail->head, 'Num');
    ok($c->tail->head->DOES($_), "... does ${_}") foreach qw[
        Literal
        Comparable
        Term
        Eq
        Printable
    ];
}

ok($cons1->equal_to($cons2), '... these structures are equal');

# TODO - add an example with sorting of Num and Str

done_testing;

#!/usr/bin/perl

use v5.42;
use feature 'class';
no warnings 'experimental::class';

use Test::More;

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

class Currency::USD :does(Comparable, Printable) {
    field $amount :param :reader = 0;

    method compare ($other) {
        $amount <=> $other->amount;
    }

    method to_string {
        sprintf '$%0.2f USD' => $amount;
    }
}

my @dollars = map {
    Currency::USD->new( amount => rand(100) )
} 0 .. 9;

isa_ok($_, 'Currency::USD') foreach @dollars;

ok($_->DOES('Eq'),         '... does Eq')         foreach @dollars;
ok($_->DOES('Comparable'), '... does Comparable') foreach @dollars;
ok($_->DOES('Printable'),  '... does Printable')  foreach @dollars;

my @sorted = sort { $a->compare($b) } @dollars;

ok($sorted[0]->less_than($sorted[1]), '... looks sorted to me');
ok($sorted[1]->less_than($sorted[2]), '... looks sorted to me');
ok($sorted[2]->less_than($sorted[3]), '... looks sorted to me');
ok($sorted[3]->less_than($sorted[4]), '... looks sorted to me');
ok($sorted[4]->less_than($sorted[5]), '... looks sorted to me');
ok($sorted[5]->less_than($sorted[6]), '... looks sorted to me');
ok($sorted[6]->less_than($sorted[7]), '... looks sorted to me');
ok($sorted[7]->less_than($sorted[8]), '... looks sorted to me');
ok($sorted[8]->less_than($sorted[9]), '... looks sorted to me');

ok($sorted[0]->less_than_or_equal_to($sorted[1]), '... looks sorted to me');
ok($sorted[1]->less_than_or_equal_to($sorted[2]), '... looks sorted to me');
ok($sorted[2]->less_than_or_equal_to($sorted[3]), '... looks sorted to me');
ok($sorted[3]->less_than_or_equal_to($sorted[4]), '... looks sorted to me');
ok($sorted[4]->less_than_or_equal_to($sorted[5]), '... looks sorted to me');
ok($sorted[5]->less_than_or_equal_to($sorted[6]), '... looks sorted to me');
ok($sorted[6]->less_than_or_equal_to($sorted[7]), '... looks sorted to me');
ok($sorted[7]->less_than_or_equal_to($sorted[8]), '... looks sorted to me');
ok($sorted[8]->less_than_or_equal_to($sorted[9]), '... looks sorted to me');

ok($sorted[1]->greater_than($sorted[0]), '... looks sorted to me');
ok($sorted[2]->greater_than($sorted[1]), '... looks sorted to me');
ok($sorted[3]->greater_than($sorted[2]), '... looks sorted to me');
ok($sorted[4]->greater_than($sorted[3]), '... looks sorted to me');
ok($sorted[5]->greater_than($sorted[4]), '... looks sorted to me');
ok($sorted[6]->greater_than($sorted[5]), '... looks sorted to me');
ok($sorted[7]->greater_than($sorted[6]), '... looks sorted to me');
ok($sorted[8]->greater_than($sorted[7]), '... looks sorted to me');
ok($sorted[9]->greater_than($sorted[8]), '... looks sorted to me');

ok($sorted[1]->greater_than_or_equal_to($sorted[0]), '... looks sorted to me');
ok($sorted[2]->greater_than_or_equal_to($sorted[1]), '... looks sorted to me');
ok($sorted[3]->greater_than_or_equal_to($sorted[2]), '... looks sorted to me');
ok($sorted[4]->greater_than_or_equal_to($sorted[3]), '... looks sorted to me');
ok($sorted[5]->greater_than_or_equal_to($sorted[4]), '... looks sorted to me');
ok($sorted[6]->greater_than_or_equal_to($sorted[5]), '... looks sorted to me');
ok($sorted[7]->greater_than_or_equal_to($sorted[6]), '... looks sorted to me');
ok($sorted[8]->greater_than_or_equal_to($sorted[7]), '... looks sorted to me');
ok($sorted[9]->greater_than_or_equal_to($sorted[8]), '... looks sorted to me');

ok($sorted[1]->not_equal_to($sorted[0]), '... looks sorted to me');
ok($sorted[2]->not_equal_to($sorted[1]), '... looks sorted to me');
ok($sorted[3]->not_equal_to($sorted[2]), '... looks sorted to me');
ok($sorted[4]->not_equal_to($sorted[3]), '... looks sorted to me');
ok($sorted[5]->not_equal_to($sorted[4]), '... looks sorted to me');
ok($sorted[6]->not_equal_to($sorted[5]), '... looks sorted to me');
ok($sorted[7]->not_equal_to($sorted[6]), '... looks sorted to me');
ok($sorted[8]->not_equal_to($sorted[7]), '... looks sorted to me');
ok($sorted[9]->not_equal_to($sorted[8]), '... looks sorted to me');

ok($sorted[0]->equal_to($sorted[0]), '... looks sorted to me');
ok($sorted[1]->equal_to($sorted[1]), '... looks sorted to me');
ok($sorted[2]->equal_to($sorted[2]), '... looks sorted to me');
ok($sorted[3]->equal_to($sorted[3]), '... looks sorted to me');
ok($sorted[4]->equal_to($sorted[4]), '... looks sorted to me');
ok($sorted[5]->equal_to($sorted[5]), '... looks sorted to me');
ok($sorted[6]->equal_to($sorted[6]), '... looks sorted to me');
ok($sorted[7]->equal_to($sorted[7]), '... looks sorted to me');
ok($sorted[8]->equal_to($sorted[8]), '... looks sorted to me');
ok($sorted[9]->equal_to($sorted[9]), '... looks sorted to me');

is($sorted[0]->to_string, sprintf('$%0.2f USD', $sorted[0]->amount), '... looks printable to me');
is($sorted[1]->to_string, sprintf('$%0.2f USD', $sorted[1]->amount), '... looks printable to me');
is($sorted[2]->to_string, sprintf('$%0.2f USD', $sorted[2]->amount), '... looks printable to me');
is($sorted[3]->to_string, sprintf('$%0.2f USD', $sorted[3]->amount), '... looks printable to me');
is($sorted[4]->to_string, sprintf('$%0.2f USD', $sorted[4]->amount), '... looks printable to me');
is($sorted[5]->to_string, sprintf('$%0.2f USD', $sorted[5]->amount), '... looks printable to me');
is($sorted[6]->to_string, sprintf('$%0.2f USD', $sorted[6]->amount), '... looks printable to me');
is($sorted[7]->to_string, sprintf('$%0.2f USD', $sorted[7]->amount), '... looks printable to me');
is($sorted[8]->to_string, sprintf('$%0.2f USD', $sorted[8]->amount), '... looks printable to me');
is($sorted[9]->to_string, sprintf('$%0.2f USD', $sorted[9]->amount), '... looks printable to me');

done_testing;

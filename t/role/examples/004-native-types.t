#!/usr/bin/perl

use v5.42;
use feature 'class';
no warnings 'experimental::class';

use Test::More;

role Item {
    method defined;
}

role Defined :does(Item) {
    method defined { true }
}

role Value :does(Defined) {
    field $value :param :reader;

    method do ($block) {
        local $_ = $value;
        $block->($value);
    }
}

role String :does(Value) {
    method lc      { CORE::lc      $self->value }
    method lcfirst { CORE::lcfirst $self->value }
    method uc      { CORE::uc      $self->value }
    method ucfirst { CORE::ucfirst $self->value }
    method chomp   { CORE::chomp   $self->value }
    method chop    { CORE::chop    $self->value }
    method reverse { CORE::reverse $self->value }
    method length  { CORE::length  $self->value }
    method index   ($offset, $length=undef) {
        return CORE::index($self->value, $offset) if not defined $length;
        return CORE::index($self->value, $offset, $length);
    }
    method rindex ($substring, $position=undef)   {
        return CORE::rindex($self->value, $substring) if not defined $position;
        return CORE::rindex($self->value, $substring, $position);
    }
    method split ($pattern, $limit=undef) {
        return [ CORE::split($pattern, $self->value) ] if not defined $limit;
        return [ CORE::split($pattern, $self->value, $limit) ];
    }
}

role Number :does(Value) {
    method abs { CORE::abs $self->value }

    method to ($end) {
        return [ $self->value .. $end ] if $self->value <= $end;
        return [ reverse $end .. $self->value ];
    }
}

class Scalar :does(String, Number) {
    method print { CORE::print $self->value }
    method say   { CORE::say $self->value }
}


my $str = Scalar->new( value => "Hey!" );
isa_ok($str, 'Scalar');
ok($str->DOES('String'), '... does String');
ok($str->DOES('Number'), '... does Number');
ok($str->DOES('Value'), '... does Value');
ok($str->DOES('Defined'), '... does Defined');

done_testing;

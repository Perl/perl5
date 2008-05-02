#!./perl

BEGIN {
    chdir 't';
    @INC = '../lib';
    require './test.pl';
}

plan tests => 11;

use strict;
use warnings;


my @tests = ('$obj ~~ "key"', '"key" ~~ $obj', '$obj ~~ $obj');

{
    package Test::Object::NoOverload;
    sub new { bless { key => 1 } }
}

{
    my $obj = Test::Object::NoOverload->new;
    isa_ok($obj, 'Test::Object::NoOverload');
    for (@tests) {
	my $r = eval;
	ok(
	    ! defined $r,
	    "we do not smart match against an object's underlying implementation",
	);
	like(
	    $@,
	    qr/overload/,
	    "we die when smart matching an obj with no ~~ overload",
	);
    }
}

{
    package Test::Object::CopyOverload;
    sub new { bless { key => 1 } }
    use overload '~~' => sub { my %hash = %{ $_[0] }; %hash ~~ $_[1] };
}

{
    my $obj = Test::Object::CopyOverload->new;
    isa_ok($obj, 'Test::Object::CopyOverload');
    ok(eval, 'we are able to make an object ~~ overload') for @tests;
}

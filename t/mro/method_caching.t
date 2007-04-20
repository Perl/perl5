#!./perl

use strict;
use warnings;
no warnings 'redefine'; # we do a lot of this
no warnings 'prototype'; # we do a lot of this

BEGIN {
    unless (-d 'blib') {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

require './test.pl';

{
    package MCTest::Base;
    sub foo { return $_[1]+1 };
    sub bar { 42 };

    package MCTest::Derived;
    our @ISA = qw/MCTest::Base/;
}

# These are various ways of re-defining MCTest::Base::foo and checking whether the method is cached when it shouldn't be
my @testsubs = (
    sub { eval 'sub MCTest::Base::foo { return $_[1]+2 }'; is(MCTest::Derived->foo(0), 2); },
    sub { eval 'sub MCTest::Base::foo($) { return $_[1]+3 }'; is(MCTest::Derived->foo(0), 3); },
    sub { eval 'sub MCTest::Base::foo($) { 4 }'; is(MCTest::Derived->foo(0), 4); },
    sub { *MCTest::Base::foo = sub { $_[1]+5 }; is(MCTest::Derived->foo(0), 5); },
    sub { local *MCTest::Base::foo = sub { $_[1]+6 }; is(MCTest::Derived->foo(0), 6); },
    sub { is(MCTest::Derived->foo(0), 5); },
    sub { sub FFF { $_[1]+9 }; local *MCTest::Base::foo = *FFF; is(MCTest::Derived->foo(0), 9); },
    sub { is(MCTest::Derived->foo(0), 5); },
    sub { *ASDF::asdf = sub { $_[1]+7 }; *MCTest::Base::foo = \&ASDF::asdf; is(MCTest::Derived->foo(0), 7); },
    sub { *ASDF::asdf = sub { $_[1]+7 }; *MCTest::Base::foo = \&ASDF::asdf; is(MCTest::Derived->foo(0), 7); },
    sub { undef *MCTest::Base::foo; eval { MCTest::Derived->foo(0) }; like($@, qr/locate object method/); },
    sub { sub MCTest::Base::foo($); *MCTest::Base::foo = \&ASDF::asdf; is(MCTest::Derived->foo(0), 7); },
    sub { *XYZ = sub { $_[1]+8 }; ${MCTest::Base::}{foo} = \&XYZ; is(MCTest::Derived->foo(0), 8); },
);

plan(tests => scalar(@testsubs) + 1);

is(MCTest::Derived->foo(0), 1);
$_->() for (@testsubs);

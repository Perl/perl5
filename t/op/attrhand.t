#!/usr/bin/perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

plan tests => 1;

# test for bug #38475: parsing errors with multiline attributes

package Antler;

use Attribute::Handlers;

sub TypeCheck :ATTR(CODE,RAWDATA) {
    ::ok(1);
}

sub WrongAttr :ATTR(CODE,RAWDATA) {
    ::ok(0);
}

package Deer;
use base 'Antler';

sub something : TypeCheck(
    QNET::Util::Object,
    QNET::Util::Object,
    QNET::Util::Object
) { #           WrongAttr (perl tokenizer bug)
    # keep this ^ lined up !
    return 42;
}

something();

#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}
use strict;

# Currently only testing the reset of patterns.
plan tests => 20;

package aiieee;

sub zlopp {
    (shift =~ ?zlopp?) ? 1 : 0;
}

sub reset_zlopp {
    reset;
}

package CLINK;

sub ZZIP {
    shift =~ ?ZZIP? ? 1 : 0;
}

sub reset_ZZIP {
    reset;
}

package main;

is(aiieee::zlopp(""), 0, "mismatch doesn't match");
is(aiieee::zlopp("zlopp"), 1, "match matches first time");
is(aiieee::zlopp(""), 0, "mismatch doesn't match");
is(aiieee::zlopp("zlopp"), 0, "match doesn't match second time");
aiieee::reset_zlopp();
is(aiieee::zlopp("zlopp"), 1, "match matches after reset");
is(aiieee::zlopp(""), 0, "mismatch doesn't match");

aiieee::reset_zlopp();

is(aiieee::zlopp(""), 0, "mismatch doesn't match");
is(aiieee::zlopp("zlopp"), 1, "match matches first time");
is(CLINK::ZZIP(""), 0, "mismatch doesn't match");
is(CLINK::ZZIP("ZZIP"), 1, "match matches first time");
is(CLINK::ZZIP(""), 0, "mismatch doesn't match");
is(CLINK::ZZIP("ZZIP"), 0, "match doesn't match second time");
is(aiieee::zlopp(""), 0, "mismatch doesn't match");
is(aiieee::zlopp("zlopp"), 0, "match doesn't match second time");

aiieee::reset_zlopp();
is(aiieee::zlopp("zlopp"), 1, "match matches after reset");
is(aiieee::zlopp(""), 0, "mismatch doesn't match");

is(CLINK::ZZIP(""), 0, "mismatch doesn't match");
is(CLINK::ZZIP("ZZIP"), 0, "match doesn't match third time");

CLINK::reset_ZZIP();
is(CLINK::ZZIP("ZZIP"), 1, "match matches after reset");
is(CLINK::ZZIP(""), 0, "mismatch doesn't match");

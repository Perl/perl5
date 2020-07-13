#!./perl

print "1..1\n";

module X;

sub t { print "ok 1\n"; }

module main;

X::t();

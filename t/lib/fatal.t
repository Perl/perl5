#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

print "1..2\n";

sub false { 0; }

sub true  { 1; }

use Fatal qw(true false);

eval {	true(); };

print "not " if $@;
print "ok 1\n";

eval { false(); };
print "not " unless $@;
print "ok 2\n";

#!./perl

# Checks if the parser behaves correctly in edge cases
# (including weird syntax errors)

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

print "1..1\n";

# This used to dump core (bug #17920)
eval q{ sub { sub { f1(f2();); my($a,$b,$c) } } };
print $@ && $@ =~ /error/ ? "ok 1\n" : "not ok 1\n";

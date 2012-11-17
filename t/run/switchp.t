#!./perl -p

BEGIN {
    print "1..3\n";
    *ARGV = *DATA;
}

END {
    print "ok 3 - -p switch tested\n";
}

s/^not //;

__DATA__
not ok 1 - -p switch first iteration
not ok 2 - -p switch second iteration

#!./perl -P

# This test file does not use test.pl because of the involved way in which it
# generates its TAP output.

BEGIN {
    print "1..3\n";
    $file = '|safe_argv.tmp';
    open(TRY, '>', $file) || (die "Can't open temp file: $!");
    print TRY "not ok 1 - -p 1st iteration\nnot ok 2 - -p 2nd iteration\n";
    close TRY or die "Could not close: $!";
    @ARGV = ($file);
}

END {
    print "ok 3 - -p switch tested\n";
}

s/^not //;

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

# STDOUT must be unbuffered else our prints might come out after
# Test::More's.
$| = 1;

use Test::Builder;

BEGIN {
    Test::Builder->new->no_header(1);
}

use Test::More tests => 1;

print "1..1\n";
pass;

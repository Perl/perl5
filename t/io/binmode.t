#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use Test::More tests => 8;
use Config;

ok( binmode(STDERR),            'STDERR made binary' );
if ($Config{useperlio}) {
  ok( binmode(STDERR, ":unix"),   '  with unix discipline' );
} else {
  ok(1,   '  skip unix discipline for -Uuseperlio' );
}
ok( binmode(STDERR, ":raw"),    '  raw' );
ok( binmode(STDERR, ":crlf"),   '  and crlf' );

# If this one fails, we're in trouble.  So we just bail out.
ok( binmode(STDOUT),            'STDOUT made binary' )      || exit(1);
if ($Config{useperlio}) {
  ok( binmode(STDOUT, ":unix"),   '  with unix discipline' );
} else {
  ok(1,   '  skip unix discipline for -Uuseperlio' );
}
ok( binmode(STDOUT, ":raw"),    '  raw' );
ok( binmode(STDOUT, ":crlf"),   '  and crlf' );

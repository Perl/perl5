#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}


use Test::More tests => 8;

ok( binmode(STDERR),            'STDERR made binary' );
ok( binmode(STDERR, ":unix"),   '  with unix discipline' );
ok( binmode(STDERR, ":raw"),    '  raw' );
ok( binmode(STDERR, ":crlf"),   '  and crlf' );

# If this one fails, we're in trouble.  So we just bail out.
ok( binmode(STDOUT),            'STDOUT made binary' )      || exit(1);
ok( binmode(STDOUT, ":unix"),   '  with unix discipline' );
ok( binmode(STDERR, ":raw"),    '  raw' );
ok( binmode(STDERR, ":crlf"),   '  and crlf' );

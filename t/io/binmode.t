#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc(qw(. ../lib));
    eval 'use Errno';
    die $@ if $@ and !is_miniperl();
}


plan(tests => 10);

ok( binmode(STDERR),            'STDERR made binary' );
SKIP: {
    skip('skip unix discipline without PerlIO layers', 1)
	unless PerlIO::Layer->find( 'perlio' );
    ok( binmode(STDERR, ":unix"),   '  with unix discipline' );
}
ok( binmode(STDERR, ":raw"),    '  raw' );
ok( binmode(STDERR, ":crlf"),   '  and crlf' );

# If this one fails, we're in trouble.  So we just bail out.
ok( binmode(STDOUT),            'STDOUT made binary' )      || exit(1);
SKIP: {
    skip('skip unix discipline without PerlIO layers', 1)
	unless PerlIO::Layer->find( 'perlio' );
    ok( binmode(STDOUT, ":unix"),   '  with unix discipline' );
}
ok( binmode(STDOUT, ":raw"),    '  raw' );
ok( binmode(STDOUT, ":crlf"),   '  and crlf' );

SKIP: {
    skip "no EBADF", 1 unless exists &Errno::EBADF;

    no warnings 'io', 'once';
    $! = 0;
    binmode(B);
    cmp_ok($!, '==', Errno::EBADF());
}

fresh_perl_like(<<'EOP', qr/^no crash/, {}, q|no segfault with binmode $fh, ':encoding(UTF-8)'|);
    eval {
        my $filename = './io/binmode-u.dat';
        die "Could not locate $filename" unless -f $filename;
        open my $fh, '<', $filename or die "Can't open $filename: $!";
        binmode $fh, ':encoding(UTF-8)';
        while (<$fh>) {
            chomp;
            next if /^(#|--)/;
        }
        close $fh or die "Can't close $filename after reading";
    };
    print "no crash";
EOP


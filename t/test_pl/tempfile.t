#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
}
use strict;

my $prefix = 'tmp'.$$;

sub skip_files{
    my($skip,$to,$next) = @_;
    my($last,$check);
    my $cmp = $prefix . $to;

    for( 1..$skip ){
        $check = tempfile();
        $last = $_;
        if( $check eq $cmp && $_ != $skip ){
            # let the next test pass
            last;
        }
    }

    local $main::Level = $main::Level + 1;

    my $common_mess = "skip $skip filenames to $to so that the next one will end with $next";
    if( $last == $skip ){
        if( $check eq $cmp ){
            pass( $common_mess );
        }else{
            my($alpha) = $check =~ /\Atmp\d+([A-Z][A-Z]?)\Z/;
            fail( $common_mess );
            diag( "only skipped to $alpha" );
        }
    }else{
        fail( $common_mess );
        diag( "only skipped $last out of $skip files" );
    }
}

note("skipping the first filename because it is taken for use by _fresh_perl()");

is( tempfile(), "${prefix}B");
is( tempfile(), "${prefix}C");

{
    ok( open( my $fh, '>', "${prefix}D" ), 'created file with the next filename' );
    is( tempfile(), "${prefix}E", 'properly skips files that already exist');

    if( close($fh) ){
        unlink_all("${prefix}D");
    }else{
        tempfile(); # allow the rest of the tests to work correctly
    }
}

skip_files(20,'Y','Z');

is( tempfile(), "${prefix}Z", 'Last single letter filename');
is( tempfile(), "${prefix}AA", 'First double letter filename');

skip_files(24,'AY','AZ');

is( tempfile(), "${prefix}AZ");
is( tempfile(), "${prefix}BA");

skip_files(26 * 24 + 24,'ZY','ZZ');

is( tempfile(), "${prefix}ZZ", 'Last available filename');
ok( !eval{tempfile()}, 'Should bail after Last available filename' );
my $err = "$@";
like( $err, qr{^Can't find temporary file name starting}, 'check error string' );

done_testing();

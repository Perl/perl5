#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
}
use strict;

my $prefix = 'tmp'.$$;

sub skip_files{
  my($skip,$to) = @_;
  note("skipping $skip filenames so that the next one will end with $to.");
  tempfile() for 1..$skip;
}

note("skipping the first filename because it is taken for use by _fresh_perl()");

is( tempfile(), "${prefix}B");
is( tempfile(), "${prefix}C");

skip_files(22,'Z');

is( tempfile(), "${prefix}Z", 'Last single letter filename');
is( tempfile(), "${prefix}AA", 'First double letter filename');

skip_files(24,'AZ');

is( tempfile(), "${prefix}AZ");
is( tempfile(), "${prefix}BA");

skip_files(26 * 24 + 24,'ZZ');

is( tempfile(), "${prefix}ZZ", 'Last available filename');
ok( !eval{tempfile()}, 'Should bail after Last available filename' );
my $err = "$@";
like( $err, qr{^Can't find temporary file name starting}, 'check error string' );

done_testing();

use strict;
use warnings;

use File::Temp qw( tempfile );
use Test::Builder::Tester;
use Test::More;

use Test::PerlRun qw( :all );

test_out('ok 1');
perlrun_exit_status_is( 'exit 42', 42 );
test_test('exit status');

test_out('ok 1');
perlrun_exit_status_is( { code => 'exit 42' }, 42 );
test_test('exit status, code in hashref with code key');

my ( $fh, $file ) = tempfile( UNLINK => 1 );
print {$fh} 'exit 42;' or die "Cannot write to $file: $!";
close $fh or die "Cannot write to $file: $!";

test_out('ok 1');
perlrun_exit_status_is( { file => $file }, 42 );
test_test('exit status, code in temp file');

test_out('ok 1');
perlrun_stdout_is( q{print 'hello'}, 'hello' );
test_test('stdout_is');

test_out('ok 1');
perlrun_stdout_like( q{print 'hello'}, qr/hell/ );
test_test('stdout_like');

test_out('ok 1');
perlrun_stderr_is( q{print STDERR 'hello'}, 'hello' );
test_test('stderr_is');

test_out('ok 1');
perlrun_stderr_like( q{print STDERR 'hello'}, qr/hell/ );
test_test('stderr_like');

test_out('ok 1');
perlrun_stdout_is(
    {
        code     => q{print ${^TAINT} ? 'tainting' : 'no taint'},
        switches => '-T',
    },
    'tainting'
);
test_test('single scalar passed for switches parameter');

test_out('ok 1');
perlrun_stdout_is(
    {
        code     => q{print ${^TAINT} ? 'tainting' : 'no taint'},
        switches => ['-T'],
    },
    'tainting'
);
test_test('array ref passed for switches parameter');

my ( $stdout, $stderr, $status )
    = perlrun(q{print "stdout\n"; warn "stderr\n"; exit 99;});

is(
    $stdout, "stdout\n",
    'perlrun() captured stdout'
);
is(
    $stderr, "stderr\n",
    'perlrun() captured stderr'
);
is(
    $status, 99,
    'perlrun() captured status'
);

done_testing();

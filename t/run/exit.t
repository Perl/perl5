#!./perl
#
# Tests for perl exit codes, playing with $?, etc...


BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

# VMS and Windows need -e "...", most everything else works better with '
my $quote = $^O =~ /^(VMS|MSWin\d+)$/ ? q{"} : q{'};

# Run some code, return its wait status.
sub run {
    my($code) = shift;
    my $cmd = "$^X -e ";
    return system($cmd.$quote.$code.$quote);
}

use Test::More tests => 3;

my $exit;

$exit = run('exit');
is( $exit >> 8, 0,              'Normal exit' );

$exit = run('exit 42');
is( $exit >> 8, 42,             'Non-zero exit' );

$exit = run('END { $? = 42 }');
is( $exit >> 8, 42,             'Changing $? in END block' );

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

BEGIN {
    $numtests = ($^O eq 'VMS') ? 7 : 3; 
}

use Test::More tests => $numtests;

my $exit, $exit_arg;

$exit = run('exit');
is( $exit >> 8, 0,              'Normal exit' );

if ($^O ne 'VMS') {

  $exit = run('exit 42');
  is( $exit >> 8, 42,             'Non-zero exit' );

} else {

# On VMS, successful returns from system() are always 0, warnings are 1,
# errors are 2, and fatal errors are 4.

  $exit = run("exit 196609"); # %CLI-S-NORMAL
  is( $exit >> 8, 0,             'success exit' );

  $exit = run("exit 196611");  # %CLI-I-NORMAL
  is( $exit >> 8, 0,             'informational exit' );

  $exit = run("exit 196608");  # %CLI-W-NORMAL
  is( $exit >> 8, 1,             'warning exit' );

  $exit = run("exit 196610");  # %CLI-E-NORMAL
  is( $exit >> 8, 2,             'error exit' );

  $exit = run("exit 196612");  # %CLI-F-NORMAL
  is( $exit >> 8, 4,             'fatal error exit' );
}

$exit = run('END { $? = 42 }');
is( $exit >> 8, 42,             'Changing $? in END block' );

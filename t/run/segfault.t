#!./perl
#
# Tests for things which have caused segfaults in the past.

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

# VMS and Windows need -e "...", most everything else works better with '
my $quote = $^O =~ /^(VMS|MSWin\d+)$/ ? q{"} : q{'};

my $IsVMS = $^O eq 'VMS';


BEGIN {
   if( $^O =~ /^(VMS|MSWin\d+)$/ ) {
      print "1..0 # Skipped: platform temporarily not supported\n";
      exit;
   }
}


# Run some code, check that it has the expected output and exits
# with the code for a perl syntax error.
sub chk_segfault {
    my($code, $expect, $name) = @_;
    my $cmd = "$^X -e ";

    # I *think* these are the right exit codes for syntax error.
    my $expected_exit = $IsVMS ? 4 : 255;

    my $out = `$cmd$quote$code$quote 2>&1`;

    is( $? >> 8,    $expected_exit,     "$name - exit as expected" );
    like( $out, qr/$expect at -e line 1/, '  with the right output' );
}

use Test::More tests => 2;

chk_segfault('($a, b) = (1, 2)',  
             "Can't modify constant item in list assignment",
             'perlbug ID 20010831.001');

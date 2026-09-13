#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

use strict;
use warnings;

plan( 'tests' => 4 );

my $res  = system qq($^X -e'\''kill "KILL", \$\$; sleep 100'\'');
my $exit = $?;

our $TODO;

is( $res, $exit, "system() result ($res) and \$? ($exit) are the same" );
TODO: {
    local $TODO = "GH #19020 on $^O";
    is( $exit, 9, "\$? ($exit) from a KILL signal is 9" );
}
TODO: {
    local $TODO = "GH #19020 on $^O";
    is( $exit >> 8, 0, 'OS exit code (shifted) is 0' );
}
TODO: {
    local $TODO = "GH #19020 on $^O";
    is( $exit & 127, 9, 'KILL signal (bitwise ANDed exit) is 9' );
}

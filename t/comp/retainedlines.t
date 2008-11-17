#!./perl -w

# Check that lines from eval are correctly retained by the debugger

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require "./test.pl";
}

use strict;

plan( tests => 10 );

my @before = grep { /eval/ } keys %::;

is (@before, 0, "No evals");

for my $sep (' ') {
    $^P = 0xA;

    my $prog = "sub foo {
    'Perl${sep}Rules'
};
1;
";

    eval $prog or die;
    # Is there a more efficient way to write this?
    my @expect_lines = (undef, map ({"$_\n"} split "\n", $prog), "\n", ';');

    my @keys = grep { /eval/ } keys %::;

    is (@keys, 1, "1 eval");

    my @got_lines = @{$::{$keys[0]}};

    is (@got_lines, @expect_lines, "Right number of lines for " . ord $sep);

    for (0..$#expect_lines) {
	is ($got_lines[$_], $expect_lines[$_], "Line $_ is correct");
    }
}

#!./perl

use strict;
require 5.002;

## Main program.
{
    my (
	$bitmask,
	$nfound,
	);

    print "1..3\n";

    ## Does this OS support sockets?
    use Socket qw(AF_INET SOCK_STREAM);
    test (socket SOCK, AF_INET, SOCK_STREAM, 0);

    ## Does this OS support select()?
    vec($bitmask='', fileno(SOCK), 1) = 1;
    eval { $nfound = select($bitmask, '', '', 0) };
    test ($@ eq "");

    ## Did select() return a correct value?
    test (defined($nfound) and $nfound == 0);

    exit;
} # end main program


############################ Subroutines #############################


BEGIN {
    my $testnum = 0;

    sub test {
	if (defined($_[0]) and $_[0]) {
	    print "ok ", ++$testnum, "\n";
	}
	else {
	    print "not ok ", ++$testnum, "\n";
	}
    } # end sub test
}

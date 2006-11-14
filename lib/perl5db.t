#!/usr/bin/perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;
use warnings;

BEGIN {
    if (!-c "/dev/null") {
	print "1..0 # Skip: no /dev/null\n";
	exit 0;
    }
}

plan(1);

sub rc {
    open RC, ">", ".perldb" or die $!;
    print RC @_;
    close(RC);
}

rc(
    qq|
    &parse_options("NonStop=0 TTY=/dev/null LineInfo=db.out");
    \n|,

    qq|
    sub afterinit {
	push(\@DB::typeahead,
	    "DB::print_lineinfo(\@{'main::_<perl5db/eval-line-bug'})",
	    'b 23',
	    'c',
	    'q',
	);
    }\n|,
);

runperl(switches => [ '-d' ], progfile => '../lib/perl5db/eval-line-bug');

my $contents;
{
    local $/;
    open I, "<", 'db.out' or die $!;
    $contents = <I>;
    close(I);
}

like($contents, qr/factorial/,
    'The ${main::_<filename} variable in the debugger was not destroyed'
);

# clean up.

END {
    unlink '.perldb', 'db.out';
}

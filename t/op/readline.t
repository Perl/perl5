#!./perl

BEGIN {
    chdir 't';
    @INC = '../lib';
    require './test.pl';
}

plan tests => 1;

eval { for (\2) { $_ = <FH> } };
like($@, 'Modification of a read-only value attempted', '[perl #19566]');


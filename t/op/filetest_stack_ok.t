#!./perl

# On platforms that don't support all of the filetest operators the code
# that faked the results of missing tests used to leave the test's
# argument on the stack.

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

my @ops = split //, 'rwxoRWXOezsfdlpSbctugkTMBAC';

plan( tests => @ops * 1 );

for my $op (@ops) {
    ok( 1 == @{ [ eval "-$op 'TEST'" ] }, "-$op returns single value" );
}

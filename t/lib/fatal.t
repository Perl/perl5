#!./perl -w

BEGIN {
   chdir 't' if -d 't';
   unshift @INC, '../lib';
   print "1..13\n";
}

use vars '*FOO';
use strict;
use Fatal qw(open close);

my $i = 1;
eval { open FOO, '<lkjqweriuapofukndajsdlfjnvcvn' };
print "not " unless $@ =~ /^Can't open/;
print "ok $i\n"; ++$i;

my $foo = 'FOO';
for ('$foo', "'$foo'", "*$foo", "\\*$foo") {
    eval qq{ open $_, '<$0' };
    print "not " if $@;
    print "ok $i\n"; ++$i;

    print "not " if $@ or scalar(<FOO>) !~ m|^#!./perl|;
    print "ok $i\n"; ++$i;
    eval qq{ close FOO };
    print "not " if $@;
    print "ok $i\n"; ++$i;
}

#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

print "1..1\n";

use FindBin qw($Bin);

my $match = $^O eq 'MacOS' ? qr/t:lib:$/ : qr,t[/.]lib\]?$,;
print "not " unless $Bin =~ $match;
print "ok 1\n";

#!./perl

BEGIN {
    chdir('t') if -d 't';    
    @INC = 'lib';
}

print "1..6\n";

use MyFilter qr/not ok/ => "ok", fail => "ok";

sub fail { print "fail ", $_[0], "\n" }

print "not ok 1\n";
print "fail 2\n";

fail(3);
&fail(4);

print "not " unless "whatnot okapi" eq "whatokapi";
print "ok 5\n";

no MyFilter;

print "not " unless "not ok" =~ /^not /;
print "ok 6\n";


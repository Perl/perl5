print "1..3\n";

use strict;
use HTML::Parser ();

my $p = HTML::Parser->new(api_version => 3);

print "not " if $p->handler("start");
print "ok 1\n";

eval {
   my $p = HTML::Parser->new(api_version => 4);
   print "not ";
};
print $@;
print "ok 2\n";

$p = HTML::Parser->new(api_version => 2);

print "not " unless $p->handler("start") eq "start";
print "ok 3\n";



use strict; use warnings;

BEGIN { require './t/lib/ok.pl' }
use Text::Wrap;

print "1..2\n";

$Text::Wrap::columns = 4;
my $x = eval { wrap('', '123', 'some text') };
ok(!$@);
ok($x eq "some\n123t\n123e\n123x\n123t");

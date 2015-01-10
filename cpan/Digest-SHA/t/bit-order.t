use strict;
use Digest::SHA;

my $s1 = Digest::SHA->new;
my $s2 = Digest::SHA->new;
my $d1 = $s1->add_bits("110")->hexdigest;
my $d2 = $s2->add_bits("1")->add_bits("1")->add_bits("0")->hexdigest;

my $numtests = 1;
print "1..$numtests\n";

for (1 .. $numtests) {
	print "not " unless $d1 eq $d2;
	print "ok ", $_, "\n";
}

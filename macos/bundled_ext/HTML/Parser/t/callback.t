print "1..47\n";

use strict;
use HTML::Parser;

my @expected;
my $p = HTML::Parser->new(api_version => 3,
                          unbroken_text => 1,
	                  default_h => [\@expected, '@{event, text}'],
			 );

my $doc = <<'EOT';
<title>Hi</title>
<h1>Ho ho</h1>
<--comment->
EOT

$p->parse($doc)->eof;
#use Data::Dump; Data::Dump::dump(@expected);

my $testno = 1;

for my $i (1..length($doc)) {
     my @t;
     $p->handler(default => \@t);
     $p->parse(chunk($doc, $i));

     # check that we got the same stuff
     #print "X:", join(":", @t), "\n";
     #print "Y:", join(":", @expected), "\n";
     print "not " unless join(":", @t) eq join(":", @expected);
     print "ok $testno\n";
     $testno++;
}

sub chunk {
    my $str = shift;
    my $size = shift || 1;
    sub {
	my $res = substr($str, 0, $size);
        #print "...$res\n";
        substr($str, 0, $size) = "";
	$res;
    }
}

# Test croking behaviour
$p->handler(default => []);

eval {
   $p->parse(sub { die "Hi" });
};
print "ERRSV: $@";
print "not " unless $@ && $@ =~ /^Hi/;
print "ok $testno\n";
$testno++;









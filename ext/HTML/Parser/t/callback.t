use Test::More tests => 47;

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

for my $i (1..length($doc)) {
     my @t;
     $p->handler(default => \@t);
     $p->parse(chunk($doc, $i));

     # check that we got the same stuff
     #diag "X:", join(":", @t);
     #diag "Y:", join(":", @expected);
     is(join(":", @t), join(":", @expected));
}

sub chunk {
    my $str = shift;
    my $size = shift || 1;
    sub {
	my $res = substr($str, 0, $size);
        #diag "...$res";
        substr($str, 0, $size) = "";
	$res;
    }
}

# Test croking behaviour
$p->handler(default => []);

eval {
   $p->parse(sub { die "Hi" });
};
like($@, qr/^Hi/);

# Verify thread safety.

use Config;
use Test::More;

BEGIN {
    plan(skip_all => "Not configured for threads")
	unless $Config{useithreads} && $] >= 5.008;
    plan(tests => 1);
}

use threads;
use HTML::Parser;

my $ok=0;

sub start
{
    my($tag,$attr)=@_;

    $ok += ($tag eq "foo");
    $ok += (defined($attr->{param}) && $attr->{param} eq "bar");
}

my $p = HTML::Parser->new
    (api_version => 3,
     handlers => {
	 start => [\&start, "tagname,attr"],
     });

$p->parse("<foo pa");

$ok=async {
    $p->parse("ram=bar>");
    $ok;
}->join();

is($ok,2);


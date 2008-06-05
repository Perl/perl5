# Test handler method

use Test::More tests => 11;

my $testno;

use HTML::Parser;
{
    package MyParser;
    use vars qw(@ISA);
    @ISA=(HTML::Parser);
    
    sub foo
    {
	Test::More::is($_[1]{testno}, Test::More->builder->current_test + 1);
    }

    sub bar
    {
	Test::More::is($_[1], Test::More->builder->current_test + 1);
    }
}

$p = MyParser->new(api_version => 3);

eval {
    $p->handler(foo => "foo", "foo");
};

like($@, qr/^No handler for foo events/);

eval {
   $p->handler(start => "foo", "foo");
};
like($@, qr/^Unrecognized identifier foo in argspec/);

my $h = $p->handler(start => "foo", "self,tagname");
ok(!defined($h));

$x = \substr("xfoo", 1);
$p->handler(start => $$x, "self,attr");
$p->parse("<a testno=4>");

$p->handler(start => \&MyParser::foo, "self,attr");
$p->parse("<a testno=5>");

$p->handler(start => "foo");
$p->parse("<a testno=6>");

$p->handler(start => "bar", "self,'7'");
$p->parse("<a>");

eval {
    $p->handler(start => {}, "self");
};
like($@, qr/^Only code or array references allowed as handler/);

$a = [];
$p->handler(start => $a);
$h = $p->handler("start");
is($p->handler("start", "foo"), $a);

is($p->handler("start", \&MyParser::foo, ""), "foo");

is($p->handler("start"), \&MyParser::foo);



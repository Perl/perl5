# Test handler method

print "1..11\n";

my $testno;

use HTML::Parser;
{
    package MyParser;
    use vars qw(@ISA);
    @ISA=(HTML::Parser);

    sub foo
    {
	print "ok $_[1]{testno}\n";
    }

    sub bar
    {
	print "ok $_[1]\n";
    }
}

$p = MyParser->new(api_version => 3);

eval {
    $p->handler(foo => "foo", "foo");
};

print "not " unless $@ && $@ =~ /^No handler for foo events/;
print "ok 1\n";

eval {
   $p->handler(start => "foo", "foo");
};
print "not " unless $@ && $@ =~ /^Unrecognized identifier foo in argspec/;
print "ok 2\n";

my $h = $p->handler(start => "foo", "self,tagname");
print "not " if defined($h);
print "ok 3\n";

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
print "not " unless $@ && $@ =~ /^Only code or array references allowed as handler/;
print "ok 8\n";

$a = [];
$p->handler(start => $a);
$h = $p->handler("start");
print "not " unless $p->handler("start", "foo") == $a;
print "ok 9\n";

print "not " unless $p->handler("start", \&MyParser::foo, "") eq "foo";
print "ok 10\n";

print "not " unless $p->handler("start") == \&MyParser::foo;
print "ok 11\n";



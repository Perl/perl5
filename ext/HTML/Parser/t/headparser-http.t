use Test::More tests => 1;

eval {
   require HTML::HeadParser;
   $p = HTML::HeadParser->new;
};

SKIP: {
skip $@, 1 if $@ =~ /^Can't locate HTTP/;

$p = HTML::HeadParser->new($h);
$p->parse(<<EOT);
<title>Stupid example</title>
<base href="http://www.sn.no/libwww-perl/">
Normal text starts here.
EOT
$h = $p->header;
undef $p;
is($h->title, "Stupid example");
}

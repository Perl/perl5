eval {
   require HTML::HeadParser;
   $p = HTML::HeadParser->new;
};
if ($@) {
   print "1..0\n" if $@ =~ /^Can't locate HTTP/;
   print $@;
   exit;
}

print "1..1\n";


$p = HTML::HeadParser->new($h);
$p->parse(<<EOT);
<title>Stupid example</title>
<base href="http://www.sn.no/libwww-perl/">
Normal text starts here.
EOT
$h = $p->header;
undef $p;
print $h->title;   # should print "Stupid example"
print "\n";

print "not " unless $h->title eq "Stupid example";
print "ok 1\n";


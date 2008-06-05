use Test::More tests => 3;

use HTML::PullParser;

my $doc = <<'EOT';
<title>Title</title>
<style> h1 { background: white }
<foo>
</style>
<H1 ID="3">Heading</H1>
<!-- ignore this -->

This is a text with a <A HREF="http://www.sol.no" name="l1">link</a>.
EOT

my $p = HTML::PullParser->new(doc   => $doc,
			      start => 'event,tagname,@attr',
                              end   => 'event,tagname',
			      text  => 'event,dtext',

                              ignore_elements         => [qw(script style)],
			      unbroken_text           => 1,
			      boolean_attribute_value => 1,
			     );

my $t = $p->get_token;
is($t->[0], "start");
is($t->[1], "title");
$p->unget_token($t);

my @a;
while (my $t = $p->get_token) {
    for (@$t) {
	s/\s/./g;
    }
    push(@a, join("|", @$t));
}

my $res = join("\n", @a, "");
#diag $res;
is($res, <<'EOT');
start|title
text|Title
end|title
text|..
start|h1|id|3
text|Heading
end|h1
text|...This.is.a.text.with.a.
start|a|href|http://www.sol.no|name|l1
text|link
end|a
text|..
EOT


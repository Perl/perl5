#!/usr/bin/perl -w

use strict;
my $tag;
my $text;

use HTML::Parser ();
my $p = HTML::Parser->new(start_h => [sub { $tag = shift  }, "tagname"],
	                  text_h  => [sub { $text .= shift }, "dtext"],
                         );


use Test::More tests => 14;

SKIP: {
eval {
    $p->marked_sections(1);
};
skip $@, 14 if $@;

$p->parse("<![[foo]]>");
is($text, "foo");

$p->parse("<![TEMP INCLUDE[bar]]>");
is($text, "foobar");

$p->parse("<![ INCLUDE -- IGNORE -- [foo<![IGNORE[bar]]>]]>\n<br>");
is($text, "foobarfoo\n");

$text = "";
$p->parse("<![  CDATA   [&lt;foo");
$p->parse("<![IGNORE[bar]]>,bar&gt;]]><br>");
is($text, "&lt;foo<![IGNORE[bar,bar>]]>");

$text = "";
$p->parse("<![ RCDATA [&aring;<a>]]><![CDATA[&aring;<a>]]>&aring;<a><br>");
is($text, "å<a>&aring;<a>å");
is($tag, "br");

$text = "";
$p->parse("<![INCLUDE RCDATA CDATA IGNORE [foo&aring;<a>]]><br>");
is($text,  "");

$text = "";
$p->parse("<![INCLUDE RCDATA CDATA [foo&aring;<a>]]><br>");
is($text, "foo&aring;<a>");

$text = "";
$p->parse("<![INCLUDE RCDATA [foo&aring;<a>]]><br>");
is($text, "fooå<a>");

$text = "";
$p->parse("<![INCLUDE [foo&aring;<a>]]><br>");
is($text, "fooå");

$text = "";
$p->parse("<![[foo&aring;<a>]]><br>");
is($text, "fooå");

# offsets/line/column numbers
$p = HTML::Parser->new(default_h => [\&x, "line,column,offset,event,text"],
		       marked_sections => 1,
		      );
$p->parse(<<'EOT')->eof;
<title>Test</title>
<![CDATA
  [foo&aring;<a>
]]>
<![[
INCLUDE
STUFF
]]>
  <h1>Test</h1>
EOT

my @x;
sub x {
    my($line, $col, $offset, $event, $text) = @_;
    $text =~ s/\n/\\n/g;
    $text =~ s/ /./g;
    push(@x, "$line.$col:$offset $event \"$text\"\n");
}

#diag @x;
is(join("", @x), <<'EOT');
1.0:0 start_document ""
1.0:0 start "<title>"
1.7:7 text "Test"
1.11:11 end "</title>"
1.19:19 text "\n"
3.3:32 text "foo&aring;<a>\n"
4.3:49 text "\n"
5.4:54 text "\nINCLUDE\nSTUFF\n"
8.3:72 text "\n.."
9.2:75 start "<h1>"
9.6:79 text "Test"
9.10:83 end "</h1>"
9.15:88 text "\n"
10.0:89 end_document ""
EOT

my $doc = "<Tag><![CDATA[This is cdata]]></Tag>";
my $result = "";
$p = HTML::Parser->new(
    marked_sections => 1,
    handlers => {
        default => [ sub { $result .= join("",@_); }, "skipped_text,text" ]
    }
)->parse($doc)->eof;
is($doc, $result);

$text = "";
$p = HTML::Parser->new(
    text_h => [sub { $text .= shift }, "dtext"],
    marked_sections => 1,
);

$p->parse("<![CDATA[foo [1]]]>");
is($text, "foo [1]", "CDATA text ending in square bracket");

} # SKIP

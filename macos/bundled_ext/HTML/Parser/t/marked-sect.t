#!/usr/bin/perl -w

use strict;
my $tag;
my $text;

use HTML::Parser ();
my $p = HTML::Parser->new(start_h => [sub { $tag = shift  }, "tagname"],
	                  text_h  => [sub { $text .= shift }, "dtext"],
                         );

eval {
    $p->marked_sections(1);
};
if ($@) {
    print $@;
    print "1..0\n";
    exit;
}

print "1..11\n";

$p->parse("<![[foo]]>");
print "not " unless $text eq "foo";
print "ok 1\n";

$p->parse("<![TEMP INCLUDE[bar]]>");
print "not " unless $text eq "foobar";
print "ok 2\n";

$p->parse("<![ INCLUDE -- IGNORE -- [foo<![IGNORE[bar]]>]]>\n<br>");
print "not " unless $text eq "foobarfoo\n";
print "ok 3\n";

$text = "";
$p->parse("<![  CDATA   [&lt;foo");
$p->parse("<![IGNORE[bar]]>,bar&gt;]]><br>");
print "not " unless $text eq "&lt;foo<![IGNORE[bar,bar>]]>";
print "ok 4\n";

$text = "";
$p->parse("<![ RCDATA [&aring;<a>]]><![CDATA[&aring;<a>]]>&aring;<a><br>");
print "not " unless $text eq "å<a>&aring;<a>å" && $tag eq "br";
print "ok 5\n";

$text = "";
$p->parse("<![INCLUDE RCDATA CDATA IGNORE [foo&aring;<a>]]><br>");
print "not " unless $text eq "";
print "ok 6\n";

$text = "";
$p->parse("<![INCLUDE RCDATA CDATA [foo&aring;<a>]]><br>");
print "not " unless $text eq "foo&aring;<a>";
print "ok 7\n";

$text = "";
$p->parse("<![INCLUDE RCDATA [foo&aring;<a>]]><br>");
print "not " unless $text eq "fooå<a>";
print "ok 8\n";

$text = "";
$p->parse("<![INCLUDE [foo&aring;<a>]]><br>");
print "not " unless $text eq "fooå";
print "ok 9\n";

$text = "";
$p->parse("<![[foo&aring;<a>]]><br>");
print "not " unless $text eq "fooå";
print "ok 10\n";

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

#print @x;
print "not " unless join("", @x) eq <<'EOT';
1.0:0 start_document ""
1.0:0 start "<title>"
1.7:7 text "Test"
1.11:11 end "</title>"
1.19:19 text "\n"
3.3:29 text "foo&aring;<a>\n"
4.3:46 text "\n"
5.1:48 text "\nINCLUDE\nSTUFF\n"
8.3:66 text "\n.."
9.2:69 start "<h1>"
9.6:73 text "Test"
9.10:77 end "</h1>"
9.15:82 text "\n"
10.0:83 end_document ""
EOT
print "ok 11\n";

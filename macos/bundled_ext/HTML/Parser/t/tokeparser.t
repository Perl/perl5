print "1..6\n";

use strict;
use HTML::TokeParser;

# First we create an HTML document to test

my $file = "ttest$$.htm";
die "$file already exists" if -e $file;

open(F, ">$file") or die "Can't create $file: $!";
print F <<'EOT';  close(F);

<!--This is a test-->
<html><head><title>
  This is the &lt;title&gt;
</title>

  <base href="http://www.perl.com">
</head>

<body background="bg.gif">

    <h1>This is the <b>title</b> again
    </h1>

    And this is a link to the <a href="http://www.perl.com"><img src="camel.gif" alt="Perl">&nbsp;<!--nice isn't it-->Institute</a>

   <? process instruction >

</body>
</html>

EOT

END { unlink($file) || warn "Can't unlink $file: $!"; }


my $p;


$p = HTML::TokeParser->new($file) || die "Can't open $file: $!";
if ($p->get_tag("foo", "title")) {
    my $title = $p->get_trimmed_text;
    #print "Title: $title\n";
    print "not " unless $title eq "This is the <title>";
    print "ok 1\n";
}
undef($p);

# Test with reference to glob
open(F, $file) || die "Can't open $file: $!";
$p = HTML::TokeParser->new(\*F);
my $scount = 0;
my $ecount = 0;
my $tcount = 0;
my $pcount = 0;
while (my $token = $p->get_token) {
    $scount++ if $token->[0] eq "S";
    $ecount++ if $token->[0] eq "E";
    $pcount++ if $token->[0] eq "PI";
}
undef($p);
close F;

# Test with glob
open(F, $file) || die "Can't open $file: $!";
$p = HTML::TokeParser->new(*F);
$tcount++ while $p->get_tag;
undef($p);
close F;

# Test with plain file name
$p = HTML::TokeParser->new($file) || die;
$tcount++ while $p->get_tag;
undef($p);

print "Number of tokens found: $tcount/2 = $scount + $ecount\n";
print "Number of process instruction found: $pcount\n";
print "not " unless $tcount == 32 &&
                    $scount == 9 && $ecount == 7 &&
                    $pcount == 1;
print "ok 2\n";

print "not " if HTML::TokeParser->new("/noT/thEre/$$");
print "ok 3\n";


$p = HTML::TokeParser->new($file) || die;
$p->get_tag("a");
my $atext = $p->get_text;
undef($p);

#print "ATEXT: $atext\n";
print "not " unless $atext eq "Perl\240Institute";
print "ok 4\n";

# test parsing of embeded document
$p = HTML::TokeParser->new(\<<HTML);
<title>Title</title>
<H1>
Heading
</h1>
HTML

print "not " unless $p->get_tag("h1") && $p->get_trimmed_text eq "Heading";
print "ok 5\n";
undef($p);

# test parsing of large embedded documents
my $doc = "<a href='foo'>foo is bar</a>\n\n\n" x 2022;

#use Time::HiRes qw(time);
my $start = time;
$p = HTML::TokeParser->new(\$doc);
print "Contruction time: ", time - $start, "\n";

my $count;
while (my $t = $p->get_token) {
    $count++ if $t->[0] eq "S";
}
print "Parse time: ", time - $start, "\n";

print "not " unless $count == 2022;
print "ok 6\n";


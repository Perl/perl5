#!/usr/bin/perl -w

print "1..3\n";
use strict;

use HTML::Parser;

my $p = HTML::Parser->new(api_version => 3, ignore_tags => [qw(b i em tt)]);
$p->ignore_elements("script");
$p->unbroken_text(1);

$p->handler(default => [], "event, text");
$p->parse(<<"EOT")->eof;
<html><head><title>foo</title><Script language="Perl">
   while (<B>) {
      # ...
   }
</Script><body>
This is an <i>italic</i> and <b>bold</b> text.
</body>
</html>
EOT

my $t = join("||", map join("|", @$_), @{$p->handler("default")});
#print "$t\n";

print "not " unless $t eq "start_document|||start|<html>||start|<head>||start|<title>||text|foo||end|</title>||start|<body>||text|
This is an italic and bold text.
||end|</body>||text|
||end|</html>||text|
||end_document|";
print "ok 1\n";


#------------------------------------------------------

$p = HTML::Parser->new(api_version => 3);
$p->report_tags("a");
$p->handler(start => sub {
		my($tagname, %attr) = @_;
		print "not " unless $tagname eq "a" && $attr{href} eq "#a";
                print "ok 2\n";
            }, 'tagname, @attr');
$p->handler(end => sub {
		my $tagname = shift;
		print "not " unless $tagname eq "a";
                print "ok 3\n";
            }, 'tagname');

$p->parse(<<EOT)->eof;

<h1>Next example</h1>

This is <a href="#a">very nice</a> example.

EOT

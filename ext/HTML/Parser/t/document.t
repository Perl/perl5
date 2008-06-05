#!perl -w

use Test;
plan tests => 6;


use HTML::Parser;
use File::Spec;

my $events;
my $p = HTML::Parser->new(default_h => [sub { $events .= "$_[0]\n";}, "event"]);

$events = "";
$p->eof;
ok($events, "start_document\nend_document\n");

$events = "";
$p->parse_file(File::Spec->devnull);
ok($events, "start_document\nend_document\n");

$events = "";
$p->parse("");
$p->eof;
ok($events, "start_document\nend_document\n");

$events = "";
$p->parse("");
$p->parse("");
$p->eof;
ok($events, "start_document\nend_document\n");

$events = "";
$p->parse("");
$p->parse("<a>");
$p->eof;
ok($events, "start_document\nstart\nend_document\n");

$events = "";
$p->parse("<a> ");
$p->eof;
ok($events, "start_document\nstart\ntext\nend_document\n");

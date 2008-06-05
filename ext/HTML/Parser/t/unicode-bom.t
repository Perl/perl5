#!perl -w

use strict;
use Test::More tests => 2;
use HTML::Parser;

SKIP: {
skip "This perl does not support Unicode", 2 if $] < 5.008;

my @parsed;
my $p = HTML::Parser->new(
  api_version => 3,
  start_h => [\@parsed, 'tag, attr'],
);

my @warn;
$SIG{__WARN__} = sub {
    push(@warn, $_[0]);
};

$p->parse("\xEF\xBB\xBF<head>Hi there</head>");
$p->eof;

#use Encode;
$p->parse("\xEF\xBB\xBF<head>Hi there</head>" . chr(0x263A));
$p->eof;

$p->parse("\xFF\xFE<head>Hi there</head>");
$p->eof;

$p->parse("\xFE\xFF<head>Hi there</head>");
$p->eof;

$p->parse("\0\0\xFF\xFE<head>Hi there</head>");
$p->eof;

$p->parse("\xFE\xFF\0\0<head>Hi there</head>");
$p->eof;

is(join("", @warn), <<EOT);
Parsing of undecoded UTF-8 will give garbage when decoding entities at $0 line 21.
Parsing of undecoded UTF-8 will give garbage when decoding entities at $0 line 25.
Parsing of undecoded UTF-16 at $0 line 28.
Parsing of undecoded UTF-16 at $0 line 31.
Parsing of undecoded UTF-32 at $0 line 34.
Parsing of undecoded UTF-32 at $0 line 37.
EOT

@warn = ();

$p = HTML::Parser->new(
  api_version => 3,
  start_h => [\@parsed, 'tag'],
);

$p->parse("\xEF\xBB\xBF<head>Hi there</head>");
$p->eof;
ok(!@warn);
}

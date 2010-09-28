#!/usr/bin/perl -Tw

use strict;

use Test::More tests => 3;
use Locale::Maketext;

# declare a class...
{
  package Woozle;
  our @ISA = ('Locale::Maketext');
  our %Lexicon = (
    _AUTO => 1
  );
  keys %Lexicon; # dodges the 'used only once' warning
}

my $lh = Woozle->new();
isa_ok($lh, 'Woozle');

$@ = 'foo';
is($lh->maketext('Eval error: [_1]', $@), 'Eval error: foo', "Make sure \$@ is localized when passed to maketext");
is($@, 'foo', "\$@ wasn't modified during call");

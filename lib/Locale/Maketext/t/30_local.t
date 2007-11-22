
require 5;
use Test;
BEGIN { plan tests => 4; }
use Locale::Maketext;
print "# Hi there...\n";
ok 1;

print "# --- Making sure that Perl globals are localized ---\n";

# declare a class...
{
  package Woozle;
  @ISA = ('Locale::Maketext');
  %Lexicon = (
    _AUTO => 1
  );
  keys %Lexicon; # dodges the 'used only once' warning
}

my $lh;
print "# Basic sanity:\n";
ok defined( $lh = Woozle->new() ) && ref($lh);

print "# Make sure \$@ is localized...\n";
$@ = 'foo';
ok $lh && $lh->maketext('Eval error: [_1]', $@), "Eval error: foo";

print "# Byebye!\n";
ok 1;

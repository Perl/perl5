
require 5;
use Test;
# Time-stamp: "2004-03-30 17:51:06 AST"
BEGIN { plan tests => 9; }
use I18N::LangTags::Detect 1.01;
print "# Hi there...\n";
ok 1;

print "# Make sure we can assign to ENV entries\n",
      "# (Otherwise we can't run the subsequent tests)...\n";
$ENV{'MYORP'}   = 'Zing';          ok $ENV{'MYORP'}, 'Zing';
$ENV{'SWUZ'}   = 'KLORTHO HOOBOY'; ok $ENV{'SWUZ'}, 'KLORTHO HOOBOY';

delete $ENV{'MYORP'};
delete $ENV{'SWUZ'};

sub show { print "#  (Seeing [@_] at line ", (caller)[2], ")\n";  return @_ }

print "# Test LANG...\n";
$ENV{'REQUEST_METHOD'} = '';
$ENV{'LANG'}     = 'Eu_MT';
$ENV{'LANGUAGE'} = '';
ok show I18N::LangTags::Detect::detect();

print "# Test LANGUAGE...\n";
$ENV{'LANG'}     = '';
$ENV{'LANGUAGE'} = 'Eu-MT';
ok show I18N::LangTags::Detect::detect();


print "# Test HTTP_ACCEPT_LANGUAGE...\n";
$ENV{'REQUEST_METHOD'}       = 'GET';
$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'eu-MT';
ok show I18N::LangTags::Detect::detect();

$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'x-plorp, zaz, eu-MT, i-klung';
ok show I18N::LangTags::Detect::detect();

$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'x-plorp, zaz, eU-Mt, i-klung';
ok show I18N::LangTags::Detect::detect();



print "# Byebye!\n";
ok 1;


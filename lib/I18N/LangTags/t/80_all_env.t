
require 5;
use Test;
# Time-stamp: "2004-06-17 22:59:30 PDT"
BEGIN { plan tests => 14; }
use I18N::LangTags::Detect 1.01;
print "# Hi there...\n";
ok 1;

print "# Using I18N::LangTags::Detect v$I18N::LangTags::Detect::VERSION\n";

print "# Make sure we can assign to ENV entries\n",
      "# (Otherwise we can't run the subsequent tests)...\n";
$ENV{'MYORP'}   = 'Zing';          ok $ENV{'MYORP'}, 'Zing';
$ENV{'SWUZ'}   = 'KLORTHO HOOBOY'; ok $ENV{'SWUZ'}, 'KLORTHO HOOBOY';

delete $ENV{'MYORP'};
delete $ENV{'SWUZ'};

sub j { "[" . join(' ', map "\"$_\"", @_) . "]" ;}

sub show {
  print "#  (Seeing {", join(' ',
    map(qq{<$_>}, @_)), "} at line ", (caller)[2], ")\n";
  printenv();
  return $_[0] || '';
}
sub printenv {
  print "# ENV:\n";
  foreach my $k (sort keys %ENV) {
    my $p = $ENV{$k};  $p =~ s/\n/\n#/g;
    print "#   [$k] = [$p]\n"; }
  print "# [end of ENV]\n#\n";
}


print "# Test LANG...\n";
$ENV{'REQUEST_METHOD'} = '';
$ENV{'LANG'}     = 'Eu_MT';
$ENV{'LANGUAGE'} = '';
ok show( scalar I18N::LangTags::Detect::detect()),    "eu-mt";
ok show( j      I18N::LangTags::Detect::detect()), q{["eu-mt"]};

print "# Test LANGUAGE...\n";
$ENV{'LANG'}     = '';
$ENV{'LANGUAGE'} = 'Eu-MT';
ok show( scalar I18N::LangTags::Detect::detect()),    "eu-mt";
ok show( j      I18N::LangTags::Detect::detect()), q{["eu-mt"]};


print "# Test HTTP_ACCEPT_LANGUAGE...\n";
$ENV{'REQUEST_METHOD'}       = 'GET';
$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'eu-MT';
ok show( scalar I18N::LangTags::Detect::detect()),    "eu-mt";
ok show( j      I18N::LangTags::Detect::detect()), q{["eu-mt"]};


$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'x-plorp, zaz, eu-MT, i-klung';
ok show( scalar I18N::LangTags::Detect::detect()), "x-plorp";
ok show( j      I18N::LangTags::Detect::detect()), qq{["x-plorp" "i-plorp" "zaz" "eu-mt" "i-klung" "x-klung"]};

$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'x-plorp, zaz, eU-Mt, i-klung';
ok show( scalar I18N::LangTags::Detect::detect()), "x-plorp";
ok show( j      I18N::LangTags::Detect::detect()), qq{["x-plorp" "i-plorp" "zaz" "eu-mt" "i-klung" "x-klung"]};




print "# Byebye!\n";
ok 1;


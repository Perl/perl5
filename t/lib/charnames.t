#!./perl

BEGIN {
    unless(grep /blib/, @INC) {
	chdir 't' if -d 't';
	unshift @INC, '../lib' if -d '../lib';
    }
}

$| = 1;
print "1..5\n";

use charnames ':full';

print "not " unless "Here\C{EXCLAMATION MARK}?" eq 'Here!?';
print "ok 1\n";

print "# \$res=$res \$\@='$@'\nnot "
  if $res = eval <<'EOE'
use charnames ":full";
"Here: \C{CYRILLIC SMALL LETTER BE}!";
1
EOE
  or $@ !~ /above 0xFF/;
print "ok 2\n";
# print "# \$res=$res \$\@='$@'\n";

print "# \$res=$res \$\@='$@'\nnot "
  if $res = eval <<'EOE'
use charnames 'cyrillic';
"Here: \C{Be}!";
1
EOE
  or $@ !~ /CYRILLIC CAPITAL LETTER BE.*above 0xFF/;
print "ok 3\n";

# If octal representation of unicode char is \0xyzt, then the utf8 is \3xy\2zt
$encoded_be = "\320\261";
$encoded_alpha = "\316\261";
$encoded_bet = "\327\221";
{
  use charnames ':full';
  use utf8;

  print "not " unless "\C{CYRILLIC SMALL LETTER BE}" eq $encoded_be;
  print "ok 4\n";

  use charnames qw(cyrillic greek :short);

  print "not " unless "\C{be},\C{alpha},\C{hebrew:bet}" 
    eq "$encoded_be,$encoded_alpha,$encoded_bet";
  print "ok 5\n";
}

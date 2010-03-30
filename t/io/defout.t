#!./perl
#
# tests for default output handle

# DAPM 30/4/10 this area seems to have been undertested. For now, the only
# tests are ensuring things don't crash when PL_defoutgv isn't a GV;
# it probably needs expanding at some point to cover other stuff.

BEGIN {
    chdir 't';
    @INC = '../lib';
    require './test.pl';
}

plan tests => 16;


my $stderr = *STDERR;
select($stderr);
$stderr = 1; # whoops, PL_defoutgv no longer a GV!

# note that in the tests below, the return values aren't as important
# as the fact that they don't crash

ok !print(""), 'print';
ok !select(), 'select';
$a = 'fooo';
format STDERR =
#@<<
$a;
.
ok ! write(), 'write';

is($^, "",     '$^');
is($~, "",     '$~');
is($=, undef,  '$=');
is($-, undef,  '$-');
is($%, undef,  '$%');
is($|, 0,      '$|');
$^ = 1; pass '$^ = 1';
$~ = 1; pass '$~ = 1';
$= = 1; pass '$= = 1';
$- = 1; pass '$- = 1';
$% = 1; pass '$% = 1';
$| = 1; pass '$| = 1';
ok !close(), 'close';


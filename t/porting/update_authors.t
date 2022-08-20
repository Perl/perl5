#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    require "./test.pl";
    set_up_inc('../lib', '..');
}

use TestInit qw(T);    # T is chdir to the top level
use strict;

find_git_or_skip('all');

my $ok= do "./Porting/updateAUTHORS.pl";
my $error= !$ok && $@;
is($ok,1,"updateAUTHORS.pl compiles correctly");
is($error, "", "updateAUTHORS.pl compiles without error");
done_testing();
exit 0;

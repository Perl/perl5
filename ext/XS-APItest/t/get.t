
# Tests for the get_*v functions.

use Test::More tests => 3;
use XS::APItest;

# XXX So far we only test get_cv.

is get_cv("utf8::encode"), \&utf8::encode, 'get_cv(utf8::encode)';

sub foo { " ooof" } # should be stored in the stash as a subref
die "Test has been sabotaged: sub foo{} should not create a full glob"
    unless ref $::{foo} eq 'CODE';

my $subref = get_cv("foo");
is ref $subref, "CODE", 'got a coderef from get_cv("globless sub")';
is &$subref, " ooof", 'got the right sub';

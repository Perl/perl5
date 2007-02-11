#!perl -w

use Test::More tests => 1;

# bug #41442
use PerlIO::encoding;
use open ':locale';
if (-e '/dev/null') { open STDERR, '>', '/dev/null' }
warn "# \x{201e}\n"; # &bdquo;
ok(1); # we got that far

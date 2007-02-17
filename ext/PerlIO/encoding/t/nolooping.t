#!perl -w

use Test::More tests => 1;

BEGIN {
    $SIG{__WARN__} = sub { $warn .= $_[0] };
}

# bug #41442
use PerlIO::encoding;
use open ':locale';
if ($warn !~ /Cannot find encoding/) {
    if (-e '/dev/null') { open STDERR, '>', '/dev/null' }
    warn "# \x{201e}\n"; # &bdquo;
}
ok(1); # we got that far

print "1..4\n";

use strict;
use URI;

my $u = URI->new('rsync://gisle@perl.com/foo/bar');

print "not " unless $u->user eq "gisle";
print "ok 1\n";

print "not " unless $u->port eq 873;
print "ok 2\n";

print "not " unless $u->path eq "/foo/bar";
print "ok 3\n";

$u->port(8730);

print "not " unless $u eq 'rsync://gisle@perl.com:8730/foo/bar';
print "ok 4\n";


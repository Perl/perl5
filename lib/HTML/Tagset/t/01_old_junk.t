
# Time-stamp: "2004-12-29 18:49:45 AST"

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use HTML::Tagset;
$loaded = 1;
print "ok 1\n";

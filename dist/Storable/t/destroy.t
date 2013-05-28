# [perl #118139] crash in global destruction when accessing an
# already freed PL_modglobal or accessing the freed cxt.
use Test;
use Storable;
BEGIN {
  plan tests => 1;
  store {}, "foo";
}
package foo;
sub new { return bless {} }
DESTROY {
  open $fh, "<", "foo";
  eval { Storable::pretrieve($fh); };
  unlink "foo";
}

package main;
# print "# $^X\n";
$x = foo->new();

ok(1);

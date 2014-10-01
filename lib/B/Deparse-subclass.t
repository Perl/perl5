#!./perl

# These tests are not necessarily normative, but until such time as we
# publicise an API for subclassing B::Deparse they can prevent us from
# gratuitously breaking conventions that CPAN modules already use.

use Test::More tests => 1;

use B::Deparse;

package B::Deparse::NameMangler {
  @ISA = "B::Deparse";
  sub padname { SUPER::padname{@_} . '_groovy' }
}

like 'B::Deparse::NameMangler'->new->coderef2text(sub { my($a, $b, $c) }),
      qr/\$a_groovy, \$b_groovy, \$c_groovy/,
     'overriding padname works for renaming lexicals';

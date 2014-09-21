BEGIN {
    chdir 't';
    require './test.pl';
    set_up_inc("../lib");
}

plan 15;

$::TODO = ' ';

eval '\$x = \$y';
like $@, qr/^Experimental lvalue references not enabled/,
    'error when feature is disabled';

use feature 'lvalue_refs';

{
    my($w,$c);
    local $SIG{__WARN__} = sub { $c++; $w = shift };
    eval '\$x = \$y';
    is $c, 1, 'one warning from lv ref assignment';
    like $w, qr/^Lvalue references are experimental/,
        'experimental warning';
}

no warnings 'experimental::lvalue_refs';

# Scalars

eval '\$x = \$y';
is \$x, \$y, '\$pkg_scalar = ...';
my $m;
eval '\$m = \$y';
is \$m, \$y, '\$lexical = ...';
eval '\my $n = \$y';
is \$n, \$y, '\my $lexical = ...';
@_ = \$_;
eval '\($x) = @_';
is \$x, \$_, '\($pkgvar) = ... gives list context';
my $o;
eval '\($o) = @_';
is \$o, \$_, '\($lexical) = ... gives list cx';
eval '\(my $p) = @_';
is \$p, \$_, '\(my $lexical) = ... gives list cx';
eval '\($_a, my $a) = @{[\$b, \$c]}';
is \$_a, \$b, 'package scalar in \(...)';
is \$a, \$c, 'lex scalar in \(...)';
eval '(\$_b, \my $b) = @{[\$b, \$c]}';
is \$_b, \$::b, 'package scalar in (\$foo, \$bar)';
is \$b, \$c, 'lex scalar in (\$foo, \$bar)';

# Array Elements

# ...

# Hash Elements

# ...

# Arrays

# ...

# Hashes

# ...

# Subroutines

# ...

# Mixed List Assignments

# ...

# Errors

# ...

# Miscellaneous

{
  my($x,$y);
  sub {
    sub {
      \$x = \$y;
    }->();
    is \$x, \$y, 'lexical alias affects outer closure';
  }->();
  is \$x, \$y, 'lexical alias affects outer sub where vars are declared';
}

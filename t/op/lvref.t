BEGIN {
    chdir 't';
    require './test.pl';
    set_up_inc("../lib");
}

plan 22;

sub on { $::TODO = ' ' }
sub off{ $::TODO = ''  }

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
\$m = \$y;
is \$m, \$y, '\$lexical = ...';
on;
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
is eval '\local $l = \3; $l', 3, '\local $scalar assignment';
off;
is $l, undef, 'localisation unwound';
on;

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

off;
eval { my $x; \$x = 3 };
like $@, qr/^Assigned value is not a reference at/, 'assigning non-ref';
eval { my $x; \$x = [] };
like $@, qr/^Assigned value is not a SCALAR reference at/,
    'assigning non-scalar ref to scalar ref';
eval { \$::x = [] };
like $@, qr/^Assigned value is not a SCALAR reference at/,
    'assigning non-scalar ref to package scalar ref';
on;

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

{ # PADSTALE has a double meaning
  use feature 'lexical_subs', 'signatures', 'state';
  no warnings 'experimental';
  my $c;
  my sub s ($arg) {
    state $x = ++$c;
    if ($arg == 3) { return $c }
    goto skip if $arg == 2;
    my $y;
   skip:
    # $y is PADSTALE the 2nd time
    \$x = \$y if $arg == 2;
  }
  s(1);
  s(2);
  is s(3), 1, 'padstale alias should not reset state'
}

off;
SKIP: {
    skip_without_dynamic_extension('List/Util');
    require Scalar::Util;
    my $a;
    Scalar::Util::weaken($r = \$a);
    \$a = $r;
    pass 'no crash when assigning \$lex = $weakref_to_lex'
}

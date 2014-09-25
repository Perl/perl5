BEGIN {
    chdir 't';
    require './test.pl';
    set_up_inc("../lib");
}

plan 44;

sub on { $::TODO = ' ' }
sub off{ $::TODO = ''  }

eval '\$x = \$y';
like $@, qr/^Experimental lvalue references not enabled/,
    'error when feature is disabled';
eval '\($x) = \$y';
like $@, qr/^Experimental lvalue references not enabled/,
    'error when feature is disabled (aassign)';

use feature 'lvalue_refs';

{
    my($w,$c);
    local $SIG{__WARN__} = sub { $c++; $w = shift };
    eval '\$x = \$y';
    is $c, 1, 'one warning from lv ref assignment';
    like $w, qr/^Lvalue references are experimental/,
        'experimental warning';
    undef $c;
    eval '\($x) = \$y';
    is $c, 1, 'one warning from lv ref list assignment';
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
\my $n = \$y;
is \$n, \$y, '\my $lexical = ...';
@_ = \$_;
\($x) = @_;
is \$x, \$_, '\($pkgvar) = ... gives list context';
undef *x;
(\$x) = @_;
is \$x, \$_, '(\$pkgvar) = ... gives list context';
my $o;
\($o) = @_;
is \$o, \$_, '\($lexical) = ... gives list cx';
my $q;
(\$q) = @_;
is \$q, \$_, '(\$lexical) = ... gives list cx';
\(my $p) = @_;
is \$p, \$_, '\(my $lexical) = ... gives list cx';
(\my $r) = @_;
is \$r, \$_, '(\my $lexical) = ... gives list cx';
\my($s) = @_;
is \$s, \$_, '\my($lexical) = ... gives list cx';
\($_a, my $a) = @{[\$b, \$c]};
is \$_a, \$b, 'package scalar in \(...)';
is \$a, \$c, 'lex scalar in \(...)';
(\$_b, \my $b) = @{[\$b, \$c]};
is \$_b, \$::b, 'package scalar in (\$foo, \$bar)';
is \$b, \$c, 'lex scalar in (\$foo, \$bar)';
is do { \local $l = \3; $l }, 3, '\local $scalar assignment';
is $l, undef, 'localisation unwound';
is do { \(local $l) = \4; $l }, 4, '\(local $scalar) assignment';
is $l, undef, 'localisation unwound';
\$foo = \*bar;
is *foo{SCALAR}, *bar{GLOB}, 'globref-to-scalarref assignment';
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

off;
(\$tahi, $rua) = \(1,2);
is join(' ', $tahi, $$rua), '1 2',
  'mixed scalar ref and scalar list assignment';
on;

# Conditional expressions

$_ = 3;
eval '$_ == 3 ? \$tahi : $rua = \3';
is $tahi, 3, 'cond assignment resolving to scalar ref';
eval '$_ == 3 ? \$toru : $wha = \3';
is $$wha, 3, 'cond assignment resolving to scalar';
eval '$_ == 3 ? \$rima : \$ono = \5';
is $$rima, 5, 'cond assignment with refgens on both branches';

# Foreach

eval '
  for \my $a(\$for1, \$for2) {
    push @for, \$a;
  }
';
is "@for", \$for1 . ' ' . \$for2, 'foreach \my $a';

@for = ();
eval '
  for \my @a([1,2], [3,4]) {
    push @for, @a;
  }
';
is "@for", "1 2 3 4", 'foreach \my @a [perl #22335]';

@for = ();
eval '
  for \my %a({5,6}, {7,8}) {
    push @for, %a;
  }
';
is "@for", "5 6 7 8", 'foreach \my %a [perl #22335]';

@for = ();
eval '
  for \my &a(sub {9}, sub {10}) {
    push @for, &a;
  }
';
is "@for", "9 10", 'foreach \my &a';


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
eval '(\do{}) = 42';
like $@, qr/^Can't modify reference to do block in list assignment at /,
    "Can't modify reference to do block in list assignment";
off;
eval '(\pos) = 42';
like $@,
     qr/^Can't modify reference to match position in list assignment at /,
    "Can't modify ref to some scalar-returning op in list assignment";
eval '(\glob) = 42';
like $@,
     qr/^Can't modify reference to glob in list assignment at /,
    "Can't modify reference to some list-returning op in list assignment";
eval '\pos = 42';
like $@,
    qr/^Can't modify reference to match position in scalar assignment at /,
   "Can't modify ref to some scalar-returning op in scalar assignment";
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

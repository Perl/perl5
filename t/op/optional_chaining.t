#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

use feature 'optional_chaining';
no warnings 'experimental::optional_chaining';

plan 66;

# ---------------------------------------------------------------------------
# Hash dereference  $h?->{key}
# ---------------------------------------------------------------------------

{
    my $u = undef;
    my $h = { a => 1, b => 0, c => '' };

    is($u?->{a},        undef, 'hash: undef lhs gives undef');
    is($h?->{a},        1,     'hash: defined lhs gives value');
    is($h?->{b},        0,     'hash: defined lhs, value 0');
    is($h?->{c},        '',    'hash: defined lhs, value empty string');
    is($h?->{missing},  undef, 'hash: missing key gives undef');
}

# ---------------------------------------------------------------------------
# Array dereference  $a?->[idx]
# ---------------------------------------------------------------------------

{
    my $u    = undef;
    my $aref = [10, 20, 30];

    is($u?->[0],    undef, 'array: undef lhs gives undef');
    is($aref?->[0], 10,    'array: first element');
    is($aref?->[2], 30,    'array: last element');
    is($aref?->[9], undef, 'array: out-of-bounds gives undef');
}

# ---------------------------------------------------------------------------
# Coderef call  $sub?->()  and  $sub?->(args)
# ---------------------------------------------------------------------------

{
    my $u   = undef;
    my $sub = sub { 42 };
    my $add = sub { $_[0] + $_[1] };

    is($u?->(),       undef, 'coderef: undef lhs no-args gives undef');
    is($sub?->(),     42,    'coderef: defined lhs no-args');
    is($u?->(1, 2),   undef, 'coderef: undef lhs with args gives undef');
    is($add?->(3, 4), 7,     'coderef: defined lhs with args');
}

# ---------------------------------------------------------------------------
# Method calls  $obj?->method  and  $obj?->method(args)
# ---------------------------------------------------------------------------

{
    package Counter {
        sub new   { bless { n => 0 }, shift }
        sub inc   { $_[0]{n} += ($_[1] // 1); $_[0] }
        sub value { $_[0]{n} }
    }

    my $u   = undef;
    my $obj = Counter->new;

    is($u?->value,   undef, 'method: undef lhs gives undef');
    is($obj?->value, 0,     'method: defined lhs, no args');
    $obj?->inc(5);
    is($obj?->value, 5,     'method: defined lhs with args');
    is($u?->inc(1),  undef, 'method: undef lhs with args gives undef');
    is($obj?->value, 5,     'method: undef call did not mutate object');
}

# ---------------------------------------------------------------------------
# Class methods (use feature 'class') -- method keyword
# ---------------------------------------------------------------------------

{
    use feature 'class';
    no warnings 'experimental::class';

    class Point {
        field $x :param;
        field $y :param;
        method x { $x }
        method coords { "$x,$y" }
    }

    my $p = Point->new(x => 3, y => 4);
    my $u = undef;

    is($p?->x,       3,     'class method: defined lhs gives value');
    is($u?->x,       undef, 'class method: undef lhs gives undef');
    is($p?->coords,  '3,4', 'class method: defined lhs with field interpolation');
}

# ---------------------------------------------------------------------------
# Lexical method invocation ?->&  (use feature 'class', my method)
# my method is only in scope inside the class block, so ?->& can only
# appear inside a method body — tested here via a public wrapper method.
# ---------------------------------------------------------------------------

{
    use feature 'class';
    no warnings 'experimental::class';

    class LexMeth {
        field $x :param;
        my method get_x { $x }
        # call_get_x uses ?->& on its argument — a maybe-undef LexMeth instance
        method call_get_x {
            my $maybe = $_[0];
            $maybe?->&get_x   # <-- the ?->& under test
        }
    }

    my $a = LexMeth->new(x => 7);
    my $b = LexMeth->new(x => 99);

    is($a->call_get_x($b),    99,    'lexical method ?->&: defined lhs calls my method');
    is($a->call_get_x(undef), undef, 'lexical method ?->&: undef lhs short-circuits');
}

# ---------------------------------------------------------------------------
# Scalar context: undef lhs produces undef
# ---------------------------------------------------------------------------

{
    my $u = undef;
    my $h = { x => 99 };

    my $r1 = $u?->{x};
    is($r1, undef, 'scalar context: undef lhs assigns undef');

    my $r2 = $h?->{x};
    is($r2, 99, 'scalar context: defined lhs assigns value');
}

# ---------------------------------------------------------------------------
# Short-circuit: args/subscripts not evaluated when lhs is undef
# ---------------------------------------------------------------------------

{
    my $u = undef;
    my $i = 0;

    $u?->{$i++};
    is($i, 0, 'short-circuit: hash subscript not evaluated when undef');

    $u?->[$i++];
    is($i, 0, 'short-circuit: array subscript not evaluated when undef');

    $u?->($i++);
    is($i, 0, 'short-circuit: coderef arg not evaluated when undef');

    $u?->somemethod($i++);
    is($i, 0, 'short-circuit: method arg not evaluated when undef');
}

# ---------------------------------------------------------------------------
# No autovivification
# ---------------------------------------------------------------------------

{
    my %h;
    my $r = $h{missing}?->{key};
    ok(!exists $h{missing}, 'no autoviv: hash element not created');

    my @a;
    $r = $a[0]?->{key};
    ok(!defined $a[0], 'no autoviv: array element not created');
}

# ---------------------------------------------------------------------------
# Chained  $a?->{b}?->{c}
# ---------------------------------------------------------------------------

{
    my $u       = undef;
    my $deep    = { b => { c => 42 } };
    my $shallow = { b => undef };

    is($u?->{b}?->{c},       undef, 'chain: undef root short-circuits');
    is($shallow?->{b}?->{c}, undef, 'chain: undef mid-chain short-circuits');
    is($deep?->{b}?->{c},    42,    'chain: all defined gives value');
}

# ---------------------------------------------------------------------------
# Chained method calls
# ---------------------------------------------------------------------------

{
    package Node {
        sub new  { bless { val => $_[1], next => $_[2] }, $_[0] }
        sub next { $_[0]{next} }
        sub val  { $_[0]{val}  }
    }

    my $list = Node->new(1, Node->new(2, Node->new(3, undef)));

    is($list?->next?->val,               2,     'chain: two-deep method chain');
    is($list?->next?->next?->val,        3,     'chain: three-deep method chain');
    is($list?->next?->next?->next?->val, undef, 'chain: past end is undef');
}

# ---------------------------------------------------------------------------
# Chained short-circuit side-effect count
# ---------------------------------------------------------------------------

{
    my $i = 0;
    my $u = undef;
    my $x = {};

    $u?->{$i++}?->[$i++];
    is($i, 0, 'chain short-circuit: neither subscript evaluated when root undef');

    $x?->{$i++}?->[$i++];
    is($i, 1, 'chain short-circuit: first subscript evaluated, second not');
}

# ---------------------------------------------------------------------------
# Mixed hash/array chain
# ---------------------------------------------------------------------------

{
    my $data = { list => [1, 2, 3] };
    my $u    = undef;

    is($data?->{list}?->[1], 2,     'mixed chain: hash then array');
    is($u?->{list}?->[1],    undef, 'mixed chain: undef root');
}

# ---------------------------------------------------------------------------
# Feature guard: ?-> without feature is a syntax error
# ---------------------------------------------------------------------------

{
    my $code = 'no feature "optional_chaining"; my $x = undef; $x?->{a};';
    eval $code;
    like($@, qr/syntax error/i, 'feature guard: ?-> without feature is a syntax error');
}

# ---------------------------------------------------------------------------
# Experimental warning is issued (needs a fresh process: it's a compile-time
# warning and lexical warning state bleeds into eval-string scopes)
# ---------------------------------------------------------------------------

fresh_perl_like(
    'use warnings; use feature "optional_chaining"; my $x; $x?->{a}',
    qr/optional chaining is experimental/,
    { stderr => 1 },
    'experimental warning is issued under use warnings',
);

# ---------------------------------------------------------------------------
# map { }  — was crashing in S_aassign_scan (peephole optimizer) because
# rv2hv/rv2av had op_first detached by newOPTARROWOP, causing a null deref
# ---------------------------------------------------------------------------

{
    my @data = ({v => 1}, undef, {v => 3});

    my @r = map { $_?->{v} } @data;
    is(scalar @r, 3, 'map ?->hash: result has correct length');
    is($r[0], 1,     'map ?->hash: first element defined');
    is($r[1], undef, 'map ?->hash: undef element gives undef');
    is($r[2], 3,     'map ?->hash: last element defined');

    my @a = ([10, 20], undef, [30, 40]);
    my @s = map { $_?->[0] } @a;
    is($s[0], 10,    'map ?->array: first element');
    is($s[1], undef, 'map ?->array: undef element gives undef');
}

# ---------------------------------------------------------------------------
# lvalue: $h?->{k} = 42
# ---------------------------------------------------------------------------

{
    my $h = {};
    $h?->{x} = 42;
    is($h->{x}, 42,  'lvalue: assign to hash element via ?->');

    my $u = undef;
    $u?->{x} = 99;
    is($u, undef,    'lvalue: assign via undef ?-> leaves lhs unchanged');

    my $a = [];
    $a?->[0] = 99;
    is($a->[0], 99,  'lvalue: assign to array element via ?->');
}

# ---------------------------------------------------------------------------
# postfix dereference: $ref?->@*  $ref?->%*
# ---------------------------------------------------------------------------

{
    my $aref = [1, 2, 3];
    my @vals = $aref?->@*;
    is(scalar @vals,  3,  'postfix deref: $aref?->@* correct length');
    is("@vals", "1 2 3",  'postfix deref: $aref?->@* correct values');

    my $u = undef;
    my @empty = $u?->@*;
    is(scalar @empty, 0,  'postfix deref: undef?->@* gives empty list');

    my $href = {a => 1};
    my %h = $href?->%*;
    is($h{a}, 1,          'postfix deref: $href?->%* defined');

    my %hempty = $u?->%*;
    is(scalar keys %hempty, 0, 'postfix deref: undef?->%* gives empty hash');
}

# ---------------------------------------------------------------------------
# non-padsv coderef LHS with arguments: $obj->get_sub()?->(args)
# ---------------------------------------------------------------------------

{
    package SubHolder {
        sub new     { bless { sub => sub { $_[0] + $_[1] } }, shift }
        sub get_sub { $_[0]->{sub} }
    }

    my $obj  = SubHolder->new;
    my $uobj = undef;

    my $result = $obj->get_sub()?->(3, 4);
    is($result, 7,   'non-padsv coderef with args: correct result');

    my $r2 = $uobj?->get_sub()?->(3, 4);
    is($r2, undef,   'non-padsv coderef with args: undef short-circuits');
}

# ---------------------------------------------------------------------------
# list assignment (aassign): undef ?-> must not swallow other assignments
# Bug: rpp_popfree_2_NN in the OPpOPTARROW_LVALUE path was called with the
# sassign stack layout (pop 2: undef-LHS + RHS), but aassign has a different
# stack layout.  When the LHS was undef, the pop consumed a RHS value, leaving
# sibling lvalues in the list unassigned.
# ---------------------------------------------------------------------------

{
    # undef LHS: ?-> slot skipped; other lvalues in the list must still be assigned
    my $u = undef;
    my $other = 'before';
    ($u?->{k}, $other) = (99, 'after');
    is($u,     undef,   'aassign: undef ?-> lhs stays undef');
    is($other, 'after', 'aassign: sibling lvalue still assigned when ?-> lhs is undef');

    # defined LHS: normal assignment must still work
    my $h = {};
    my $other2 = 'before';
    ($h?->{k}, $other2) = (99, 'after');
    is($h->{k}, 99,      'aassign: defined ?-> lhs assigned');
    is($other2, 'after', 'aassign: sibling lvalue assigned when ?-> lhs is defined');

    # multiple items after the undef ?->
    my $u2 = undef;
    my ($a, $b) = ('a', 'b');
    ($u2?->{k}, $a, $b) = (1, 2, 3);
    is($a, 2, 'aassign: first sibling after undef ?-> assigned');
    is($b, 3, 'aassign: second sibling after undef ?-> assigned');
}

# ---------------------------------------------------------------------------
# Structural invariant: no two distinct ops in a compiled sub may share the
# same anonymous PADTMP slot as op_targ.  op_clear calls pad_free(op_targ)
# for every op with op_targ > 0, so shared ownership causes a double-free.
#
# Named lexicals (PADMYs) are legitimately referenced from multiple ops and
# are excluded.  op_targ values >= padsize are nulled-op type tags, not pad
# slot offsets, and are also excluded.
#
# Tested across several op patterns; the ?-> pad-ferry case (non-padsv coderef
# LHS) was the specific bug that motivated this test.
# ---------------------------------------------------------------------------

SKIP: {
    eval { require B } or skip("B not available", 1);

    # Helper: return the number of anonymous PADTMP slots shared between two
    # or more distinct ops in the given sub reference.
    sub _count_shared_padtmps {
        my $subref  = shift;
        my $cv      = B::svref_2object($subref);
        my @pnames  = $cv->PADLIST->ARRAY;
        my @names   = $pnames[0]->ARRAY;
        my $padsize = scalar @names;

        # Ops that use op_targ as a refcount (OPpREFCOUNTED), not a pad
        # slot offset.  Perl_op_refcnt_dec() stores the refcount in op_targ
        # for leavesub and similar scope-exit ops, so a value of 1 or 2 here
        # does NOT mean "pad slot 1 or 2" — exclude them from the check.
        my %refcount_ops = map { $_ => 1 }
            qw(leavesub leavesublv leaveeval leave scope leavewrite);

        my %owners;
        my $walk; $walk = sub {
            my $op = shift;
            return unless ref $op && $op->can('name') && $$op;
            my $t = $op->targ;
            if ($t > 0 && $t < $padsize && !$refcount_ops{$op->name}) {
                my $pn = $names[$t];
                unless (ref($pn) && $pn->can('PVX') && defined $pn->PVX) {
                    push @{ $owners{$t} }, sprintf('%s(0x%x)', $op->name, $$op);
                }
            }
            $walk->($op->other)   if $op->isa('B::LOGOP') && ${$op->other};
            $walk->($op->first)   if $op->can('first')    && ${$op->first};
            $walk->($op->sibling) if $op->can('sibling')  && ${$op->sibling};
        };
        $walk->($cv->ROOT);

        my $shared = 0;
        for my $t (keys %owners) {
            my %seen;
            my @uniq = grep { !$seen{$_}++ } @{ $owners{$t} };
            $shared++ if @uniq > 1;
        }
        return $shared;
    }

    package PadFerryCheck {
        sub new   { bless {}, shift }
        sub get_f { sub { $_[0] + $_[1] } }
    }

    # Several op patterns that allocate PADTMPs — none should share a slot
    my @cases = (
        ['simple arithmetic',
            sub { my $x = 1 + 2; $x }],
        ['chained plain ->',
            sub { PadFerryCheck->new->get_f()->(1,2) }],
        ['?-> hash/array (padsv lhs)',
            sub { my $h = {k=>1}; $h?->{k} }],
        ['?-> coderef padsv lhs',
            sub { my $f = sub{42}; $f?->() }],
        ['?-> non-padsv coderef lhs (pad-ferry)',
            sub { my $o = PadFerryCheck->new; $o->get_f()?->(3,4) }],
    );

    my $total_shared = 0;
    for my $case (@cases) {
        my ($label, $code) = @$case;
        $total_shared += _count_shared_padtmps($code);
    }
    is($total_shared, 0,
        'no anonymous PADTMP slot is owned by two distinct ops (double-free invariant)');
}

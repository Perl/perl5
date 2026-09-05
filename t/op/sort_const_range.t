#!./perl
# Tests for GH #19790 and GH #16865:
# sort with a block comparator whose arg list contains a range whose
# right endpoint is a non-numeric string constant (e.g. 0.."r").
#
# Root cause: S_gen_constant_list() calls CALL_PEEP() internally, which
# sets op_opt=1 on the flip-flop ops.  When CALLRUNOPS dies (the "isn't
# numeric" warning is fatal inside gen_constant_list), the failure path
# (case 3) used to restore o->op_next without resetting op_opt.  That
# left the main rpeep() unable to reach case OP_SORT, so null_wrap->op_next
# (= PL_sortcop) was left pointing into the sort's argument list instead of
# the comparator block, causing S_sortcv to re-execute the argument list
# recursively and exhaust the MARK stack.
#
# NOTE: these tests must NOT use "no warnings 'numeric'" around the sort
# expressions.  That pragma works via cop_warnings which gen_constant_list
# inherits when it copies the current COP.  Suppressing the numeric warning
# at compile time prevents gen_constant_list from hitting case 3 (the
# failure path), so the bug is never triggered and the test becomes a
# false positive on unpatched perls.
#
# Refs: GH #19790, GH #16865, GH #16033

use strict;
use warnings;

require './test.pl';

my $libdir = -d 'lib' ? 'lib' : '../lib';

# stderr=>1 so warnings in subprocess output are captured but don't
# interfere with the TAP stream; we only care about exit status.
# -w is passed explicitly so that cop_warnings==pWARN_STD in the subprocess
# falls back to PL_dowarn & G_WARN_ON, letting gen_constant_list's internal
# CALLRUNOPS (which forces PL_dowarn |= G_WARN_ON) hit the WARN_NUMERIC
# warning for "r" and reach case 3 — the code path this test exercises.
# Without -w the test still works in practice (gen_constant_list forces
# PL_dowarn itself), but -w makes the dependency explicit and safe.
my $run_args = { switches => ["-I$libdir", "-w"], stderr => 1 };

# ---------------------------------------------------------------------------
# 1-8: crash-safety tests via fresh_perl.
#
# On unpatched perl the process crashes (MARK stack underflow) so exit != 0.
# On patched perl the sort runs to completion and exits cleanly.
#
# We do NOT use "no warnings" in the snippets: the numeric warning for "r"
# must reach gen_constant_list's PERL_WARNHOOK_FATAL so that case 3 is
# triggered, which is exactly the code path the fix addresses.
# ---------------------------------------------------------------------------

my $out;

# 1-2: GH #16865 minimal reproducer
$out = fresh_perl('\(sort {0} 0, 0 .. "r")', $run_args);
is($?,  0, 'GH #16865 minimal: clean exit');
unlike($out, qr/MARK underflow/, 'GH #16865 minimal: no MARK underflow panic');

# 3: list context (no outer reference)
$out = fresh_perl('my @x = sort {0} 0, 0 .. "r"', $run_args);
is($?, 0, 'GH #19790 list-context: clean exit');

# 4: nested sort (the fuzz variant from GH #19790)
$out = fresh_perl(
    'my @x = \(sort {0} 0, 0 .. "r", sort {0} 1, 2)',
    $run_args
);
is($?, 0, 'GH #19790 nested sort: clean exit');

# 5: repeated invocations — no state corruption between calls
$out = fresh_perl(
    'for (1..5) { \(sort {0} 0, 0 .. "r") }',
    $run_args
);
is($?, 0, 'repeated invocations: clean exit');

# 6: double-nested, both sorts have non-numeric range args
$out = fresh_perl(
    '\(sort { \(sort {0} 0, 0 .. "z") } 0, 0 .. "r")',
    $run_args
);
is($?, 0, 'double-nested sort with range args: clean exit');

# 7-8: GH #16033 variant — assertion failure / MARK underflow via flip-flop
$out = fresh_perl('\(sort {0} 0 .. "r")', $run_args);
is($?, 0, 'GH #16033 sort {0} 0.."r" only: clean exit');

$out = fresh_perl('sort { $a cmp $b } 0 .. "r"', $run_args);
is($?, 0, 'sort with cmp comparator and range arg: clean exit');

# ---------------------------------------------------------------------------
# 9-10: correctness oracle — run in-process (compilation happens here,
# so no "no warnings 'numeric'" must be active around the sort expression).
#
# Key invariant: if PL_sortcop is wrong, S_sortcv executes the argument
# list instead of the comparator.  The comparator is never called, and
# $cmp_called stays 0.  Either that, or the process crashes before
# reaching the ok() call.
# ---------------------------------------------------------------------------

{
    # Suppress only the runtime "isn't numeric" warning that pp_flop
    # emits when it evaluates 0.."r" at run time.  We use a local
    # override of $SIG{__WARN__} rather than "no warnings 'numeric'"
    # to avoid touching cop_warnings and accidentally masking the
    # compile-time warning that drives gen_constant_list into case 3.
    local $SIG{__WARN__} = sub {};

    my $cmp_called = 0;
    my @sorted = sort { $cmp_called++; $a <=> $b } 5, 0 .. "r";
    ok($cmp_called > 0, 'comparator block was actually called (not arg list)');
    is("@sorted", "0 5",  'sort result is correct');
}

done_testing();

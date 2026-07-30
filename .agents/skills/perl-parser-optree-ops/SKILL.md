---
name: perl-parser-optree-ops
description: "Use when changing Perl parser, lexer, optrees, ops, pp functions, check functions, pads, scopes, toke.c, perly.y, op.c, pp*.c, or opcode regen."
---

# Perl Parser, Optree, and Ops

Separate syntax parsing, op construction, check-time behavior, and run-time pp behavior before editing. Parser and opcode changes often require generated files and B tests.

## Workflow

1. Locate whether the behavior belongs to tokenization, grammar, op creation, checking, optimization, scope/pad handling, or pp execution.
2. Read nearby tests and `pod/perlinterp.pod` before changing op shape or stack behavior.
3. Edit generator inputs such as `perly.y` or `regen/opcodes` instead of generated outputs.
4. Regenerate with the narrowest make target and inspect generated diffs.
5. Run focused `t/comp`, `t/op`, `ext/B`, and XS/API tests as appropriate.

Read [references/parser-optree-ops.md](references/parser-optree-ops.md) for source maps, regen targets, tests, and searches.

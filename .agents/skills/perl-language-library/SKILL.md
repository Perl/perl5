---
name: perl-language-library
description: "Use when changing Perl language behavior, builtins, pragmata, diagnostics, core modules, dual-life modules, portability policy, deprecations, or user-visible library behavior."
---

# Perl Language and Library

User-visible changes need tests, docs, policy awareness, and often perldelta notes. For core modules, check whether the module is maintained in core or imported from CPAN.

## Workflow

1. Identify whether the change is language syntax/semantics, builtin behavior, diagnostics, pragma behavior, or module/library behavior.
2. Find the owning tests and docs before editing.
3. Check dual-life ownership for modules under `dist/` and `cpan/`.
4. Update docs and perldelta for user-visible changes.

Read [references/language-library.md](references/language-library.md) for docs, ownership checks, and tests.

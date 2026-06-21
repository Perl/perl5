---
name: perl-xs-embedding
description: "Use when working on XS, embedding Perl, typemaps, PerlIO/API usage, extension-facing compatibility, or behavior visible to XS authors."
---

# Perl XS and Embedding

Separate public API guarantees from core-internal convenience. XS authors should be pointed to documented APIs, not incidental core symbols.

## Workflow

1. Check whether the change affects XS authors, embedded interpreters, or only core internals.
2. Prefer documented `perlapi` functions and existing XS examples.
3. If symbol exposure changes, use `perl-embed-fnc`.
4. Add tests in existing XS/API test locations when behavior is extension-facing.

Read [references/xs-embedding.md](references/xs-embedding.md) for docs, files, and validation.

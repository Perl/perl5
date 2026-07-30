---
name: perl-core-hacking
description: "Use when changing Perl core internals in C or headers, assessing public/internal API boundaries, touching generated files, or preparing a safe Perl core patch."
---

# Perl Core Hacking

Treat core changes as compatibility-sensitive. Read existing code and tests first, then choose the smallest change consistent with established local patterns.

## Workflow

1. Locate the subsystem and nearby tests with `rg`.
2. Check whether public API, binary compatibility, or generated files are involved.
3. Prefer existing macros, allocation helpers, refcount patterns, and error paths.
4. Update docs, `pod/perldelta.pod`, or generated sources when the behavior or API changes.
5. Run targeted tests before broad tests.

Read [references/core-change-workflow.md](references/core-change-workflow.md) for internals sources, risk checks, and validation patterns.

## Boundaries

- Use `perl-sv-magic-memory` for SV/AV/HV/CV, refcounts, mortals, magic, save stack, arenas, or ownership changes.
- Use `perl-parser-optree-ops` for parser, lexer, optree, pad, scope, opcode, check-function, or pp-function changes.
- Use `perl-regex-engine` for regex compiler/executor/optimizer changes.
- Use `perl-core-portability` for EBCDIC, locale, threads, multiplicity, platform, and C portability concerns.
- Use `perl-generated-files` for generated-file mapping, regeneration, and validation.
- Use `perl-configure-build-system` for Configure, config headers, makefile, hints, cross-build, and platform build changes.
- Use `perl-core-archaeology` when the task is to explain why, when, or how a behavior or implementation changed.
- Use `perl-embed-fnc` for `embed.fnc`, generated prototypes, API docs, and symbol visibility.
- Use `perl-xs-embedding` when the change affects XS authors or embedding API users.

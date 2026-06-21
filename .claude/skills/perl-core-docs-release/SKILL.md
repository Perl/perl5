---
name: perl-core-docs-release
description: "Use when editing Perl core POD, perldelta, release notes, Porting release workflows, MANIFEST, maintainer metadata, or documentation style."
---

# Perl Core Docs and Release

Documentation changes in core are often tied to tests, release notes, generated indexes, and distribution metadata. Keep user-visible behavior, internals docs, and release notes consistent.

## Workflow

1. Identify whether the change is user-facing, internals-facing, release-process, or generated docs.
2. Follow local POD style and existing section structure.
3. Update `pod/perldelta.pod` when required by `pod/perlhack.pod` and release guidance.
4. Run relevant porting/docs tests.

Read [references/docs-release.md](references/docs-release.md) for canonical docs and validation.

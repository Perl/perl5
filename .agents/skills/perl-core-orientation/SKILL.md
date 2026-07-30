---
name: perl-core-orientation
description: "Use when orienting inside the Perl core repository, finding the right source/docs/tests/tools, mapping subsystems, or deciding where a Perl core change belongs."
---

# Perl Core Orientation

Start by locating the change in the source tree before proposing edits. Prefer repo truth over memory: use `rg`, `rg --files`, nearby docs, and existing tests.

## Workflow

1. Read the files closest to the requested behavior, then read the owning docs.
2. Check whether generated files are involved before editing headers, POD indexes, or tables.
3. Identify the narrowest relevant tests before broad test runs.
4. When historical comments or old compatibility decisions are unclear, ask for project context before changing behavior.

## Source Map

Read [references/source-map.md](references/source-map.md) when you need the repository layout, canonical docs, or search patterns.

Use `perl-core-archaeology` when orientation depends on historical rationale, commit lineage, old behavior, mailing-list context, or release provenance.

## Common Entry Points

- `README`, `INSTALL`, `Configure`, `Makefile.SH`: build and project overview.
- `pod/perlsource.pod`: source tree orientation.
- `pod/perlhack.pod`: contributor workflow and testing.
- `Porting/README.pod`: porting and release helper scripts.
- `MANIFEST`: distribution membership.
- `AUTHORS`, `Porting/updateAUTHORS.*`: contributor identity data.

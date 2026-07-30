---
name: perl-embed-fnc
description: "Use when editing embed.fnc, adding Perl core C functions to generated prototypes, changing public/internal API documentation, adjusting symbol visibility, or debugging proto.h/embed.h/perlapi/perlintern generation."
---

# Perl embed.fnc

`embed.fnc` is the source of truth for many generated prototypes, short-name macros, args assertions, API docs, and export decisions. Treat `A` public API entries as compatibility commitments.

## Workflow

1. Read the relevant `embed.fnc` header comments and nearby entries.
2. Decide whether the symbol is public API, internal but visible, static, inline, macro-backed, or not exported.
3. Add pointer/nullability/assert annotations deliberately.
4. Regenerate and run porting checks.
5. Inspect generated diffs in `proto.h`, `embed.h`, docs, and export-related output.

Read [references/embed-fnc-guide.md](references/embed-fnc-guide.md) for syntax, flags, outputs, and validation commands.

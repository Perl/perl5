---
name: perl-regex-engine
description: "Use when changing or analyzing Perl regex internals: regcomp/regexec, regnodes, optimizer/study logic, tries, ANYOF/EXACT handling, regex generated files, regex debug output, or t/re tests."
---

# Perl Regex Engine

Regex internals are high-risk. Separate compile-time behavior, execution behavior, optimizer behavior, generated node metadata, and user-visible semantics before editing.

## Workflow

1. Identify whether the issue is compile, execute, optimize/study, debug display, generated metadata, or public regex API.
2. Read the relevant source files, `pod/perlreguts.pod`, and `pod/perlreapi.pod` for public regex engine API changes.
3. Never hand-edit generated regex headers; edit generator inputs/scripts and regenerate.
4. Add the narrowest regex tests first, then expand for Unicode, locale, thread, or API coverage as needed.
5. Ask for project context before changing behavior whose historical rationale is unclear.

Read [references/regex-engine-map.md](references/regex-engine-map.md) for source maps, generated files, tests, and risk searches.

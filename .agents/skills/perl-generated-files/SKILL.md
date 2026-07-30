---
name: perl-generated-files
description: "Use when mapping Perl core generated files to generators, running regen targets, validating derived headers/docs/tables, or fixing regen and t/porting/regen failures."
---

# Perl Generated Files

Treat generated outputs as derived artifacts. Find the generator and input first, edit sources, regenerate through make targets, and inspect both source and output diffs.

## Workflow

1. Search the output for `DO NOT EDIT`, `This file is built`, `Generated from`, or generator comments.
2. Map the output to its source inputs and make target.
3. Edit generator input or script, not the generated file, unless the file is intentionally hand-maintained.
4. Run the narrowest regen target, then `t/porting/regen.t` and related checks.
5. Route subsystem-specific changes to the narrower skill when the generated file is only a symptom.

Read [references/generated-files.md](references/generated-files.md) for generator maps, commands, tests, and searches.

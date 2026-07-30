---
name: perl-core-build-test-debug
description: "Use when configuring, building, testing, smoke testing, profiling, debugging, or interpreting failures in the Perl core repository."
---

# Perl Core Build, Test, Debug

Choose the narrowest command that validates the risk. Broaden only after targeted tests pass or when the change crosses subsystem boundaries.

## Workflow

1. Check whether the tree is already configured and built.
2. Use targeted tests for the changed subsystem.
3. Use `t/porting` tests for generated files, metadata, docs, and API consistency.
4. Use debug builds, gdb, valgrind, ASan, or profiling only when the failure mode calls for them.

Read [references/testing-debugging.md](references/testing-debugging.md) for commands and decision points.

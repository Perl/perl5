---
name: perl-configure-build-system
description: "Use when changing Perl Configure, config_h.SH, configpm, Makefile.SH, makedepend, hints, Cross, install config, or platform build conventions."
---

# Perl Configure and Build System

Build-system changes affect every platform. Keep probes, generated config, make targets, and platform hints aligned, and avoid assuming the local Unix build is representative.

## Workflow

1. Identify whether the change belongs to `Configure`, config header generation, makefile generation, dependency generation, install config, hints, or cross-build support.
2. Read the matching generated output and its source template before editing.
3. Check platform-specific overrides in `hints/`, `Cross/`, `win32/`, `vms/`, and `README.*`.
4. Regenerate or rebuild only through documented make or Configure paths.
5. Run syntax, config, manifest, and relevant build/test checks.

Read [references/configure-build-system.md](references/configure-build-system.md) for files, risks, commands, tests, and searches.

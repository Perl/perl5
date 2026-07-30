---
name: perl-core-portability
description: "Use when handling Perl core portability: C dialect limits, EBCDIC/native character macros, locale, threads, multiplicity, globals, hints, Cross, VMS, Windows, OS/2, or AIX."
---

# Perl Core Portability

Assume unusual platforms and build options are real. Check existing macros, platform READMEs, hints, and porting tests before introducing a convenient C or POSIX assumption.

## Workflow

1. Identify which portability axis is involved: C dialect, character set, locale, threads, multiplicity, platform build, or exported globals.
2. Prefer existing core macros over direct libc, byte, global, or compiler-specific assumptions.
3. Check `README.*`, `hints/`, `Cross/`, and platform directories before changing conditional code.
4. Add tests or porting checks that exercise the portability contract where possible.
5. Route configure/build-system changes through `perl-configure-build-system`.

Read [references/core-portability.md](references/core-portability.md) for docs, files, risks, tests, and searches.

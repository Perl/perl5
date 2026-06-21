# Core Change Workflow

## Read First

- `pod/perlhack.pod`: patch process, tests, perldelta expectations.
- `pod/perlhacktips.pod`: C portability, macros, debugging, valgrind, ASan.
- `pod/perlguts.pod`: SV/AV/HV/CV, magic, stacks, memory, optrees.
- `pod/perlinterp.pod`: interpreter overview.
- `pod/perlapi.pod`: public API.
- `pod/perlintern.pod`: documented internal API.
- `handy.h`: common macros, memory helpers, character-class wrappers, context-sensitive convenience macros, and many small conventions used throughout core.
- `pod/perlpolicy.pod`: compatibility and deprecation policy.

## Route Narrowly

- Use `perl-sv-magic-memory` for SV flags, refcounts, mortalization, magic/vtables, arenas, allocation macros, save stack, or ownership changes.
- Use `perl-parser-optree-ops` for `toke.c`, `perly.y`, `op.c`, `op.h`, `pp*.c`, `pad.c`, `scope.c`, check functions, pp functions, optrees, or opcode regen.
- Use `perl-core-portability` for C dialect, EBCDIC/native character handling, locale, threads, multiplicity, globals, `README.*`, `hints/`, `Cross/`, VMS, Windows, OS/2, or AIX issues.
- Use `perl-generated-files` when generated outputs or regeneration tests are central to the change.
- Use `perl-configure-build-system` for `Configure`, `config_h.SH`, `configpm`, `Makefile.SH`, `makedepend`, `hints/`, `Cross/`, or platform build conventions.
- Use `perl-core-archaeology` for bug reports or issues that need historical context, and for `git blame`, `git log -p`, pickaxe, bisect, p5p archive, issue tracker, release-note, or CPAN-upstream history investigations.
- Use `perl-core-docs-release` when code changes require POD, perldelta, MANIFEST, release, or documentation validation.

## Risk Checks

- Public API: functions documented in `pod/perlapi.pod`, `A` entries in `embed.fnc`, exported symbols, and XS-visible macros.
- Internal API: `pod/perlintern.pod`, `C`/internal `embed.fnc` entries, `PERL_CORE` sections.
- Binary compatibility: struct layout, exported symbols, `mathoms.c`, `makedef.pl`, platform export files.
- Generated outputs: `proto.h`, `embed.h`, `opnames.h`, `opcode.h`, `regnodes.h`, Unicode tables, config docs.
- Portability: EBCDIC, VMS, Windows, non-GNU C, unusual integer sizes, locale, threads, multiplicity.
- Repository membership: every new file that should ship must be added explicitly to `MANIFEST`, then sorted with `make manisort`; `make manisort` does not discover and describe new files.

## Naming and Context Conventions

- `pTHX`, `pTHX_`, `aTHX`, `aTHX_`, and `dTHX` are macros, not ordinary identifiers.
- `pTHX`/`pTHX_` appear in function declarations and prototypes that take an interpreter context. The trailing underscore form includes the following comma.
- `aTHX`/`aTHX_` appear at call sites when passing the current interpreter context. The trailing underscore form includes the following comma.
- Prefer explicitly threading interpreter context through internal helpers with `pTHX_` in the signature and `aTHX_` at call sites.
- `dTHX` is the fallback for functions that need interpreter context but do not receive it as an argument; it fetches context from thread-local storage or equivalent. Avoid it in core internals where you can pass context explicitly, and avoid it in XS code too unless the calling convention genuinely leaves no cleaner option.
- `Perl_` names are in Perl's global C namespace, but that prefix alone does not mean public API. Check `pod/perlapi.pod`, `pod/perlintern.pod`, and `embed.fnc` before treating a `Perl_*` symbol as stable or exported.
- `S_` names are file-local static helpers and should stay private to their defining translation unit.
- `Perl_pp_*` names are pp opcode implementations; `PP(foo)`/`PP_wrapped(foo, ...)` macros usually generate those names.
- `Perl_ck_*` names are op checker functions used during compilation.
- `XS_*`, `XSPROTO`, `XS_INTERNAL`, and `XS_EXTERNAL` belong to XS entry-point and linkage conventions rather than ordinary core helper naming.

## Common Commands

```sh
rg -n "symbol_or_behavior" *.c *.h pod lib ext dist cpan t Porting regen
rg -n "PERL_ARGS_ASSERT|Newx|Safefree|SvREFCNT|SAVE|LEAVE|ENTER" file.c
rg -n "perldelta|Incompatible|Deprecations|Internal Changes" pod/perldelta.pod
```

Targeted tests usually start with a specific `t/foo/bar.t`, `t/porting/*.t`, or extension test. See `perl-core-build-test-debug` for test command selection.

## Commit Guidance

- Prefer commits that are self-contained, as small as practical, and avoid unnecessary code churn.
- Keep the change narrowly focused on the actual fix or feature; do not mix in unrelated cleanup unless it is required to make the change correct or maintainable.
- Validate the change with the narrowest relevant tests you can reasonably include, and make sure the final change is well tested.
- Include test coverage whenever practical, especially for behavior changes, bug fixes, regressions, API changes, and generated-file changes.
- Write commit messages with a clear subject line and a wrapped body that explains the problem, the approach, and any important constraints or tradeoffs.
- When possible, start the subject line with the major file or subsystem most responsible for the change. Good patterns are `regcomp.c: fix ...`, `sv.c: add ...`, `embed.fnc: adjust ...`, or `pod/perlhack.pod: clarify ...`.
- Prefer concise, informative subjects over vague ones; the reader should be able to tell where the change lands and roughly what it does before opening the full diff.
- Reference related GitHub issues or pull requests in commit messages when that context is relevant. Use the exact `Fixes #1234` form when the intent is to close an issue on merge; see `pod/perlhack.pod` for the repository's documented convention.
- Keep `AUTHORS` correct for contributor changes. Follow `pod/perlhack.pod` and prefer `Porting/updateAUTHORS.pl` over ad hoc edits when adding or updating contributor records.

## Running Project Tools

After building the tree, run project Perl scripts with the built interpreter and explicit core library path:

```sh
./perl -Ilib some_script.pl
```

Do not omit `-Ilib`; `./perl` may otherwise search install paths that do not exist yet.

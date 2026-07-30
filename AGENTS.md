# Perl Repository Agent Directives

This file gives repository-wide instructions for coding agents working on
Perl core. Apply these directives to every task unless the user explicitly
asks for a different approach.

## Prime Directives

- Keep changes to existing code or infra small, incremental, and reviewable.
- Prefer self-contained commits that include code, tests, documentation, and
  generated-file updates required by the change.
- Add or update tests for behavior changes, bug fixes, generated-file checks,
  and regression-sensitive refactors.
- Update documentation when behavior, APIs, diagnostics, build behavior,
  release process, or contributor workflow changes.
- Consider whether `pod/perldelta.pod` needs an entry for user-visible,
  downstream-visible, release-note-worthy, or maintainer-relevant changes.
- Preserve portability. Check platform READMEs, `hints/`, `Cross/`, EBCDIC,
  locale, threads, multiplicity, and non-Unix assumptions when relevant.
- Prefer existing Perl core patterns, helper macros, regeneration targets, and
  porting tools over new local conventions.
- Do not hand-edit generated files without also identifying and running the
  generator, or documenting why regeneration is not appropriate.
- Keep public API, binary compatibility, and XS/embedding compatibility in mind
  for C and header changes.
- Add every new distribution file to `MANIFEST` with a short description, then
  run `make manisort`.
- Use focused validation first, then broaden. `make test_porting` is a good
  broad check for documentation, metadata, generated-file, and policy changes;
  for preliminary screening, `TEST_JOBS=N make -jN test_porting` is a
  reasonable parallel form.
- Use code archaeology when it helps explain bug reports, surprising behavior,
  compatibility constraints, or old design choices.

## Agent Skills

Repository-specific skill files live in `.agents/skills`. Read the relevant
skill before editing the associated subsystem. The skill tree is documented in
`pod/perlagentskills.pod`.

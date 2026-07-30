# Docs and Release Reference

## Canonical Files

- `pod/`: primary end-user and internals documentation.
- `pod/perldelta.pod`: current release delta template/content.
- `Porting/how_to_write_a_perldelta.pod`: perldelta style and section guidance.
- `Porting/perldelta_template.pod`: template source.
- `Porting/release_managers_guide.pod`: release process.
- `Porting/pumpkin.pod`: historical release and patching guidance.
- `pod/perldocstyle.pod`, `pod/perlpodstyle.pod`: documentation style.
- `pod/perl.pod`: master index for installed Perl documentation.
- `pod/buildtoc`: generates `pod/perltoc.pod` from POD metadata.
- `Porting/pod_rules.pl`: generates POD lists for makefiles and consistency checks.
- `pod/perltoc.pod`: generated table of contents; update through `pod/buildtoc`, not by hand.
- `Porting/README.pod`: Porting tool index.
- `MANIFEST`: distribution contents.
- `Porting/Maintainers*`: module ownership and upstream status.

## Documentation Routing

Use `pod/perl.pod` and generated `pod/perltoc.pod` as the full manual indexes.
Use this shorter map to choose the likely starting document:

- `pod/perlhack.pod`: contribution workflow, patch expectations, tests, pull requests, and when to update `pod/perldelta.pod`.
- `pod/perlsource.pod`: source-tree layout, where code, tests, modules, generated files, and developer tools live.
- `pod/perlinterp.pod`: interpreter architecture and how the major C source files fit together.
- `pod/perlhacktips.pod`: practical C-level hacking tips, debugging, portability traps, and core build options.
- `pod/perlgit.pod`: git workflow for the Perl repository.
- `pod/perlguts.pod`: internals concepts for extension and core work; start here for SVs, refs, stacks, pads, magic, and related APIs.
- `pod/perlapi.pod`: public API reference generated from core annotations; do not edit by hand.
- `pod/perlintern.pod`: internal API reference generated from core annotations; do not edit by hand.
- `pod/perlxstut.pod`, `pod/perlxs.pod`, `pod/perlxstypemap.pod`, and `pod/perlembed.pod`: XS, typemap, and embedding documentation.
- `pod/perlre.pod`, `pod/perlreapi.pod`, and `pod/perlreguts.pod`: regex user behavior, regex plugin API, and regex engine internals.
- `pod/perlport.pod`, `pod/perlebcdic.pod`, `README.*`, `hints/`, and `Cross/`: portability, platform behavior, and build assumptions.
- `pod/perldocstyle.pod` and `pod/perlpodstyle.pod`: prose style and POD markup style for documentation changes.
- `Porting/README.pod`: index for release, maintenance, and porting helper tools.
- `Porting/how_to_write_a_perldelta.pod`: style and structure for perldelta entries.

Use the make target for manifest sorting:

```sh
make manisort
```

Do not call `Porting/manisort` directly as the preferred workflow; the make target reflects the repository's intended entry point.

## New Files and MANIFEST

Every new file that should ship in the Perl distribution needs an explicit `MANIFEST` entry with a short description. `make manisort` only sorts existing entries; it does not discover arbitrary new files and add descriptions for them.

- For ordinary new files, add the `MANIFEST` line manually, then run `make manisort`.
- Use `./perl -Ilib Porting/manicheck` or `./perl -Ilib t/porting/manifest.t` to find files missing from `MANIFEST` and stale `MANIFEST` entries.
- Use workflow-specific helpers when they apply: `Porting/add-pod-file` for new `pod/*.pod` files, `Porting/add-package.pl` for package imports, and `Porting/sync-with-cpan` for CPAN sync workflows.
- Stage the new file and the `MANIFEST` update together; `t/porting/manifest.t` checks git tracking as well as file existence.

## POD Checks

`make test_porting` is a good broad validation target for documentation,
metadata, `MANIFEST`, generated-list, and policy changes.

```sh
make test_porting
./perl -Ilib t/porting/podcheck.t
./perl -Ilib t/porting/pod_rules.t
./perl -Ilib t/porting/perlfunc.t
./perl -Ilib t/porting/manifest.t
./perl -Ilib t/porting/maintainers.t
```

Use the available built perl. If not built, inspect the test files for prerequisites before running.

## Perldelta Decision

Usually add `pod/perldelta.pod` notes for user-visible behavior changes, incompatible changes, deprecations, security changes, performance changes, module updates, diagnostics, platform support, testing changes, and internal changes notable to downstream maintainers.

Do not add noise for purely mechanical refactors with no user, extension, maintainer, or release impact.

## Adding or Moving POD

- Add end-user and internals documentation under `pod/` unless nearby module ownership says otherwise.
- Follow `pod/perldocstyle.pod` for prose style and `pod/perlpodstyle.pod` for POD markup style.
- Update `pod/perl.pod` when the document should appear in the installed documentation index.
- Run `./perl -Ilib -I. -f pod/buildtoc -q` or the relevant make path to refresh `pod/perltoc.pod`.
- Run `./perl -Ilib Porting/pod_rules.pl --build-podmak --verbose` when POD makefile lists need refreshing; `t/porting/pod_rules.t` will point at this area when stale.
- Keep `MANIFEST` sorted with `make manisort`.

## Useful Searches

```sh
rg -n "perldelta|delta|Documentation|Internal Changes|Diagnostics" pod/perlhack.pod Porting pod/perldelta.pod
rg -n "podcheck|pod_rules|perldocstyle|perlpodstyle|buildtoc|perltoc" t/porting pod Porting
rg -n "MANIFEST|Maintainers|customized" Porting t/porting
```

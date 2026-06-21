# Perl Core Source Map

Use this as a navigation index. Load canonical docs before relying on this summary for detailed behavior.

## Top-Level Areas

- `*.c`, `*.h`: interpreter core sources and public/internal headers.
- `pod/`: primary Perl documentation, including internals docs.
- `lib/`: core Perl modules and some generated or module-owned POD.
- `ext/`: core extensions built with the interpreter.
- `dist/`: dual-life distributions maintained primarily in core.
- `cpan/`: dual-life distributions imported from CPAN.
- `t/`: core tests. `t/TEST` and `t/harness` drive many test workflows.
- `Porting/`: release, maintenance, validation, metadata, and contributor tools.
- `regen/`: generators for derived headers, docs, tables, and metadata.
- `hints/`, `Cross/`, `README.*`: platform-specific build support.

## Canonical Docs

- Orientation: `pod/perlsource.pod`, `README`, `INSTALL`.
- Hacking: `pod/perlhack.pod`, `pod/perlhacktips.pod`, `pod/perlpolicy.pod`.
- Internals: `pod/perlguts.pod`, `pod/perlinterp.pod`, `pod/perlapi.pod`, `pod/perlintern.pod`.
- Regex internals: `pod/perlreguts.pod`, `pod/perlreapi.pod`, `pod/perldebguts.pod`.
- XS/API: `lib/perlxs.pod`, `lib/perlxstut.pod`, `lib/perlxstypemap.pod`, `pod/perlembed.pod`, `pod/perlcall.pod`.
- Docs style: `pod/perldocstyle.pod`, `pod/perlpodstyle.pod`.
- Release work: `Porting/release_managers_guide.pod`, `Porting/how_to_write_a_perldelta.pod`, `pod/perldelta.pod`.
- History work: `pod/perlgit.pod`, `Porting/bisect.pl`, `Porting/bisect-runner.pl`, `pod/perlNNNdelta.pod`, p5p archives.

## Generated File Guardrail

Before editing a file that looks generated, search for its generator:

```sh
rg -n "DO NOT EDIT|This file is built|Generated from|regen" FILE
rg -n "FILE|basename_without_suffix" regen Porting Makefile.SH
```

Edit the source generator/input where possible, run the relevant regen command, then inspect generated diffs.

## Running Project Scripts

After building the tree, run project Perl scripts with the built interpreter and explicit core library path:

```sh
./perl -Ilib some_script.pl
```

The `-Ilib` matters. Without it, `./perl` can search install paths that do not exist yet and fail to find core modules such as `strict.pm`.

## Useful Searches

```sh
rg -n "NAME|DESCRIPTION|SYNOPSIS" pod/perl*.pod lib/*.pod Porting/*.pod
rg -n "make test|test_harness|TEST_ARGS|TEST_FILES" README pod/perlhack.pod Makefile.SH
rg -n "regen|generated|DO NOT EDIT" Makefile.SH regen Porting t/porting
rg -n "AUTHORS|Maintainers|generated|regen" AUTHORS Porting pod *.c *.h regen
```

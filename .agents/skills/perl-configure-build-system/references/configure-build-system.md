# Configure and Build System Reference

## Canonical Docs

- `INSTALL`: primary build and configuration documentation.
- `README`, `README.*`: platform-specific build notes.
- `pod/perlhack.pod`: development build and test workflow.
- `Porting/README.pod`: maintenance scripts.
- `Cross/README`, `Cross/`: cross-compilation conventions where present.

## Key Files

- `Configure`: main Unix configuration script.
- `config_h.SH`: generates `config.h` from Configure results.
- `configpm`: generates `Config.pm` and related install-time configuration.
- `Makefile.SH`, `make_ext.pl`, `makedepend.SH`: generated makefile and dependency behavior.
- `hints/`: platform and compiler hints consumed by Configure.
- `Cross/`: cross-build templates and support scripts.
- `win32/`, `vms/`, `os2/`: non-Unix build systems and platform support.
- `installperl`, `installman`, `Porting/Glossary`, `regen-configure/`: install and Configure-related metadata.

## Risk Checks

- Probe semantics: distinguish compile tests, run tests, cross-build defaults, cached answers, and user-supplied Configure options.
- Generated config: keep `Configure`, `config_h.SH`, `configpm`, `Porting/Glossary`, and docs aligned when adding or removing symbols.
- Make behavior: avoid GNU make or shell assumptions unless the target already requires them.
- Platform hints: check whether a change needs hints overrides or breaks existing ones.
- Paths and tools: account for spaces, drive letters, case-insensitive filesystems, non-POSIX shells, and missing utilities.

## Commands

```sh
./Configure -des -Dusedevel
make
make test_harness TEST_FILES='comp/hints.t'
./perl -Ilib t/porting/manifest.t
./perl -Ilib t/porting/regen.t
./perl -Ilib -c configpm
./perl -Ilib -c makedepend.SH
```

Use platform-specific build commands for `win32/`, `vms/`, `os2/`, or cross builds instead of forcing the Unix make path.

## Useful Searches

```sh
rg -n "d_\\w+|i_\\w+|HAS_|use\\w+|config_sh|config_h|Glossary|Configure" Configure config_h.SH configpm Porting hints Cross
rg -n "Makefile.SH|makedepend|make_ext|test_harness|regen|installperl|installman" Makefile.SH makedepend.SH make_ext.pl installperl installman Porting
rg -n "VMS|WIN32|OS2|AIX|cross|hints|config" README.* hints Cross win32 vms os2 t
```

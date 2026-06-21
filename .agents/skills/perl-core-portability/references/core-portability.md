# Core Portability Reference

## Canonical Docs

- `pod/perlhacktips.pod`: C portability, macros, debugging, and platform notes.
- `pod/perlport.pod`: Perl-level portability behavior.
- `pod/perlebcdic.pod`: EBCDIC and native character set handling.
- `pod/perllocale.pod`: locale behavior and risks.
- `pod/perlthrtut.pod`: thread behavior visible to users.
- `INSTALL`, `README.*`, `Porting/README.pod`: build and platform guidance.

## Key Files

- `perl.h`, `handy.h`, `config.h`, `config_h.SH`: core portability macros and config-derived feature gates.
- `utf8.h`, `ebcdic_tables.h`, `regen/charset_translations.pl`: native/Unicode/EBCDIC mapping.
- `locale.c`, `locale_table.h`, `regen/locale.pl`: locale state and generated tables.
- `intrpvar.h`, `perlvars.h`, `thread.h`: interpreter globals, thread-local state, multiplicity.
- `hints/`, `Cross/`, `win32/`, `vms/`, `os2/`, `README.*`: platform-specific build and code conventions.
- `makedef.pl`, `embed.fnc`, `mathoms.c`: exports and binary compatibility surface.

## Risk Checks

- C dialect: avoid assuming C99/C11 features, GNU extensions, declaration-after-statement support, or compiler warnings semantics unless established nearby.
- Characters: use native-aware macros instead of ASCII constants when semantics are character-based; check EBCDIC.
- Locale: avoid process-global locale surprises; account for UTF-8 locale, thread safety, and `LC_*` categories.
- Threads/multiplicity: avoid direct globals where interpreter-local state is required; check clone, teardown, and `PERL_IMPLICIT_CONTEXT`.
- Platforms: do not assume Unix paths, file descriptors, fork, symlinks, signals, case-sensitive filesystems, or ELF exports.

## Tests

```sh
./perl -Ilib t/porting/globvar.t
./perl -Ilib t/porting/libperl.t
./perl -Ilib t/porting/regen.t
make test_harness TEST_FILES='run/locale.t op/threads.t op/utf8*.t io/utf8.t uni/*.t'
make test_harness TEST_FILES='../ext/XS-APItest/t/locale.t ../ext/XS-APItest/t/thread.t ../ext/XS-APItest/t/win32.t'
```

Use platform-specific smoke results when local hardware cannot exercise the risk.

## Useful Searches

```sh
rg -n "EBCDIC|NATIVE|ASCII|is[A-Z_a-z]+_A|LATIN1|UTF-8|utf8" *.c *.h pod t regen
rg -n "locale|LC_|setlocale|uselocale|thread|MULTIPLICITY|PERL_IMPLICIT_CONTEXT|dTHX|pTHX" *.c *.h t ext
rg -n "VMS|WIN32|OS2|AIX|__GNUC__|HAS_|I_\\w+|d_\\w+|hints|Cross" *.c *.h Configure config_h.SH hints Cross win32 vms os2
```

# embed.fnc Guide

## Core Files

- `embed.fnc`: canonical entries, syntax, flags, and documentation directives.
- `regen/embed.pl`: generator and flag validation.
- `regen/embed_lib.pl`: parser shared by `embed.pl`, `autodoc.pl`, `makedef.pl`, and some porting tests.
- `regen/tidy_embed.pl`: sorting and formatting rules.
- `autodoc.pl`: generates API docs.
- `makedef.pl`: generates export lists for platforms.

## Entry Syntax

Entries are pipe-separated:

```text
flags|return_type|name|arg1|arg2|...|argN
```

Backslash continues entries. `aTHX` context is implicit unless `T` is used.

Pointer arguments should be annotated: `NN`, `NULLOK`, `SPTR`, `MPTR`, `EPTRge`, `EPTRgt`, `EPTRtermNUL`. Integer nonzero uses `NZ`. `NOCHECK` suppresses automatic AV/HV/CV type checks.

Generated `PERL_ARGS_ASSERT_FOO` macros should be called near the top of the implementation.

## Flag Groups

- Visibility/API: `A` public API/perlapi, `C` visible but internal/perlintern, `E` core extensions, `X` exported without short-name macro outside core, `e` not exported.
- Naming/storage: `p` real symbol has `Perl_`, `S` real symbol has `S_`, `s` static `Perl_`, `i`/`I` static inline, `m` macro implementation, `M` implementation supplies own macro, `o` omit generated short macro.
- Behavior/docs/export: `d` has docs, `h` hide docs or link elsewhere, `D` deprecated, `x` experimental, `b` mathoms/binary compatibility, `N` no compatibility macro, `O` compatibility macro only, `R` warn unused result, `r` noreturn, `a` malloc-like, `P` pure, `f` printf/strftime format, `F` varargs not format, `W` debug depth arg.
- Non-functions: `v` value, `y` typedef, `@` array, `#` preprocessor symbol, `;` semicolon in usage, `U` suppress usage, `u` unorthodox macro syntax, `n` no arg list.

Confirm details in `embed.fnc`; flag legality is enforced in `regen/embed.pl`.

## Generated Outputs

- `regen/embed.pl`: `proto.h`, `embed.h`, `embedvar.h`, `long_names.c`.
- `autodoc.pl`: `pod/perlapi.pod`, `pod/perlintern.pod`.
- `makedef.pl`: platform export lists to stdout for `aix`, `win32`, `os2`, `vms`, and `test`.

## Commands

```sh
make regen_headers
make regen
./perl -Ilib regen/tidy_embed.pl --tap embed.fnc
./perl -Ilib makedef.pl PLATFORM=test
./perl -Ilib t/porting/regen.t
./perl -Ilib t/porting/args_assert.t
./perl -Ilib t/porting/globvar.t
./perl -Ilib t/porting/diag.t
./perl -Ilib t/porting/header_parser.t
./perl -Ilib t/porting/extrefs.t
./perl -Ilib t/porting/cpphdrcheck.t
./perl -Ilib t/porting/libperl.t
./perl -Ilib t/porting/podcheck.t
```

Use commands that match the available build state. Avoid direct `regen.pl` invocation; use make targets so regeneration ordering and prerequisites are respected. For project scripts, use `./perl -Ilib script.pl`, not bare `./perl script.pl`.

## API Risks

- `A` is an API contract for XS authors. Do not use it just to fix linkage.
- `Perl_` or presence in `proto.h` does not imply public API. `pod/perlapi.pod` is the public signal.
- `C` and `X` can export implementation symbols while remaining internal.
- Do not expose internal macros/types to XS namespace casually.
- Typedefs, enums, and values are not hidden by `embed.h`; protect internal ones with `#if defined(PERL_CORE)` where appropriate.

## Useful Searches

```sh
rg -n '^[:A-Za-z0-9_@#?;]+\s*\|' embed.fnc
rg -n '\|NAME\b|\|NULLOK\b|\|SPTR\b|\|MPTR\b|\|EPTR|\bNZ\b|\bNOCHECK\b' embed.fnc
rg -n '^=for apidoc(_item|_flag|_defn)?\b' *.c *.h pod/*.pod
rg -n 'PERL_ARGS_ASSERT_[A-Z0-9_]+;' *.c *.h
rg -n 'flag .*not legal|requires .*flag|mutually exclusive|incompatible' regen/embed.pl
rg -n 'setup_embed|embed\.fnc|makedef|autodoc|PERL_ARGS_ASSERT' regen/*.pl autodoc.pl makedef.pl t/porting/*.t
```

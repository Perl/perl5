# SV, Magic, and Memory Reference

## Canonical Docs

- `pod/perlguts.pod`: SVs, AVs, HVs, CVs, refcounts, magic, stacks, arenas, and internals overview.
- `pod/perlapi.pod`: public API for XS-visible value and memory helpers.
- `pod/perlintern.pod`: documented internal API.
- `pod/perlhacktips.pod`: debugging, leak checks, ASan, valgrind, and portability notes.
- `lib/perlxs.pod`, `lib/perlxstypemap.pod`: extension-facing ownership and conversion patterns.

## Key Files

- `sv.c`, `sv.h`, `sv_inline.h`: scalar body layout, flags, refcounts, PV handling, copy-on-write, magic hooks.
- `av.c`, `hv.c`, `hv.h`: arrays, hashes, placeholders, iteration, shared keys, hash randomization concerns.
- `cv.h`, `pad.c`, `op.c`: CVs, pads, closures, prototypes, anon subs, and ownership across compilation.
- `mg.c`, `mg.h`, `mg_data.h`, `mg_raw.h`, `mg_vtable.h`, `regen/mg_vtable.pl`: magic types, vtables, and generated vtable metadata.
- `scope.c`, `scope.h`: save stack, temps, `ENTER`/`LEAVE`, `SAVE*`, mortals, and unwinding.
- `perl.h`, `handy.h`, `embed.fnc`, `proto.h`: allocation macros, assertions, and API surfaces.

## Risk Checks

- Refcount ownership: know whether a function borrows, steals, increments, decrements, mortalizes, or transfers.
- Magic: account for get/set/clear/free callbacks, `SvMAGICAL`, tied values, overload, taint, hints, env, and regex/global magic.
- Copy-on-write and UTF-8: preserve flags and buffer ownership through scalar mutation.
- Save stack and temps: balance `ENTER`/`LEAVE`, `SAVETMPS`/`FREETMPS`, `SAVE*`, `mortal` values, and exception paths.
- Threads/multiplicity: avoid hidden globals and verify clone/free paths for shared or interpreter-owned state.
- API: use `perl-embed-fnc` for public/internal function exposure, generated prototypes, args assertions, or API docs.

## Tests

```sh
make test_harness TEST_FILES='op/sv*.t op/ref.t op/bless.t op/magic*.t op/tie*.t op/hash*.t op/array.t'
make test_harness TEST_FILES='../ext/XS-APItest/t/sv*.t ../ext/XS-APItest/t/magic*.t ../ext/XS-APItest/t/weaken.t ../ext/XS-APItest/t/savestack.t'
./perl -Ilib t/porting/args_assert.t
./perl -Ilib t/porting/globvar.t
```

Use `PERL_DESTRUCT_LEVEL=2` with targeted tests when leak sensitivity matters.

## Useful Searches

```sh
rg -n "SvREFCNT|SvFLAGS|SvMAGICAL|SvROK|SvPVX|SvUTF8|SvIsCOW|SvWEAKREF" sv.c sv.h *.c *.h ext/XS-APItest
rg -n "mg_|MAGIC|MGVTBL|PERL_MAGIC|SAVE|ENTER|LEAVE|FREETMPS|SAVETMPS|mortal" *.c *.h ext/XS-APItest t/op
rg -n "Newx|Newxz|Renew|Safefree|Move|Copy|Zero|Poison|PERL_ARGS_ASSERT" *.c *.h
```

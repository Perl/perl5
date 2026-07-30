# Parser, Optree, and Ops Reference

## Canonical Docs

- `pod/perlinterp.pod`: interpreter, parser, optree, stack, and execution overview.
- `pod/perlguts.pod`: op internals, pads, CVs, scopes, and memory ownership.
- `pod/perlhack.pod`: testing and regeneration workflow.
- `pod/perlapi.pod`, `pod/perlintern.pod`: API boundary for op and parser helpers.
- `ext/B/B/Concise.pm`, `ext/B/t/`: observable optree output and tests.

## Key Files

- `toke.c`, `perly.y`, `perly.act`, `perly.h`, `perly.tab`: lexer and grammar artifacts.
- `regen_perly.pl`: regenerates `perly` artifacts; use `make regen_perly` or `make regen-perly`.
- `op.c`, `op.h`, `opnames.h`, `opcode.h`, `op_reg_common.h`, `regen/opcodes`, `regen/op_private`, `regen/opcode.pl`: op definitions and generated metadata.
- `pp.c`, `pp_hot.c`, `pp_ctl.c`, `pp_sys.c`, `pp_sort.c`, `pp_pack.c`: pp implementations.
- `pad.c`, `pad.h`, `scope.c`, `scope.h`, `cop.h`, `parser.h`: lexical pads, hints, scopes, COPs, and parser state.
- `peep.c`: peephole optimizer and op transformations.
- `lib/B/Deparse.pm`, `lib/B/Deparse.t`, `ext/B/t/`: deparse and optree visibility, especially after op compaction or new op forms.
- `t/lib/croak/*`, `t/lib/warnings/*`, `pod/perldiag.pod`: parser diagnostics and warning text fixtures.

## Risk Checks

- Stack behavior: preserve `SP`, `MARK`, `dSP`, `PUSH*`, `XPUSH*`, `RETURN`, and pp calling conventions.
- Context: respect scalar/list/void/lvalue context and `OPf_WANT*` flags.
- Pads/scopes: preserve lexical lifetime, closure capture, hints, warnings, `%^H`, and save-stack unwinding.
- Optree shape: B tests and downstream tooling may depend on observable op names, flags, private bits, and child order.
- Diagnostics: parser behavior changes often require synchronized updates to croak/warnings fixtures and `pod/perldiag.pod`.
- Deparse: op optimizer changes can break `B::Deparse`, including code blocks embedded in regexes.
- Parser artifacts: do not hand-edit generated `perly` or opcode headers.
- API: route generated prototypes or exposed helper changes through `perl-embed-fnc`.

## Regen and Validation

```sh
make regen_perly
make regen-perly
make regen_headers
make regen
./perl -Ilib t/porting/regen.t
./perl -Ilib t/porting/header_parser.t
./perl -Ilib t/porting/args_assert.t
```

`make regen` runs many, but not all, regenerators. Use `perl-generated-files` when mapping an output to its generator is the main problem.

## Tests

```sh
make test_harness TEST_FILES='comp/*.t op/*.t'
make test_harness TEST_FILES='../lib/B/Deparse.t ../ext/B/t/*.t ../ext/XS-APItest/t/op*.t ../ext/XS-APItest/t/pad*.t'
cd t && ./perl -I../lib harness comp/parser.t op/args.t op/state.t
```

## Useful Searches

```sh
rg -n "TOKEN|KEYWORD|yylex|parser|perly|grammar|PL_parser|lex_|op_lvalue|new[A-Z].*OP" toke.c perly.y op.c op.h parser.h
rg -n "PP\\(|PP_wrapped|OPf_|OPp_|ck_|op_private|regen/opcodes|regen/op_private" pp*.c op.c op.h regen ext/B/t t/op
rg -n "PAD|pad_|SAVE|LEAVE|ENTER|COP|%^H|hints|scope" pad.c scope.c op.c cop.h t/comp t/op ext/XS-APItest
rg -n "croak|warning|diagnostic|Deparse|PADRANGE|\\(\\?\\{" t/lib pod/perldiag.pod lib/B ext/B t/re
```

# XS and Embedding Reference

## Canonical Docs

- `lib/perlxs.pod`: XS reference.
- `lib/perlxstut.pod`: XS tutorial.
- `lib/perlxstypemap.pod`: typemaps.
- `pod/perlembed.pod`: embedding Perl.
- `pod/perlcall.pod`: calling Perl from C.
- `pod/perlguts.pod`: internal API context.
- `pod/perlapi.pod`: public API.
- `pod/perlintern.pod`: internal documented functions.
- `pod/perlapio.pod`, `pod/perliol.pod`: PerlIO.

## Source and Tests

- `ext/XS-APItest/`: API-level tests for XS-facing behavior.
- `ext/`: bundled extensions.
- `dist/ExtUtils-ParseXS/`, `dist/ExtUtils-CBuilder/`, `cpan/ExtUtils-MakeMaker/`: XS build tooling areas.
- `XSUB.h`, `EXTERN.h`, `perl.h`, `embed.h`, `proto.h`: key headers.

## API Boundary

- `pod/perlapi.pod` is the public API signal.
- `pod/perlintern.pod` is internal, even when documented.
- `Perl_` prefix or `proto.h` presence does not make a symbol public.
- Use `perl-embed-fnc` before changing `A`, `C`, `X`, exports, args assertions, or generated prototypes.

## XS Conventions

- Define `PERL_NO_GET_CONTEXT` before including `EXTERN.h`, `perl.h`, and `XSUB.h` where the file can pass interpreter context explicitly.
- Prefer passing context with `pTHX_` and `aTHX_`; use `dTHX` only when the calling convention does not provide a cleaner context path.
- Use `XS_INTERNAL` and `XS_EXTERNAL` for XS entry-point linkage decisions, and `XSPROTO(name)` for prototypes that must match XS calling conventions.
- Use `dXSARGS`, `ST(n)`, `items`, `PUSHs`, `XPUSHs`, `EXTEND`, `PUTBACK`, `SPAGAIN`, `dMARK`, and related stack macros according to existing nearby XS code.
- Check typemaps before hand-converting arguments. Core typemap behavior is in `lib/perlxstypemap.pod`, extension typemaps, and `ExtUtils::ParseXS`.
- Keep boot functions and `newXS` registration compatible with existing module patterns; avoid exposing core-only helpers just to simplify XS setup.
- For parser or typemap generation issues, inspect `dist/ExtUtils-ParseXS/` tests before changing generated XS output.

## Useful Searches

```sh
rg -n "XS|typemap|xsub|PERL_CORE|perlapi|perlintern" lib pod ext dist
rg -n "PERL_NO_GET_CONTEXT|XS_INTERNAL|XS_EXTERNAL|XSPROTO|dXSARGS|call_sv|newXS|PUSH|XPUSH|SvREFCNT|RETVAL" ext dist lib *.c *.h
rg -n "XS-APItest|callregexec|regex_global_pos" ext/XS-APItest t
```

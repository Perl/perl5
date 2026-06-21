# Language and Library Reference

## Language Docs

- Syntax and operators: `pod/perlsyn.pod`, `pod/perlop.pod`, `pod/perldata.pod`, `pod/perlsub.pod`.
- Builtins: `pod/perlfunc.pod`, `pod/perlvar.pod`, `pod/perlrun.pod`.
- Regex user behavior: `pod/perlre.pod`, `pod/perlretut.pod`, `pod/perlrequick.pod`.
- Unicode/locale: `pod/perlunicode.pod`, `pod/perluniintro.pod`, `pod/perllocale.pod`.
- Security/portability: `pod/perlsec.pod`, `pod/perlport.pod`.
- Policy/deprecation: `pod/perlpolicy.pod`, `pod/perldeprecation.pod`, `pod/perlexperiment.pod`.

## Module Ownership

- `lib/`: core modules and docs.
- `ext/`: core extensions.
- `dist/`: dual-life distributions often maintained with core involvement.
- `cpan/`: distributions usually imported from CPAN.
- `Porting/Maintainers`, `Porting/Maintainers.pl`, `Porting/Maintainers.pm`: ownership and upstream metadata.
- `t/porting/customized.t` and `t/porting/customized.dat`: local customizations for imported modules.

Changes can cross ownership boundaries. If fixing a core-visible bug requires touching both `cpan/` and `dist/`, check upstream status, local customization records, and whether one dual-life module is being changed only to unblock another.

## Tests

- Language behavior: `t/op`, `t/run`, `t/cmd`, `t/io`, `t/uni`, `t/re`.
- Library behavior: nearby tests under `lib/`, `ext/*/t`, `dist/*/t`, `cpan/*/t`.
- Portability/policy: `t/porting`.
- Diagnostics and docs: `t/lib/croak/*`, `t/lib/warnings/*`, `pod/perldiag.pod`, and the relevant user-facing POD.

## Useful Searches

```sh
rg -n "function_or_feature" pod lib ext dist cpan t
rg -n "CUSTOMIZED|Maintainers|DISTRIBUTION|FILES|UPSTREAM" Porting/Maintainers* t/porting/customized.*
rg -n "deprecated|experimental|incompatible|perldelta" pod Porting t
rg -n "croak|warning|diagnostic|unicode class|blessed|package separator" pod lib ext dist cpan t
```

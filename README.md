# Perl 7.0.0

You can read more about [the Proposal for Perl 7](https://github.com/Perl/perl5/wiki/The-Proposal-for-Perl-7) on the [wiki page](https://github.com/Perl/perl5/wiki/The-Proposal-for-Perl-7).

# About this 'core-p7' branch

The branch `core-p7` is *experimental* and based on top of [v5.32.0](https://github.com/Perl/perl5/tree/v5.32.0). It tries to show what could looks like a `perl` binary compiled with `strict, warnings` and several features like `signature, no indirect...` as described in [the Proposal for Perl 7](https://github.com/Perl/perl5/wiki/The-Proposal-for-Perl-7).

The goal is to identify issues with the proposal and provides a `proof of concept`.

# What to expect?

## Compiling and running tests

You should be able to compile perl using your favorites configure options

```
git clean -dxf
./Configure -Dcc="ccache gcc" -Dusedevel -des
```

The test suite is currently not clean and you should expect multiple errors.
Several fixes are still required to adjust some core or dual life modules. Patch welcome!

You can run the test suite using for example this command:
```
TEST_JOBS=8 make -j8 test_harness
```

## New defaults implemented in core-p7

`v7.0` is the opportunity to promote new defaults as standard.

When using perl from this branch you are going to have the following defaults out of the box:

* use strict
* use warnings

### Features enabled by default

[regen/features.pl](https://github.com/Perl/perl5/blob/core-p7/regen/feature.pl) was patched to setup the list for `v7.0`.

* bitwise
* current_sub
* evalbytes
* fc
* no indirect
* postderef_qq
* say
* state
* switch
* unicode_eval
* unicode_strings

Note that due to the limitation of features bundles wich can be stored in `HINT_FEATURE_MASK`, some cleanup was made by [401cba074e7](https://github.com/Perl/perl5/commit/401cba074e7458c7f5d4f31dce6334799f4f88ba).

### Features not enabled by default

* utf8 *not a feature*
* unicode_strings

### lib/p5.pm, lib/p7.pm and regen/pX.pm

Right now you could change the defaults by using `use p5` in a filename to avoid enabling `v7.0` standards.

[regen/pX.pl](https://github.com/Perl/perl5/blob/core-p7/regen/pX.pl) provides a mechanism to generate `lib/p5.pm` and `lib/p7.pm`.

The final name could change and we could prefer alternate like `use v7` and `use v5` or `use compat::p5` and `use compat::p7`. Right now by using `p5` and `p7` this allows to avoid some technical details and a global replace could be performed later in the development cycle.

* [regen/pX.pl](https://github.com/Perl/perl5/blob/core-p7/regen/pX.pl)
* [lib/p7.pm](https://github.com/Perl/perl5/blob/core-p7/lib/p7.pm)
* [lib/p5.pm](https://github.com/Perl/perl5/blob/core-p7/lib/p5.pm)

Note: `p5` needs to be patched to authorize `use feature "indirect"`.

## New flags

This could change overtime and we could come with a better solution, but right now this is what has been implemented in the `core-p7` branch.

### -e promotes v7.0 standard

Using `-e` you are using the `v7.0` features with `strict` and `warnings`

You can run something like this natively
```
./perl -e 'sub add($a, $b) { return $a + $b } my $list = [1, 2]; say add( $list->@* )'
3
```

### -5 fallback to v5.0 standards

`-5` was introduced to keep writing oneliners using the `v5` standards

```
# works
./perl -5 "print 54"

# but this fails
./perl -5 "say 54"
Number found where operator expected at -e line 1, near "say 54"
	(Do you need to predeclare say?)
syntax error at -e line 1, near "say 54"
Execution of -e aborted due to compilation errors.
```

### -E could enable future features

Currently behaves like `-e` but could overtime enable new features enabled during the `7.x` development cycle.

# How to contribute?

You can submit fixes as `Pull Request` by targeting the `core-p7` using the [github.com/Perl/perl](https://github.com/Perl/perl5) repoository.

# FAQ

## Is this branch going to be released?

No, this branch should not be released as it. It's a primer to give the opportunity to experience what could feels like `Perl 7`.

## Is it going to be merged to blead?

No. The goal is to not break blead and submit small mergeable/reviewable chunks to blead later once the global direction for the project is validated.

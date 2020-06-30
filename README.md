# Perl 7.0.0

You can read more about [the Proposal for Perl 7](https://github.com/Perl/perl5/wiki/The-Proposal-for-Perl-7) on the [wiki page](https://github.com/Perl/perl5/wiki/The-Proposal-for-Perl-7).

# About this 'core-p7' branch

The branch `core-p7` is *experimental* and based on top of [v5.32.0](https://github.com/Perl/perl5/tree/v5.32.0). It tries to show what could looks like a `perl` binary compiled with `strict, warnings` and several features like `signature, no indirect...` as described in [the Proposal for Perl 7](https://github.com/Perl/perl5/wiki/The-Proposal-for-Perl-7).

The goal is to identify issues with the proposal and provides a `proof of concept`.

# What to expect?

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

# How to contribute?

You can submit fixes as `Pull Request` by targeting the `core-p7` using the [github.com/Perl/perl](https://github.com/Perl/perl5) repoository.

# FAQ

## Is this branch going to be released?

No, this branch should not be released as it. It's a primer to give the opportunity to experience what could feels like `Perl 7`.

## Is it going to be merged to blead?

No. The goal is to not break blead and submit small mergeable/reviewable chunks to blead later once the global direction for the project is validated.

## lib/p5.pm, lib/p7.pm and regen/pX.pm

[regen/pX.pl](https://github.com/Perl/perl5/blob/core-p7/regen/pX.pl) provides a mechanism to generate `lib/p5.pm` and `lib/p7.pm`.

The final name could change and we could prefer alternate like `use v7` and `use v5` or `use compat::p5` and `use compat::p7`. Right now by using `p5` and `p7` this allows to avoid some technical details and a global replace could be performed later in the development cycle.

* [regen/pX.pl](https://github.com/Perl/perl5/blob/core-p7/regen/pX.pl)
* [lib/p7.pm](https://github.com/Perl/perl5/blob/core-p7/lib/p7.pm)
* [lib/p5.pm](https://github.com/Perl/perl5/blob/core-p7/lib/p5.pm)

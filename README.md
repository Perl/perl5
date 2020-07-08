# Perl 7.0.0

You can read more about [the Proposal for Perl 7](https://github.com/Perl/perl5/wiki/The-Proposal-for-Perl-7) on the [wiki page](https://github.com/Perl/perl5/wiki/The-Proposal-for-Perl-7).

# About this 'core-p7' branch

The branch `core-p7` is **experimental** and based on top of [v5.32.0](https://github.com/Perl/perl5/tree/v5.32.0). It tries to show what could looks like a `perl` binary compiled with `strict, warnings` and several features like `signature, no indirect...` as described in [the Proposal for Perl 7](https://github.com/Perl/perl5/wiki/The-Proposal-for-Perl-7).

The goal is to identify issues with the proposal and to provide a **proof of concept**.

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

You can run tests in specific directories (relative to `t/`) with a command like this:
```
make test TEST_FILES="io/*.t"
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

This could change over time and we could come with a better solution, but right now this is what has been implemented in the `core-p7` branch.

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

# FAQ

## Is this branch going to be released?

No, this branch will not be released as is. It's a primer to give the Perl community the opportunity to experience what `Perl 7` might feel like.

## Is it going to be merged to blead?

No. The goal is to not break blead and submit small mergeable/reviewable chunks to blead later once the global direction for the project is validated.

## How can I contribute to the work on the `core-p7` branch?

Working on the `core-p7` branch is very similar to working on `blead`, with two differences to be discussed below.

### Work cycle:

* Fork the [Perl 5 core repository](https://github.com/Perl/perl5) to your own
  GitHub site, then clone that repository to your local machine.
* `git checkout core-p7`
* `git checkout -b my-core-p7-contribution`
* Regular configure-build-test cycle
* `git add` then `git commit`
* In the output from `git commit` you will be provided a github URL to create a pull request.  When you arrive at that URL, be sure to **change the target branch for that pull request** from `blead` to `core-p7`.  (This is Difference #1).

### Filing issues (bug tickets)

Because we will encounter **many** bugs in the course of working on the `core-p7` branch, and because the overwhelming majority of those bug reports will not be relevant to ongoing development in blead, we are using a different location for issues for this branch.  (This is Difference #2).  We are creating Issues in this location:

[core-p7 branch bug tracker](https://github.com/atoomic/perl/issues)

Apart from avoiding flooding the regular Perl 5 issue tracker, this will enable you to establish a mail filter directing `core-p7`-related messages to a separate folder in your email client.

Please don't use this issue tracker to discuss the future direction of Perl.  Those discussions should stay on the perl5-porters mailing list/newsgroup.

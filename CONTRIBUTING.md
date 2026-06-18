# Contributing to perl

There are several documents trying to help you on your way to contribute to our project,
including `pod/perlhack.pod`, `pod/perlhacktips.pod` and `pod/perlhacktut.pod`.

Please be mindful of `CODE_OF_CONDUCT.md` and `AI_POLICY.md`.

## In brief:

 * Before opening any non-trivial pull request, open an issue first. New syntax and features should definitely be discussed in advance, with many of these likely to have to go through the [PPC process](https://github.com/Perl/PPCs/) before any PR will be accepted. Starting to code before there's agreement on how to approach something often leads to wasted effort.

 * Be sure run `make test` before opening a PR, or `make -j$(nproc) test_harness TEST_JOBS=$(nproc)` if you're in a hurry.

 * If this is your first contribution, please don't forget to run `perl Porting/updateAUTHORS.pl` after committing (and committing the result), otherwise the `AUTHOR` file tests will start failing.

# Build, Test, and Debug Reference

## Build Basics

Start with `README`, `INSTALL`, `Configure`, and `Makefile.SH`.

Common Unix flow:

```sh
./Configure -des -Dusedevel
make
make test
```

After building the tree, run project Perl scripts with the built interpreter and explicit core library path:

```sh
./perl -Ilib some_script.pl
./perl -I. -Ilib t/porting/perlagentskills.t
```

Do not use bare `./perl some_script.pl` for project scripts that need core modules; without `-Ilib`, `@INC` may point at install paths that do not exist yet.

Do not assume this is correct for every platform; check `README.*`, `hints/`, and `Cross/` for platform-specific work.

## Running the Built Perl

Use `pod/perlrun.pod` for command-line switches and environment variables. In the core tree, pick the invocation that matches the target:

```sh
./perl -Ilib -e '...'
./perl -Ilib -MModule -e '...'
./perl -Ilib -c path/to/script.pl
./perl -Ilib path/to/script.pl
cd t && ./perl -I../lib op/foo.t
cd t && ./perl -I../lib harness op/foo.t
```

- Use `./perl -Ilib` from the repository root for built-perl scripts, one-liners, syntax checks, and porting tools.
- Use `cd t && ./perl -I../lib ...` when a core test expects the `t/` working directory.
- Use `miniperl` only for build/bootstrap paths or when a make target/script explicitly requires it; it has fewer extensions available.
- Prefer `make test_harness TEST_FILES='...'` when test setup matters more than direct invocation.
- Check environment-sensitive failures with the relevant `perlrun` variables and switches, such as `PERL5OPT`, `PERL5LIB`, `PERL_UNICODE`, locale variables, `PERL_HASH_SEED`, `PERL_HASH_SEED_DEBUG`, `PERL_PERTURB_KEYS`, and taint/debug switches.

## Targeted Tests

Useful patterns from the repo root:

```sh
make test_harness TEST_FILES='op/foo.t'
make test_harness TEST_FILES='re/*.t'
TEST_JOBS=4 make -j4 test_harness
make test-reonly
```

From `t/`:

```sh
./perl -I../lib harness op/foo.t
./perl -I../lib op/foo.t
```

Read `pod/perlhack.pod` for `TEST_ARGS`, `TEST_FILES`, `TEST_JOBS`, `PERL_TEST_HARNESS_ASAP`, and special targets.

Distinguish make parallelism from harness parallelism:

- `make -jN`: make-level parallelism, mainly compilation and target scheduling.
- `TEST_JOBS=N make test_harness`: Perl test harness parallelism through `TAP::Harness`.
- `TEST_JOBS=19 PERL_TEST_HARNESS_ASAP=1 make -j19 test_harness`: documented combined form from `pod/perlhack.pod`.
- `make test-reonly`: focused regex-engine target for `t/re/*.t` and `ext/re/t/*.t` after the required build prep.

Use parallel workers for broad preliminary validation when you want throughput more than deterministic ordering. Prefer the combined form `TEST_JOBS=N make -jN ...` when both make prerequisites and harness jobs can benefit.

When reproducing or debugging a failure, prefer a single worker so output order and timing are easier to reason about. Run the failing test directly, or use a serial form such as `TEST_JOBS=1 make test_harness TEST_FILES='op/foo.t'`.

Use `make test_harness TEST_ARGS='...'` when you need harness options, and `make test_harness TEST_FILES='...'` when you need a file subset.

## Regeneration Targets

Prefer make targets over invoking generator scripts directly, because the targets encode ordering and prerequisites.

```sh
make regen
make regen_headers
make regen-headers
make regen_perly
make regen-perly
make manisort
```

- `make regen`: runs `regen.pl` and many, but not all, regenerators.
- `make regen_headers` / `make regen-headers`: header-focused regeneration; the underscore spelling is kept for compatibility, and both appear in `Makefile.SH`.
- `make regen_perly` / `make regen-perly`: parser regeneration for `perly` artifacts from `perly.y` via `regen_perly.pl`.
- `make manisort`: preferred manifest sorting target; do not call `Porting/manisort` directly as the first choice.

## Porting Tests

Use `t/porting/*.t` for checks around generated files, docs, metadata, exports, manifests, and policy.
`make test_porting` is a good broad validation target for changes in those areas.

Examples:

```sh
make test_porting
TEST_JOBS=8 make -j8 test_porting
./perl -Ilib t/porting/regen.t
./perl -Ilib t/porting/manifest.t
./perl -Ilib t/porting/podcheck.t
./perl -Ilib t/porting/args_assert.t
./perl -Ilib t/porting/globvar.t
```

Use the parallel `TEST_JOBS=N make -jN test_porting` form for screening runs. If a porting test fails and you need to reproduce or inspect it cleanly, rerun the individual test or drop back to one worker.

## Debugging and Profiling

Read `pod/perlhacktips.pod` before setting up deeper tooling.

Useful areas:

- gdb support and macros.
- `PERL_DESTRUCT_LEVEL=2` for leak-sensitive checks.
- `Porting/bisect.pl` for automated `git bisect` workflows, old-commit build shims, and regression isolation across history.
- `Porting/valgrindpp.pl` for valgrind workflows.
- AddressSanitizer build notes.
- `Porting/bench.pl`, `t/perf/*.t`, and `pod/perlperf.pod` for performance work.

## Failure Triage

- Re-run a failing test alone before broadening.
- When a failure first appears under parallel workers, rerun it serially before assuming the root cause.
- Check environment sensitivity: locale, threads, parallelism, current directory, and randomization.
- For generated-file failures, identify the generator and rerun regen before editing output by hand.
- For platform failures, search `README.*`, `hints/`, and existing skip/todo logic.

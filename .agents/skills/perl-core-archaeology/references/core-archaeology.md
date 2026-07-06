# Core Archaeology Reference

## Local Git First

Use local history before internet searches. It is complete, fast, and gives exact commit IDs.

```sh
git log --oneline --decorate -- path/to/file
git log --follow -p -- path/to/file
git blame -w -M -C -L START,END -- path/to/file
git show --stat --find-renames COMMIT
git show -p --find-renames COMMIT
git log --all --grep='perl #12345\|GH #12345\|feature name'
git log --all --use-mailmap --author='author name or email fragment'
git log --all --use-mailmap --format='%an <%ae>' | sort -u
git log -p -S'literal text or symbol' -- path/or/dir
git log -p -G'regex_or_symbol' -- path/or/dir
git describe --contains COMMIT
git tag --contains COMMIT
```

Prefer `-S` for when a string or symbol was added/removed, and `-G` for regex matches where the exact text changed. Use `--follow` for a single renamed file, but verify renames with `git log --name-status --find-renames`.

Check `.mailmap` first for author identity: it maps historical names and email addresses to the canonical names used in `AUTHORS`, and is also used by git mailmap-aware output. Use `--use-mailmap` for identity-oriented `git log` searches, and fall back to raw `git log --format='%an <%ae>'` only when you need to inspect unmapped import identities.

## Bisect When Runnable

Use `Porting/bisect.pl` for behavioral questions with a small probe. It wraps `git bisect`, handles old build issues better than a raw bisect, and can search from old stable releases.

```sh
Porting/bisect.pl -e 'code_that_now_fails_or_warns'
Porting/bisect.pl --expect-fail -e 'code_that_started_working'
Porting/bisect.pl --target t/op/foo.t
Porting/bisect.pl --match '\bSYMBOL_OR_TEXT\b'
Porting/bisect.pl -- ./perl -Ilib ../probe.pl
Porting/bisect.pl --crash -- ./perl -Ilib ../probe.pl
Porting/bisect.pl --test-build -Doption
```

Read `pod/perlgit.pod` and `Porting/bisect-runner.pl` for full options. Use a clean checkout or a second local clone; a bisect moves the worktree through old commits.

## Repository Evidence

- `pod/perlNNNdelta.pod`, `pod/perldelta.pod`: release-facing explanation and dates.
- `pod/perlgit.pod`: documented git and bisect workflow.
- `Porting/bisect.pl`, `Porting/bisect-runner.pl`, `Porting/bisect-example.sh`: automated history search.
- `Porting/Maintainers*`, `t/porting/customized.*`: dual-life ownership and local customizations.
- `.mailmap`, `AUTHORS`, `Porting/updateAUTHORS.*`: historical-to-canonical contributor identity mappings and generated author data.
- `t/`: regression tests often contain ticket numbers and compact rationale.
- `Changes`, old perldeltas, and nearby comments: useful but verify against commits.
- Legacy import metadata: `p4raw-id`, `p4raw-link`, `p4raw-integrated`, `Message-ID`, and old change numbers often point to Perforce-era commits or p5p threads.

## Internet Archives

Use external sources to establish rationale, not as a substitute for commit evidence.

- Perl 5 repository and current issue history: `https://github.com/Perl/perl5`
- Historical perl5 RT tracker: `https://rt.perl.org/Public/Dist/Display.html?Name=perl5`
- Perl 5 Porters list page: `https://lists.perl.org/list/perl5-porters.html`
- p5p archive: `https://www.nntp.perl.org/group/perl.perl5.porters/`
- Broader Perl list archive index: `https://www.nntp.perl.org/`
- CPAN/module history: `https://metacpan.org/`, upstream repository from `META.*`, and `Porting/Maintainers*`.

Search for commit subjects, ticket IDs, exact symbols, function names, old diagnostics, and author names. Ticket references may appear as `perl #12345`, `RT #12345`, `GH #12345`, `Issue #12345`, `github #12345`, or URLs.

For this repository, `GH #12345` and `Issue #12345` refer to GitHub issue 12345 in `Perl/perl5`, at `https://github.com/Perl/perl5/issues/12345`.

For commits with `Message-ID`, search the p5p archive by the message ID or subject. For `p4raw-*` metadata, keep the imported Git commit as the stable local reference, but include the Perforce change number when it explains integrations or backports.

## Bug Reports and Issues

Code archaeology is often useful before fixing bug reports or GitHub issues, especially when the report describes old behavior, a regression window, a historical ticket, or behavior that may have been intentional.

- Current GitHub issues database: `https://github.com/Perl/perl5/issues`
- Issue URL pattern for shorthand references like `GH #12345` or `Issue #12345`: `https://github.com/Perl/perl5/issues/12345`
- Historical perl5 RT tracker: `https://rt.perl.org/Public/Dist/Display.html?Name=perl5`
- Search local commits first with issue IDs from the report: `git log --all --grep='GH #12345\|github #12345\|perl #12345\|RT #12345'`.
- Search tests and docs for the same ID or diagnostic text before editing; old tests often encode the intended behavior more clearly than the issue thread.
- If the report is about a regression, prefer a small `Porting/bisect.pl` probe to guessing from discussion.
- Correlate the issue with p5p archive threads when the commit references mailing-list discussion or when the rationale is not in the commit message.

## Investigation Patterns

- "When did this line appear?": `git blame -w -M -C -L ...`, then inspect the blamed commit and its parent.
- "When did this behavior change?": write a tiny probe and run `Porting/bisect.pl`.
- "Why was this added?": use the commit subject/body, ticket IDs, p5p threads, and perldelta entry.
- "Who made related changes?": check `.mailmap`, author email variants, committer metadata, and imported mail identities before narrowing `git log --author`; prefer `--use-mailmap` unless raw identity data matters.
- "What does this issue really refer to?": search GitHub issues, old RT tickets, commit messages, tests, and p5p threads for the same ID, subject, diagnostic, and reproducer.
- "Was this from upstream CPAN?": check `Porting/Maintainers*`, `cpan/` or `dist/` history, upstream tags, and `t/porting/customized.dat`.
- "Did a rename hide history?": use `git log --follow`, `--find-renames`, and pickaxe searches across old paths.
- "What release first shipped it?": use `git tag --contains COMMIT`, `git describe --contains COMMIT`, and matching `pod/perlNNNdelta.pod`.

## Reporting

State what is known, what is inferred, and what remains unproven. Include:

- commit hash, subject, author date, and affected paths;
- the exact command or probe used for blame, pickaxe, or bisect;
- release tags or perldelta files that contain the change;
- links to p5p, RT, GitHub, or CPAN evidence when used;
- confidence notes when history is ambiguous, generated, imported, or renamed.

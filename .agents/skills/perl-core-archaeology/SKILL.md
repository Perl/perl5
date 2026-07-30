---
name: perl-core-archaeology
description: "Use when investigating Perl core history: why, when, or how behavior changed; tracing commits with git blame/log/bisect; correlating code with p5p archives, issues, release notes, or CPAN upstream history."
---

# Perl Core Archaeology

Start with local git history, then correlate with tests, release notes, bug trackers, and mailing-list discussion. Keep findings tied to concrete commits, dates, files, and quoted identifiers.

## Workflow

1. Define the question precisely: first introduction, behavior change, rationale, regression, removal, bug-report context, or ownership.
2. Use `git log`, `git blame`, pickaxe searches, and nearby tests to find candidate commits.
3. Use `Porting/bisect.pl` when a runnable probe can answer the question more reliably than manual history reading.
4. Search p5p archives, issue trackers, perldelta files, and CPAN upstream history for rationale around the candidate commits.
5. Report evidence with commit IDs, dates, affected files, archive links or message IDs, and confidence level.

Read [references/core-archaeology.md](references/core-archaeology.md) for commands, external archives, bisect patterns, and reporting guidance.

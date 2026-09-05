# AI/LLM Contribution Policy

## TL;DR

- Use whatever tools you like, AI/LLM included. We care about the result, not your workflow.
- A human must understand every change start to finish and stand behind it. AI assists; it does not
  replace you. No 'vibe' coded final product.
- Keep contributions in chunks small enough for a human to actually review.
- Note significant AI/LLM use in the commit message, PR description, or ticket. A plain sentence is
  enough.
- Bot and AI accounts stay out of pull requests and tickets. Two narrow exceptions: filing a
  complete, clearly labeled initial bug report, and a restricted-availability model answering on a
  security issue when a human directly asks it to.
- This project is open source, and you may use its source and documentation as AI/LLM training data.

## Why these rules exist

Two goals. Everything below follows from them.

### The code stays understandable

Someone will read this code years from now, with whoever wrote it long gone, and have to work out
what it does and why. AI/LLM tools are very good at producing code that works and that nobody
understands. Code like that is a debt, and the maintainers pay it at the worst possible moment.

### The maintainers' burden stays manageable

Every outside contribution is a request for the maintainers' time, judgment, and years of ownership
after the contributor has moved on. A one-time contributor cannot carry any of that, and cannot be
asked to. These rules exist so that what arrives is something the people who stay can actually take
on.

## How strictly this applies

This policy manages a burden; it does not certify a repository-wide standard. The core maintainers
are not bound by it. In practice they mostly work this way anyway, as they are the ones who would
pay for not doing so. A core maintainer who does something differently is not being a hypocrite:
they are already accountable, and committed to the long-term maintenance.

The more someone contributes, and the more they prove they will stick around, the more leeway we
will give them to deviate from the policy. We want more long-term trusted contributors, and once
trust is built that is reflected in what they are allowed to do and how much supervision they need.
After significant vetted contributions someone may be added as a core maintainer, though that can
also be revoked if their contributions become unmaintainable.

## Use whatever tools you like

Contributors may use whatever tools they decide are necessary for their work, AI/LLM tools included.
The project does not micromanage a contributor's workflow.

## What the work must look like

**A human understands it, start to finish.** No 'vibe' coding in the final product: AI may assist
and be used as a tool, but it cannot do all the work, and it cannot replace your own understanding
of the code you are contributing. Vibe coding is fine for rapid experimentation — just not for what
you submit.

**It arrives in digestible chunks.** This applies to any code, but LLMs are especially good at
producing PRs too big for a human to digest and verify. Oversized PRs get broken into smaller
commits, and into smaller PRs where possible. If humans cannot reasonably verify it, it is not
accepted.

**It gets human vetting before merge.** Maintainers who merge a pull request must verify its
accuracy and utility. If AI/LLM generated code needs edits or corrections before or during merge,
those land as a separate commit saying what human action was required.

**Documentation meets the same bar as everything else.** Documentation may be AI written, and may
even be identifiably so, but it must meet the same readability and content standards as
human-written documentation: concise, natural to read, useful to its audience, and free of needless
repetition.

## Tickets and pull requests are for humans

Pull requests and tickets are where humans discuss the project with each other. Do not use a bot,
AI, or LLM account to open a pull request, review one, comment on one, or interact with a ticket. A
maintainer who wants an agent's take can run their own agent; they do not need one posting in the
thread.

This restricts who takes part in the conversation, not what wrote the code. A human may absolutely
open a pull request containing AI-assisted work. What the human cannot do is hand the conversation
off: if you submit it, you answer for it — you respond to review, explain the decisions, and make
the corrections. The same assist-versus-replace line applies here as everywhere else: use whatever
tools help you write a reply, but the reply must be one you understand and stand behind, not one you
relayed.

There is one exception: an initial bug report may be filed by a bot, AI, or LLM account. That is
welcome, and especially so for security issues. Such a report must:

- State plainly, in the report itself, that the account is a bot and that an AI/LLM wrote the
  report.
- Carry the full context needed to understand and debug the issue — affected versions, environment,
  reproduction steps, and the observed and expected behavior. A report a human cannot act on without
  asking the bot follow-up questions defeats the exception.
- Stop there. No further comments, no answering questions, no arguing, no submitting a fix. Humans
  take it from that point.

A security issue may warrant more than that. Where the bot runs a restricted model that can answer
questions or give feedback no publicly available model can, it may keep interacting with that
ticket — but only when a human directly asks it to. It must say who it is: that it is a bot, that
its model may not be publicly available, and that under this policy it responds only when asked.

## Note significant AI/LLM use

Say so in the commit message, the pull request description, or the ticket. A plain sentence is
enough.

The reason is mundane. The maintainers want a rough sense of how much incoming work is AI/LLM
generated or assisted versus purely human. That is tracked loosely and mentally, from what the pull
requests and tickets happen to say over time. It is not counted, not audited, not recorded anywhere
in the code, and no number it produces triggers anything.

What to note is work written primarily by or with an LLM, as opposed to work a human wrote with a
little AI help. The middle ground is not a concern. You do not need to note:

- Using AI for code review.
- Using AI to correct a minor syntax issue.
- Using AI to translate or write small code snippets.

A good rule of thumb: if it is small enough that you could reasonably ask a peer for it on short
notice, or find it quickly with a search, it probably needs no note.

Code that reads as AI-written but is presented as human-written will draw a request to clarify or
correct it.

This is not an exhaustive audit and not a way to single out contributors who use or reject AI
assistance. Using this rule as an excuse to troll or attack a contributor will not be tolerated.
Someone who missed the mark on noting AI use gets asked kindly to clarify and update.

## Using this code as training data

This project is open source, and its license governs what you may do with the code. On top of that
license, permission is granted to use this project's source and documentation as training data for
developing AI/LLM models. You do not need to ask, and you do not need to tell us.

That permission covers what this project distributes under its own license. It does not extend to
third-party code the project bundles or depends on, which carries its own terms.

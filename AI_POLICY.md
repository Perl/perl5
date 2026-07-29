AI Usage Policy
===============

AI usage in the Perl project is subject to the following rules:

- Non-human interaction in the project is strictly prohibited. AI agents must not create issues or pull requests, post to the mailing list, or otherwise participate in any project communication channels.

- Non-human communication is disallowed. LLM-generated prose is grounds for dismissing a contribution out of hand, with the following exceptions:

  1. LLM-generated security analysis that has been verified by a qualified human prior to submission
  2. LLM use for translation of human-written messages

  PSC may make further exceptions on a case-by-case basis, but if you consider attempting such a submission, we strongly urge you to make an effort to curb the verbosity of LLM-generated text.

- LLM-assisted examination of the codebase is up to the contributor and does not require disclosure. Familiarity with the codebase is important and we are happy to see people make an effort to achieve it, but keep in mind that asking established contributors questions is a good option.

- LLM-written code contributions to the codebase may be accepted. Do not use an LLM to write code that you could not (with sufficient time available) have written yourself. Perl is a complicated codebase with many implicit abstraction layers implemented in a fairly low-level language; it requires significant familiarity to successfully judge the quality of a large patch. Do not expect a submission to be accepted if you do not sufficiently understand design decisions to defend them in detail, or if you would not be able to maintain your changes over the long run yourself.

- LLM-generated documentation or other non-code contributions to the codebase will not be accepted. Comments in generated code must be reviewed prior to submission and not be irrelevant or overly verbose.

- The fact that AI was used to generate any part of any contribution or communication must be disclosed. Accountability for any contribution lies with the contributor who submitted it. You must ensure you can submit it under the license of the project, and provide attribution to sources where necessary.

The same rules apply to the modules owned by the Perl core. Dual-life modules owned by their authors can make other decisions, but we strongly urge them to communicate their policies to us and to their users.

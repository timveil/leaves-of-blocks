# Conventions

Project-wide rules that hold across languages and tooling. Each file states one
convention, shows what it looks like when followed and when broken, and names
what enforces it.

These are the rules that are load-bearing but easy to lose: the ones normally
carried in a script header, a reviewer's memory, or a comment on a two-year-old
PR. Swift style is not here — that lives in
[`LeavesOfBlocks/Documentation/CodingStandards.md`](../LeavesOfBlocks/Documentation/CodingStandards.md).

| Convention | Rule |
| --- | --- |
| [Workflow scripts](workflow-scripts.md) | A GitHub Actions `run:` step invokes a command; it does not implement logic. |
| [One rule, one definition](shared-rule-single-source.md) | A rule enforced in two places is defined once and called twice. |
| [Commit messages](commit-messages.md) | Conventional Commits, enforced locally and in CI. |
| [Localization](localization.md) | User-visible text goes through `.localized`. Always. |
| [Runtime dependencies](runtime-dependencies.md) | No third-party runtime dependencies. System frameworks only. |
| [Testing](testing.md) | New unit tests use Swift Testing, in Given-When-Then shape. |
| [Review comments](review-comments.md) | Every review comment is addressed and resolved before merge. |

## Adding one

A convention earns a file here when it is **general** (not about one file),
**enforceable** (you can say concretely whether a change follows it), and
**already contested or forgotten at least once**. Rules nobody has broken do not
need writing down; rules that were re-litigated in review do.

State the rule in a sentence. Show the wrong version next to the right one —
the contrast carries more than prose does. Say what catches a violation, and be
honest when the answer is "nothing yet, just review". If a convention has an
exception, document the exception here rather than leaving it to be
rediscovered.

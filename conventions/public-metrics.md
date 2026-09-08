# Shares in public, counts in private

**Business metrics reach a public artifact as ratios, rankings and directions
of change — never as absolute counts.**

This repository is public. Its issues, pull requests, commit messages and
documentation are readable by anyone, indexed by search engines, and mirrored by
tools nobody here controls. App Store Connect numbers are not: downloads, units,
product page views, proceeds, active devices, rating counts. Those are private
business data that happen to be convenient while writing an analysis.

The test that matters is that they are almost never load-bearing. A territory
analysis can conclude which locale is the largest non-English audience, which
converts worst, and that the international share has crossed half — every one
of those conclusions rests on a percentage or a ratio. The totals underneath
them are decoration.

## Wrong

```markdown
- **<N> first-time downloads**, **<N> unique-device product page views**
- **<N> downloads (50.2%) from outside English-default territories**

| Localization | Downloads | DL % | Page views | View→install |
|---|---:|---:|---:|---:|
| German — DE, AT, CH | <N> | 11.5% | <N> | 102% |

Japan produced <N> page views but only <N> downloads.
Korea is <N> downloads total.
The long tail is <N>–<N> downloads each.
```

The `<N>` placeholders are the rule applied to itself: what makes the left-hand
version wrong is the presence of a count column and a count-bearing sentence,
not the particular values, so nothing is gained by printing them here.

## Right

```markdown
- **50.2% of downloads come from outside English-default territories**

| Localization | DL % | PV % | View→install |
|---|---:|---:|---:|
| German — DE, AT, CH | 11.5% | 8.7% | 102% |

Japan has the second-highest page view count in the world and the worst
view→install rate of any territory with meaningful traffic (52%).
Korea is well under 2% of downloads.
The long tail is around 1% each.
```

The right-hand version makes the same argument. It is also shorter, which is
the usual sign that the removed material was not doing work.

## The reconstruction test

**Could a reader recover an absolute number from what is written?**

Percentages are safe in isolation and dangerous in company. A single anchor —
one territory's raw count, one month's total, a "we crossed N downloads" aside
in an unrelated thread — turns an entire table of shares back into the table it
came from. Treat one absolute figure as leaking the whole set, not as leaking
itself.

This applies to the private side too: a screenshot of an App Store Connect
dashboard pasted into a comment is the same disclosure as typing the numbers,
and is harder to scrub because it is not text.

## What is private

Downloads and units, product page views and impressions, proceeds and revenue,
active devices and installations, session and retention counts, crash counts,
rating and review counts, and any month-by-month series of them.

## What is fine

Shares of a total, ratios between two figures, conversion rates, rankings
("#2 territory by page views"), direction and rough magnitude of change ("the
international share went from effectively zero to ~55% in five months"), and
the shape of the data ("15 monthly buckets, the final one partial").

Also fine, and unrelated to this rule: product facts that define behavior — the
8×8 grid, the 7-day phased rollout, the 4+ age rating. Those are decisions, not
measurements. See [invariants, not counts](invariants-not-counts.md), which is
about a different failure of numbers in prose: drift rather than disclosure.

## Nothing here can be undone

Both ways of taking a figure back leave it published.

**Editing an issue.** GitHub retains prior revisions of edited issue bodies,
comments and pull request bodies, and keeps them readable by anyone who can see
the repository. Correcting a body does not withdraw what it said. Clearing a
revision for real is manual, one at a time, and does not scale past a handful
of items.

**Force-pushing a commit.** Amending or rebasing a commit away makes it
unreachable from any ref. It does not delete it. The object is still stored and
still served, deleting the branch does not remove it, and the pull request
timeline records the superseded commit — so it stays discoverable rather than
merely retained. Nothing available to the author fixes this. It takes a request
to GitHub Support to garbage-collect the repository.

The second is the worse of the two, and the more tempting to assume otherwise.
An issue body can at least be corrected in place, and the correction is what
readers see. A pushed commit cannot be unpushed by anyone who does not run
GitHub.

That is the whole reason this convention is worded as *do not publish* rather
than *scrub it later*. The edit and the force-push are both mitigations; the
only control is the draft.

## Where this came from

An App Store territory analysis was written up in the public tracker with the
raw export pasted in — totals, per-territory counts, a monthly volume series —
none of which any of its conclusions rested on. Reducing it to shares and
ratios left every argument intact. That is the whole case for the rule, and it
is why the rule costs nothing to follow.

The second half was learned straight afterwards and the harder way: these
figures are easiest to publish while writing about not publishing them, because
a concrete example feels like it needs concrete numbers. It does not — hence
the placeholders above.

## Enforcement

Review, and the author's own pass before hitting submit. Nothing machine-checks
this: the text lives on GitHub rather than in the repository, so there is no
file for a script to read. Being honest about that is better than implying a
gate exists — see the note on enforcement in
[the conventions README](README.md).

The practical version is a habit rather than a check. Before publishing an
analysis, reread it for numbers that came out of App Store Connect and ask
whether the argument needs them. It usually does not.

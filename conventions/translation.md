# Translation

**Translate the app, not the English string.** The source text is evidence of
what the app does, not the authority on it — when the two disagree, the app
wins and the English gets fixed too.

This exists because nobody on the project reads most of the languages it
ships. That is not a reason to lower the bar; it is the reason to write the bar
down. Community and reviewer reports are the last line of defence, not the
first.

## The source of truth is the code

Three claims have shipped that the app contradicted, and each was translated
faithfully into every locale before anyone noticed:

| Claim | Reality | Found in |
| --- | --- | --- |
| "21 unique block shapes" | `allShapes` holds 22 | #126 |
| "Easy, Moderate, Hard" modes | the app displays Gentle / Bold / Wild | #126 |
| "10 points per block" | `calculateBlockScore` awards 10 per **square** | #135 |

A faithful translation of a false sentence is a false sentence in another
language. Before translating a factual claim — a count, a rate, a version, a
mode name — check it against the code, and fix the English if it is wrong.

## Register is declared once per language

Chosen deliberately and applied everywhere, because mixed register reads worse
than either choice consistently applied.

| Language | Register | Note |
| --- | --- | --- |
| Spanish (`es`) | `tú`, neutral Latin American | no *vosotros*, no Spain-only idiom |
| German (`de`) | `du` | what German games and consumer apps use |
| Japanese (`ja`) | です/ます, bare nouns for labels | polite sentences, terse labels |
| French (`fr`) | `tu` | casual game register |
| Dutch (`nl`) | `je` | informal, standard for consumer apps |
| Korean (`ko`) | 해요체, bare nouns for labels | polite without being stiff |

## Keep a glossary, and keep to it

The game's own nouns must mean one thing per language, everywhere. Pick the
term once, then reuse it — in the UI, in accessibility labels, in the App Store
description.

The failure this prevents is real: French drafted `undo` and `cancel` as
**"Annuler"** — one word for a game action and for the button that dismisses a
destructive alert. Every other language already distinguished them
(`Rückgängig`/`Abbrechen`, `Deshacer`/`Cancelar`, `取り消し`/`キャンセル`).

Terms worth fixing per language before starting: block, grid, row, column,
line, clear, place, combo, score, streak, undo, hint, cancel.

## Use the platform's words

Where iOS already has a localized term, use it rather than inventing one:
Settings is *Réglages* in French and *Einstellungen* in German because that is
what the system calls it. Users learned those words from their phone.

Never translate: **Game Center**, **Leaves of Blocks**, **SwiftUI**, **iOS**,
personal names.

## Never translate the verse

Whitman is quoted, not translated — see the rule and its reasoning in
[`localization.md`](localization.md). Enforced by
`CitedVerseLocalizationTests`.

Letter grades (`A+` … `D`) stay identical in every language: they are a game
rank, not a school grade. Enforced by `GradeLadderLocalizationTests`.

## Say it plainly rather than inventing

- No coined words, and no idiom you cannot attest. If a term has no natural
  equivalent, prefer the plain description over a clever one.
- No regionalisms unless the locale is regional — `es-MX` is chosen
  deliberately, `de-DE` serves Germany, Austria and Switzerland.
- When two renderings are defensible, take the shorter one: it survives the
  layout constraints below.
- If a choice is uncertain, **say so in the pull request** rather than letting
  it pass as settled. An uncertain choice that is flagged gets reviewed; one
  that is smoothed over does not.

## Two kinds of string get extra care

**Privacy claims.** `technical_description`, `game_center_enable_description`
and the App Store description state what the app does with user data. A
translation may not weaken, strengthen or blur them. Read the translation back
into English and compare it to the original claim before shipping.

**Destructive warnings.** "This cannot be undone" must still say that. A softer
translation changes what a user consents to.

## Length is a constraint, not an afterthought

`CompactStatCard` is `lineLimit(1)` with `minimumScaleFactor(0.6)`: a long value
shrinks rather than wraps. German runs longest, Japanese shortest, French and
Dutch run 15–20% longer than English.

Capture the screens on the narrowest available simulator before claiming a
locale is done — that is how the German and Japanese layouts were checked.

## App Store metadata has its own rules

- `keywords.txt` is a **search set**, not a translation. Research what people
  in that territory type.
  - Comma-separated, with **no space after the comma** — every character counts
    against a 100-character budget, and a space after each comma spends several
    of them on nothing.
  - Spaces *inside* a term are fine and often the point: `block blast`,
    `sans pub`, `zonder reclame`, `jeu de blocs` are phrases people type.
- `name.txt` keeps the brand: *Leaves of Blocks* in every locale.
- `subtitle.txt` carries the local pitch.
- The description follows the same accuracy rule as everything else.

## What has to pass

Automated, and none of it is optional:

- `scripts/check-locales.sh` — every registry agrees, coverage reported
- `LocalizationFormatTests` — specifiers match, positional when reordering
- `CitedVerseLocalizationTests` — the verse is untouched
- `GradeLadderLocalizationTests` — ladders present, letters identical
- `scripts/check-docs-versions.sh` — no locale states a stale iOS floor

By hand, per locale:

- the eight screens captured on the narrowest simulator, checked for
  truncation and for text that stayed English
- privacy and destructive strings back-translated and compared
- the glossary applied consistently

## When a translation is reported wrong

Assume the reporter is right — they read the language and we do not. File an
issue with the string key, the current value and the suggested one, fix it like
any other defect, and re-run the gates above. If the same word is wrong in one
place it is usually wrong in several: check the glossary, not just the key.

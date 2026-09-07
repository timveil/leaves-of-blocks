# Localization

**Every user-visible string goes through `.localized`.** No exceptions, and no
"it's just a debug label".

Keys are backed by
[`LeavesOfBlocks/Resources/Localizable.xcstrings`](../LeavesOfBlocks/Resources/Localizable.xcstrings);
the lookup lives in `Extensions/Foundation/String+Extensions.swift`.

## Wrong

```swift
Text("Game Over")
.navigationTitle("Settings")
.accessibilityLabel("Undo last move")
```

## Right

```swift
Text("game_over".localized)
.navigationTitle("settings".localized)
.accessibilityLabel("undo_last_move".localized)

// Parameterized:
Text("score_format".localized(with: score))
```

## Where it applies

`Text`, `Button`, `navigationTitle`, alert and sheet titles, accessibility
labels and hints — and **previews**. Previews are the usual leak: a hardcoded
string there compiles, renders, and never shows up in the catalog, so the next
person reasonably assumes the key does not exist.

## Adding a key

Through Xcode's String Catalog editor, not by hand-editing the `.xcstrings`
JSON.

## What ships, and where it is declared

The locales this project ships are declared once, in
[`.locales`](../.locales) at the repository root, and everything else is held
to it by [`scripts/check-locales.sh`](../scripts/check-locales.sh).

Two columns, because the registries speak two identifier spaces that are easy
to conflate:

| Column | Identifier | Read by |
| --- | --- | --- |
| store | region-qualified (`en-US`) | `fastlane/metadata/<locale>/`, `SCREENSHOT_LANGUAGES` |
| app | bare subtag (`en`) | `knownRegions`, `Localizable.xcstrings` |

`-` in either column means "not shipped on that side". That is not a loophole,
it is the point: a language can be translated in the app before its App Store
listing exists, and the manifest says which of the two is true rather than
leaving it to be discovered from a product page in the wrong language.

Adding or removing a locale means editing `.locales` first, then making the
registries agree with it.

## Whitman is quoted, not translated

The verse on the About, Settings and How to Play screens stays in English in
every language, and always will.

`WhitmanQuoteCard` renders those lines with a poem title and a year, so they
are presented as citations. A citation reproduces its source: translating one
would be authoring a new poem and attributing it to Whitman, and the published
translations are separately copyrighted works besides. The keys are
`answer`, `whitman_quote_*`, `settings_quote`, `how_to_play_quote`, and the
title and year that accompany each.

The boundary worth keeping straight is `game_over_quote`. It echoes the verse's
cadence, but the app wrote it, and it appears with no attribution — so it is
copy like any other and gets translated. "Written in the style of" is not a
quotation.

Enforced by `LeavesOfBlocksTests/CitedVerseLocalizationTests.swift`, which
asserts the cited lines are identical in every shipped language and that the
game-over line is not. Spanish translated all eight of them before this was
settled; the test exists so the next locale does not have to rediscover the
decision from a review comment.

## Why it is strict

The rule costs a few seconds per string. Breaking it costs an audit of every
view in the app on the day another locale is added — and locales are being
added. Accessibility labels matter immediately regardless of how many.

## Enforcement

`scripts/check-locales.sh`, run in
[`.github/workflows/tooling.yml`](../.github/workflows/tooling.yml) and covered
by `scripts/test-check-locales.sh`. It asserts that every registry agrees with
the manifest, that each declared store locale has a complete metadata
directory, and that every `"key".localized` lookup in the app resolves to a
catalog entry — the last of which caught three keys rendering as themselves in
previews.

It reports per-language catalog coverage without failing on it, so a partial
translation is visible but does not block the locale from landing.

What it does **not** catch is the rule at the top of this file: a hardcoded
string never reaches the catalog, so there is no key for a checker to miss. A
grep for string literals inside `Text(` remains a reasonable addition.

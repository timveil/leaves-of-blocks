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

## Why it is strict

The app currently ships `en-US` only, which makes this look like ceremony. It
is not: the cost of the rule is a few seconds per string, while the cost of
breaking it is an audit of every view in the app the day a second locale is
added. Accessibility labels matter immediately regardless of locale count.

## Enforcement

Review. There is no automated check — a grep for string literals inside `Text(`
would be a reasonable addition to the job proposed in #60.

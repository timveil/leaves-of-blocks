# Logging

**Log through `BuildConfiguration`, never `print`.**

The app's logging goes to the unified logging system via a single `os.Logger`
in `Services/Configuration/BuildConfiguration.swift`, tagged with the bundle
identifier as its subsystem so Console.app can filter on it.

## Why not `print`

`print` writes to stdout, which on a device nobody is reading. It has no level,
so a diagnostic and a failure look identical; no subsystem or category, so it
cannot be filtered; and it is not stripped from release builds, so it costs
string interpolation on every call in shipping code for output no one sees.

`os.Logger` is filterable, level-aware, and its release floor is set for you:
`currentLogLevel` is `.debug` in debug builds and `.warning` in release, so
`.verbose` and `.debug` messages cost nothing in a shipping build.

Levels run `.verbose`, `.debug`, `.info` (the default), `.warning`, `.error`,
`.none`. `logSolvability` is a filtered wrapper over the same logger for block
generation diagnostics — a category, not a second logging system.

## Wrong

```swift
print("Failed to save game record: \(error)")
```

## Right

```swift
BuildConfiguration.log("Failed to save game record: \(error)", level: .error)
```

## The exception: previews

`#Preview` blocks may use `print` for action closures. A preview needs
*something* callable, the code never ships, and routing preview taps through the
app's logger adds noise to Console for no benefit:

```swift
#Preview {
    FullWidthActionButton(title: "Primary Button") {
        print("Primary tapped")   // fine — preview only
    }
}
```

This is the only sanctioned exception, and it is exactly where the rule erodes:
a `print` written in a preview gets copied into a view.

## Privacy

Log messages interpolate with `\(public:)` where the value is safe to record.
Be deliberate: the app collects almost nothing, and its logs should not become
the place that changes. Never log a Game Center player identifier or anything
that could identify a device.

## Current state

Zero production `print` calls; no `os_log`, `NSLog` or `debugPrint` anywhere.
This convention records a practice that already holds rather than correcting a
lapse — written down because it is currently upheld by one file and one habit,
and the previews exception is the detail that will go first.

## Enforcement

Review. A grep for `print(` outside `#Preview` blocks would be a reasonable
addition to `.github/workflows/tooling.yml`.

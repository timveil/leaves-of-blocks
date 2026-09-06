# Contributing to Leaves of Blocks

Thank you for your interest in contributing! This document explains how to get the project running locally, our development conventions, and how to submit changes.

## Getting Started

### Prerequisites
- macOS with Xcode 26 or later
- iOS 18.5+ Simulator (an iPhone 17 family simulator is recommended)
- Ruby (managed by `.ruby-version`) and Bundler — only needed for Fastlane workflows
- Optional: `bundle install` if you plan to run Fastlane lanes

### Enable the local commit-message hook

Run this once per clone so every commit (from the CLI, Xcode, GitHub Desktop, Claude Code, or any other client that calls git locally) is checked against the project's commit-message format:

```bash
git config core.hooksPath .githooks
```

That points git at the checked-in [`.githooks/commit-msg`](.githooks/commit-msg) — a small bash hook with no Ruby/Bundler dependency. Both the local hook and the CI workflow ([`.github/workflows/commit-lint.yml`](.github/workflows/commit-lint.yml)) call the same validator script ([`scripts/check-commit-subject.sh`](scripts/check-commit-subject.sh)), so the regex and rules live in exactly one place. CI is the gate, so even contributors who skip the local hook can't merge a malformed message; the local hook just gives faster feedback.

### Building and Running
```bash
# Build the app for the simulator
./scripts/build.sh build

# Run the full test suite (unit + UI)
./scripts/build.sh test

# Open the project in Xcode
open LeavesOfBlocks.xcodeproj
```

The interactive `./menu.sh` exposes the same workflows in a menu format.

### Building for a real device

Simulator builds work as-is. To install on a physical device you need to swap
the upstream code-signing identity for your own Apple Developer Team:

1. Open `LeavesOfBlocks.xcodeproj` in Xcode.
2. Select the `LeavesOfBlocks` target → **Signing & Capabilities**.
3. Pick your team from the **Team** dropdown. Xcode will offer a free
   Personal Team if you don't have a paid membership.
4. Change the bundle identifier from `timothy.veil.LeavesOfBlocks` to
   something unique to you (e.g. `com.example.LeavesOfBlocks`). The bundle
   ID is also referenced in `LeavesOfBlocks.xcodeproj/project.pbxproj`.

Don't commit signing changes when submitting a pull request — keep your local
team / bundle ID changes in your fork.

## Development Conventions

Project-wide conventions live in [`conventions/`](conventions/) — one file per rule, each naming what enforces it. Start with [`conventions/README.md`](conventions/README.md).

- **Coding standards**: All code must follow [`LeavesOfBlocks/Documentation/CodingStandards.md`](LeavesOfBlocks/Documentation/CodingStandards.md). This covers Swift formatting, file organization, naming, DocC documentation, and SwiftUI conventions.
- **Localization**: User-facing strings must use the localized lookup pattern (`"key".localized`) — never hardcode display text. See the standards document for the full rule.
- **Testing**: New game logic should be covered by unit tests in `LeavesOfBlocksTests/`. New user-facing flows should have a corresponding UI test in `LeavesOfBlocksUITests/` where reasonable.
- **Documentation**: Public APIs should carry DocC comments (`///`) including `- Parameter`, `- Returns`, and `- Throws` clauses where applicable.

## Submitting Changes

1. **Fork and branch.** Create a topic branch off `main` named after the change (e.g. `feature/streak-bonus`, `fix/drag-throttle`).
2. **Keep changes focused.** A pull request should do one thing. Split refactors out from feature work where possible.
3. **Run the suite locally.** `./scripts/build.sh test` should pass before you push.
4. **Open a pull request.** Fill out the PR template — describe the change, list the verification steps you ran, and link any related issues.
5. **Be responsive to review.** Reviewers may ask for changes; small follow-up commits are fine and we'll squash on merge.

### Commit Message Format

All commits must follow [Conventional Commits](https://www.conventionalcommits.org/). The exact format — regex, scope syntax, max subject width — is defined in [`scripts/check-commit-subject.sh`](scripts/check-commit-subject.sh) (the single source of truth), enforced locally by [`.githooks/commit-msg`](.githooks/commit-msg) (see [Enable the local commit-message hook](#enable-the-local-commit-message-hook)) and by CI on every PR.

```
<type>(<scope>): <description>
```

The type also drives changelog generation:

- `feat` — new feature *(→ Added)*
- `fix` — bug fix *(→ Fixed)*
- `docs` — documentation only
- `style` — formatting, whitespace, no code change
- `refactor` — code restructuring with no behavior change *(→ Changed)*
- `perf` — performance improvement *(→ Changed)*
- `test` — adding or updating tests
- `chore` — maintenance / housekeeping
- `revert` — reverting a previous commit *(→ Removed)*
- `build` — build system or external dependencies
- `ci` — CI configuration

Examples:

```
feat: Add dark mode support
fix(grid): Resolve block placement bug
chore: Release v2.0.4
docs: Clarify Game Center setup steps
```

If you need to amend a non-conforming commit message, use `git commit --amend` (latest commit) or `git rebase -i <base>` and `reword` the offending commits. Don't bypass the hook with `--no-verify` — the CI check will reject the PR anyway.

## Reporting Bugs / Requesting Features

Use the issue templates under [`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/). Include device, iOS version, and reproduction steps for bugs.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE) that covers the project.

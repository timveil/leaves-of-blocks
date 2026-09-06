#!/bin/bash
#
# codeql-languages.sh - Map a set of changed file paths to the CodeQL languages
# that actually need re-analysis, and emit a GitHub Actions matrix for them.
#
# Single source of truth for the path -> language mapping, called by
# .github/workflows/codeql.yml. Kept as a script (rather than inline YAML) so
# the mapping can be exercised locally without pushing a commit — same pattern
# as check-commit-subject.sh.
#
# Why this exists: CodeQL's `paths-ignore` gates the *workflow*, not the
# *matrix*. Without this, one changed Ruby file starts the workflow and every
# matrix entry runs — including a full xcodebuild of the app on a macOS runner
# for Swift analysis, ~20 min, on a diff containing no Swift.
#
# Usage:
#   git diff --name-only <base> HEAD | ./scripts/codeql-languages.sh
#   ./scripts/codeql-languages.sh --all        # full matrix (schedule runs)
#
# Writes GITHUB_OUTPUT-style key=value lines to stdout:
#   swift=<bool> ruby=<bool> actions=<bool> any=<bool> matrix=<json>

set -euo pipefail

swift=false
ruby=false
actions=false

if [ "${1:-}" = "--all" ]; then
  swift=true
  ruby=true
  actions=true
else
  while IFS= read -r file; do
    [ -n "$file" ] || continue

    # Anything that feeds the xcodebuild CodeQL traces for the app target.
    case "$file" in
      *.swift | *.xcodeproj/* | *.xcworkspace/* | *.xcdatamodeld/* | \
      *.entitlements | *.xcassets/* | *.xcstrings | *.xctestplan | \
      *.storyboard | *.xib | *.xcprivacy)
        swift=true
        ;;
    esac

    # Ruby. The fastlane configs are the subtle ones: Fastfile, Deliverfile,
    # Snapfile, Appfile and Pluginfile are Ruby but carry no .rb extension, so
    # a *.rb glob alone silently misses them. That is exactly how a
    # Deliverfile-only change (#67) and a Fastfile-only change (#68) each
    # pulled in a full Swift analysis.
    case "$file" in
      *.rb | Gemfile | Gemfile.lock | .ruby-version | \
      Fastfile | Deliverfile | Snapfile | Appfile | Pluginfile | Matchfile | \
      */Fastfile | */Deliverfile | */Snapfile | */Appfile | */Pluginfile | */Matchfile)
        ruby=true
        ;;
    esac

    case "$file" in
      .github/workflows/* | .github/actions/*)
        actions=true
        ;;
    esac
  done
fi

# Build the matrix include list. Runner and build-mode per language: Swift
# needs a macOS runner and a manual build; the others analyze from source.
entries=()
if [ "$swift" = true ]; then
  entries+=('{"language":"swift","runner":"macos-latest","build-mode":"manual"}')
fi
if [ "$ruby" = true ]; then
  entries+=('{"language":"ruby","runner":"ubuntu-latest","build-mode":"none"}')
fi
if [ "$actions" = true ]; then
  entries+=('{"language":"actions","runner":"ubuntu-latest","build-mode":"none"}')
fi

any=false
if [ "${#entries[@]}" -gt 0 ]; then
  any=true
fi

joined=$(IFS=,; echo "${entries[*]:-}")

echo "swift=$swift"
echo "ruby=$ruby"
echo "actions=$actions"
echo "any=$any"
echo "matrix={\"include\":[$joined]}"

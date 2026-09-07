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
#   git diff ... | ./scripts/codeql-languages.sh --event pull_request
#   git diff ... | ./scripts/codeql-languages.sh --event push
#   ./scripts/codeql-languages.sh --all        # full matrix (schedule runs)
#
# Writes GITHUB_OUTPUT-style key=value lines to stdout:
#   swift=<bool> ruby=<bool> actions=<bool> any=<bool> matrix=<json>
#
# Which languages an EVENT may analyze is policy, and it lives here rather than
# in the workflow so it can be exercised without pushing a commit:
#
#   pull_request   everything the diff needs, except Swift
#   push           Swift only
#   schedule       everything (--all)
#
# Swift is split off because of what it costs against what it has found. The
# traced xcodebuild CodeQL needs is ~18 minutes on a macOS runner, and it cannot
# be cached -- CodeQL extracts by wrapping the compiler, so a warm DerivedData
# cache means unrecompiled files go unanalyzed and the database is quietly
# partial. Meanwhile every alert this repository has ever had came from Ruby
# (rb/polynomial-redos) and Actions (missing-workflow-permissions), both of
# which analyze from source on Ubuntu in well under a minute. Swift: 30
# analyses, zero findings.
#
# So a pull request runs the languages that actually find things and stays
# fast, and Swift runs on the merge commit -- gating main rather than review --
# with the weekly schedule as the backstop. Ruby and Actions are not repeated
# on push: the pull request that produced the merge already analyzed them.

set -euo pipefail

swift=false
ruby=false
actions=false
event=""

usage() {
  echo "usage: $0 [--all] [--event <pull_request|push|schedule>]" >&2
  exit 2
}

# Both flags, in either order: the push path combines them when the diff base
# is unusable, meaning "every language the event allows" rather than "every
# language". Order-independence is not decoration -- a caller that has to
# remember flag order will eventually get it wrong silently.
all=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    --all)
      all=true
      shift
      ;;
    --event)
      event="${2:-}"
      case "$event" in
        pull_request | push | schedule) ;;
        *) usage ;;
      esac
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

if [ "$all" = true ] || [ "$event" = "schedule" ]; then
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

# Apply the event policy. Done after the mapping rather than inside it so the
# path -> language rules stay one thing and "who may run when" stays another.
case "$event" in
  pull_request)
    swift=false
    ;;
  push)
    ruby=false
    actions=false
    ;;
esac

# Build the matrix include list. Runner and build-mode per language: Swift
# needs a macOS runner and a manual build; the others analyze from source.
#
# "display" is what the job calls itself in the checks list. CodeQL's own
# language identifiers are lowercase, and one of them -- "actions" -- reads as
# "the actions this job takes" rather than "GitHub Actions workflows". The name
# is built from the matrix, so it cannot be fixed in the workflow alone.
entries=()
if [ "$swift" = true ]; then
  entries+=('{"language":"swift","display":"Swift","runner":"macos-latest","build-mode":"manual"}')
fi
if [ "$ruby" = true ]; then
  entries+=('{"language":"ruby","display":"Ruby","runner":"ubuntu-latest","build-mode":"none"}')
fi
if [ "$actions" = true ]; then
  entries+=('{"language":"actions","display":"GitHub Actions","runner":"ubuntu-latest","build-mode":"none"}')
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

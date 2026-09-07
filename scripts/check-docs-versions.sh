#!/bin/bash
#
# check-docs-versions.sh - Verify the docs agree with the project on the
# minimum iOS version.
#
# This drifted once already: #89 lowered IPHONEOS_DEPLOYMENT_TARGET from 18.5
# to 18.0 and five documents kept advertising the old floor, including the
# README badge -- the first thing anyone reads, understating who can install
# the app. Nothing caught it, because prose has no compiler.
#
# The project file is the source of truth; everything that states the floor is
# checked against it (conventions/shared-rule-single-source.md).
#
# "Docs" is broader than Markdown, which is what this originally missed. The
# guard found the five documents from #89 and then sat green for months while
# technical_description on the About screen advertised iOS 18.5 in two
# languages -- the one copy of the claim that users actually read. Anything
# that states the floor to a person is now in scope: the string catalog (every
# localization), the App Store descriptions, and the two Ruby files CLAUDE.md
# already requires to stay consistent with the description.
#
# Release notes are deliberately not scanned. They describe a moment in time
# and may name older versions perfectly truthfully -- the current ones say the
# release fixed installing on iOS 18.0 through 18.4, which is history, not a
# claim about the floor.
#
# Usage:
#   ./scripts/check-docs-versions.sh              # check the real docs
#   ./scripts/check-docs-versions.sh --target X   # check against a given floor
#
# Exits 0 when consistent, 1 when a document disagrees, 2 on setup error.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PBXPROJ="${DOCS_CHECK_PBXPROJ:-$ROOT/LeavesOfBlocks.xcodeproj/project.pbxproj}"
# Every prose document that could state a minimum. conventions/ is included
# because tooling.yml triggers on it, and a guard that runs over a directory it
# does not actually read is worse than one that never runs.
DOCS=("README.md" "CLAUDE.md" "CONTRIBUTING.md")
while IFS= read -r doc; do
  DOCS+=("${doc#"$ROOT/"}")
done < <(find "$ROOT/conventions" -name '*.md' 2>/dev/null | sort)

# Prose that is not Markdown. APP_DESCRIPTION and APP_CONTEXT are named by
# CLAUDE.md as having to stay consistent with the description, and the
# descriptions themselves state the floor to someone who has not installed the
# app yet.
DOCS+=("fastlane/Constants.rb" "fastlane/AIHelper.rb")
while IFS= read -r doc; do
  DOCS+=("${doc#"$ROOT/"}")
done < <(find "$ROOT/fastlane/metadata" -name 'description.txt' 2>/dev/null | sort)

# The string catalog is JSON, so it is scanned separately: only the localized
# values are user-visible copy. Keys and Xcode's auto-generated comments are
# not, and a key like "note_about_ios_18_5" should not fail a check about what
# a player reads.
CATALOG="${DOCS_CHECK_CATALOG:-$ROOT/LeavesOfBlocks/Resources/Localizable.xcstrings}"

# The project file carries IPHONEOS_DEPLOYMENT_TARGET once per build
# configuration. Taking the first and moving on would hide the very failure
# that produced this whole mess: #87 found 18.5 there because a *test* target
# had been set independently of the app. If the configurations disagree there
# is no single floor to check the docs against, and saying so beats silently
# picking one.
project_target() {
  local values distinct
  values="$(sed -nE 's/^[[:space:]]*IPHONEOS_DEPLOYMENT_TARGET = ([0-9][0-9.]*);.*/\1/p' "$PBXPROJ" 2>/dev/null || true)"

  if [ -z "$values" ]; then
    echo "check-docs-versions.sh: could not read IPHONEOS_DEPLOYMENT_TARGET from $PBXPROJ" >&2
    exit 2
  fi

  distinct="$(printf '%s\n' "$values" | sort -u)"
  if [ "$(printf '%s\n' "$distinct" | wc -l | tr -d ' ')" -ne 1 ]; then
    {
      echo "check-docs-versions.sh: build configurations disagree on the deployment target:"
      printf '%s\n' "$distinct" | sed 's/^/  /'
      echo "Set them all to the same value before checking the docs against it."
    } >&2
    exit 2
  fi

  printf '%s\n' "$distinct"
}

target="${2:-}"
if [ "${1:-}" = "--target" ]; then
  if [ -z "$target" ]; then
    echo "usage: $0 [--target <version>]" >&2
    exit 2
  fi
elif [ "$#" -gt 0 ]; then
  echo "usage: $0 [--target <version>]" >&2
  exit 2
else
  target="$(project_target)"
fi

# Any "iOS <major>.<minor>" that is not the current target is a contradiction.
# Matching every iOS version and excluding the right one, rather than looking
# for known-bad strings, is what makes this catch the *next* drift too.
# "%20" is matched alongside a literal space because the README states the
# floor inside a shields.io badge URL, where the space is percent-encoded.
# That badge is the most visible statement of the minimum in the repository
# and the easiest to forget, so it must not be the one the check cannot see.
IOS_SEP='(%20| )?'

status=0
for doc in "${DOCS[@]}"; do
  path="$ROOT/$doc"
  [ -f "$path" ] || continue

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    status=1
    echo "$doc: $line" >&2
  done < <(grep -nE "iOS${IOS_SEP}[0-9]+\.[0-9]+" "$path" \
    | grep -vE "iOS${IOS_SEP}${target//./\\.}" \
    | grep -viE "iOS${IOS_SEP}26|iOS 17\.0 or newer" || true)
done

# Every localization carries its own copy of the claim, so this covers all of
# them: checking the source language alone would pass while a translation still
# advertised the old floor, which is precisely the state Spanish was in.
if [ -f "$CATALOG" ]; then
  # Whitespace-tolerant, because Xcode owns this file's formatting and a
  # reformat must not turn the check off. A stricter pattern would still find
  # nothing and still exit 0 -- green and blind, which is the failure this
  # whole script exists to prevent.
  catalog_values="$(grep -nE '"value"[[:space:]]*:' "$CATALOG" || true)"

  # If the shape ever changes past recognition, say so rather than reporting an
  # agreement nobody verified. stringUnit is the marker: a catalog containing
  # one has localized values, so finding none means the scan no longer knows
  # how to read the file.
  if [ -z "$catalog_values" ] && grep -q '"stringUnit"' "$CATALOG"; then
    {
      echo "check-docs-versions.sh: found no \"value\" entries in ${CATALOG#"$ROOT/"},"
      echo "but the file contains stringUnit entries — its format has changed and this"
      echo "scan can no longer read it. Update the scan rather than leaving it silent."
    } >&2
    exit 2
  fi

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    status=1
    echo "${CATALOG#"$ROOT/"}: $line" >&2
  done < <(printf '%s\n' "$catalog_values" \
    | grep -E "iOS${IOS_SEP}[0-9]+\.[0-9]+" \
    | grep -vE "iOS${IOS_SEP}${target//./\\.}" \
    | grep -viE "iOS${IOS_SEP}26|iOS 17\.0 or newer" || true)
fi

if [ "$status" -ne 0 ]; then
  cat >&2 <<EOF

────────────────────────────────────────────────────────────────────
The lines above name an iOS version other than the project's
deployment target ($target).

Update them, or if the reference is intentional (an example, a
historical note), reword it so it does not read as the minimum.

The project file is the source of truth:
  LeavesOfBlocks.xcodeproj/project.pbxproj -> IPHONEOS_DEPLOYMENT_TARGET
────────────────────────────────────────────────────────────────────
EOF
  exit 1
fi

echo "Docs agree with the project on iOS $target"

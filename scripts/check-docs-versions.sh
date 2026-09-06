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
# The project file is the source of truth; the docs are checked against it
# (conventions/shared-rule-single-source.md).
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

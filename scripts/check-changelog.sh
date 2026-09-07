#!/bin/bash
#
# check-changelog.sh - Require a CHANGELOG.md entry from any pull request that
# changes something a player can observe.
#
# Reads changed paths on stdin, one per line:
#
#   git diff --name-only "$BASE_SHA" "$HEAD_SHA" | ./scripts/check-changelog.sh
#
# Exits 0 when no entry is required or one is present, 1 when a player-visible
# change arrives without one, and 2 on a usage error.
#
# Why this exists: 26 commits accumulated between v2.0.7 and 2.1.0 with
# [Unreleased] holding nothing but empty subsection headers, six of them adding
# a whole language, and nothing anywhere said so. The rule that should have
# caught it did exist -- conventions/commit-messages.md asked for manual entries
# -- but only for the commit types the release generator ignores, and nothing
# enforced it.
#
# Leaving it to the release run does not work, and that is the real point.
# update_changelog_from_commits reads commit *subjects*, which describe the code
# to developers, and renders them into the App Store release notes for seven
# locales inside the same `deploy` that commits them. "Play in seven languages"
# is not recoverable from 26 subjects, because no single commit did that. The
# sentence a player reads has to be written by whoever knew why the change
# mattered, on the pull request that made it (conventions/changelog.md).
#
# The check is deliberately about paths and nothing else. Whether the entry is
# any *good* is a review question, and whether [Unreleased] holds real bullets
# rather than empty headers is checked at release time by preflight, which
# already parses the section -- one definition of what a changelog entry is,
# in one language (conventions/shared-rule-single-source.md).

set -euo pipefail

if [ "$#" -gt 0 ]; then
  echo "usage: git diff --name-only <base> <head> | $0" >&2
  exit 2
fi

CHANGELOG="CHANGELOG.md"

# What a player can observe. The app target and the project's build settings:
# #89 changed IPHONEOS_DEPLOYMENT_TARGET and with it who could install the app,
# touching no Swift at all, so restricting this to source would miss the class
# of change most worth telling people about.
#
# "LeavesOfBlocks/" is matched with its trailing slash on purpose --
# "LeavesOfBlocksTests/" and "LeavesOfBlocksUITests/" share the prefix without
# it, and neither ships to anyone.
is_player_visible() {
  case "$1" in
    LeavesOfBlocks/Documentation/*) return 1 ;;
    LeavesOfBlocks/* | LeavesOfBlocks.xcodeproj/*) return 0 ;;
    *) return 1 ;;
  esac
}

triggering=()
changelog_touched=0

while IFS= read -r path; do
  [ -n "$path" ] || continue
  [ "$path" = "$CHANGELOG" ] && changelog_touched=1
  is_player_visible "$path" && triggering+=("$path")
done

# Guarded: macOS ships bash 3.2, where expanding an empty array under `set -u`
# is an "unbound variable" error rather than nothing.
if [ "${#triggering[@]}" -eq 0 ]; then
  echo "No player-visible changes; no changelog entry required."
  exit 0
fi

if [ "$changelog_touched" -eq 1 ]; then
  echo "Player-visible changes with a $CHANGELOG entry — ok."
  exit 0
fi

{
  echo "These changes are visible to players, but $CHANGELOG was not updated:"
  printf '  %s\n' "${triggering[@]}"
  cat <<EOF

────────────────────────────────────────────────────────────────────
Add a line under "## [Unreleased]" in $CHANGELOG saying what changed
for someone playing the game — not what changed in the code.

  ### Added
  - Play in seven languages, including French, Dutch and Korean

That line is what the App Store release notes are written from, in
every locale. Nobody downstream can recover it from a commit subject.

If this change genuinely cannot be observed by a player, label the
pull request "no-changelog" and this check will be skipped.

The rule: conventions/changelog.md
────────────────────────────────────────────────────────────────────
EOF
} >&2

exit 1

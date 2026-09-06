#!/bin/bash
#
# check-pr-title.sh - Validate the commit subject a squash merge will produce.
#
# Usage:
#   ./scripts/check-pr-title.sh "<pr title>" "<pr number>"
#
# Why this exists: commit-lint validates the commits *in* a PR, but that is not
# what lands on main. This repository's squash setting is COMMIT_OR_PR_TITLE --
# GitHub uses the single commit's subject when a PR has exactly one, and the PR
# title otherwise -- and appends " (#N)" either way. So a PR with follow-up
# commits puts its title on main, unlinted.
#
# That is not cosmetic. update_changelog_from_commits parses subjects from main,
# so a non-conventional subject is not mis-filed but dropped entirely, with
# nothing to show a release note went missing.
#
# The composed subject is what gets checked, which also catches the length
# case: " (#123)" is six or seven characters that a 72-character title does not
# have room for.
#
# Exits 0 when valid, 1 when not, 2 on usage error.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$SCRIPT_DIR/check-commit-subject.sh"

if [ "$#" -ne 2 ]; then
  echo "usage: $0 \"<pr title>\" \"<pr number>\"" >&2
  exit 2
fi

title="$1"
number="$2"

if [ -z "$title" ]; then
  echo "check-pr-title.sh: empty PR title" >&2
  exit 1
fi

if ! [[ "$number" =~ ^[0-9]+$ ]]; then
  echo "check-pr-title.sh: PR number must be numeric, got '$number'" >&2
  exit 2
fi

# What GitHub will actually write onto main.
subject="$title (#$number)"

echo "Squash merge will land this subject on main:"
echo "  $subject"
echo

if "$CHECK" "$subject"; then
  echo "✓ PR title produces a valid commit subject"
  exit 0
fi

cat >&2 <<EOF

────────────────────────────────────────────────────────────────────
This repository squash-merges with COMMIT_OR_PR_TITLE, so the subject
above is what lands on main -- the PR title is used whenever the PR has
more than one commit, and " (#$number)" is appended either way.

Rename the pull request to follow the commit convention. Note the
appended number counts toward the width limit, so the title itself has
$(( ${#number} + 4 )) fewer characters to work with than the limit suggests.

The convention and its rules: conventions/commit-messages.md
────────────────────────────────────────────────────────────────────
EOF
exit 1

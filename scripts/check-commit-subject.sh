#!/bin/bash
#
# check-commit-subject.sh - Validate a commit subject line against the project's
# Conventional Commits format. Single source of truth used by:
#   - .githooks/commit-msg            (local pre-commit feedback)
#   - .github/workflows/commit-lint.yml (CI gate on PRs)
#
# Usage:
#   ./scripts/check-commit-subject.sh "<subject line>"
#
# Exits 0 if the subject is valid, 1 otherwise. On failure, prints a friendly
# explanation to stderr that includes the offending subject and the rules.

set -euo pipefail

# Pattern + width — the rules. Keep these here only; the hook and workflow
# both call this script rather than re-encoding them.
COMMIT_PATTERN='^(feat|fix|docs|style|refactor|perf|test|chore|revert|build|ci)(\([^)]+\))?: .+$'
MAX_SUBJECT_WIDTH=72

if [ "$#" -ne 1 ]; then
  echo "usage: $0 \"<subject line>\"" >&2
  exit 2
fi

subject="$1"

fail() {
  cat >&2 <<EOF

✗ commit subject rejected:
    "$subject"

$1

Format:  <type>(<scope>): <description>
Types:   feat, fix, docs, style, refactor, perf, test,
         chore, revert, build, ci
Subject: ≤ ${MAX_SUBJECT_WIDTH} characters

Examples:
  feat: Add dark mode support
  fix(grid): Resolve block placement bug
  chore: Release v2.0.4
  docs: Clarify Game Center setup steps
EOF
  exit 1
}

if [ -z "$subject" ]; then
  fail "Reason: commit message is empty."
fi

if [ "${#subject}" -gt "$MAX_SUBJECT_WIDTH" ]; then
  fail "Reason: subject is ${#subject} characters (max ${MAX_SUBJECT_WIDTH})."
fi

if ! [[ "$subject" =~ $COMMIT_PATTERN ]]; then
  fail "Reason: subject does not match Conventional Commits format."
fi

exit 0

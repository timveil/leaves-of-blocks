#!/bin/bash
#
# test-lint-commit-range.sh - Exercise scripts/lint-commit-range.sh.
#
# The interesting behavior is not the format check itself (that belongs to
# check-commit-subject.sh) but the iteration around it: which commits are in
# scope, that one bad subject among many fails the whole range, that an empty
# range is a pass rather than an error, and that a failure prints the
# remediation block a contributor needs.
#
#   ./scripts/test-lint-commit-range.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINT="$SCRIPT_DIR/lint-commit-range.sh"

pass=0
fail=0

ok()   { pass=$((pass + 1)); printf '  ok    %s\n' "$1"; }
bad()  { fail=$((fail + 1)); printf '  FAIL  %s\n        %s\n' "$1" "$2"; }

# run_stdin <expected-exit> <description> <subjects...>
run_stdin() {
  local want="$1" desc="$2"; shift 2
  local out code
  out=$(printf '%s\n' "$@" | "$LINT" --stdin 2>&1)
  code=$?
  if [ "$code" -eq "$want" ]; then
    ok "$desc"
  else
    bad "$desc" "want exit $want, got $code"$'\n'"$out"
  fi
}

echo "exit status"

run_stdin 0 "all subjects valid" \
  "feat: Add dark mode support" \
  "fix(grid): Resolve block placement bug" \
  "chore: Release v2.0.4"

run_stdin 1 "one invalid subject among valid ones" \
  "feat: Add dark mode support" \
  "Update CHANGELOG and docs" \
  "fix: Correct a typo"

run_stdin 1 "every subject invalid" \
  "Bump version" \
  "WIP"

run_stdin 1 "valid type but subject too long" \
  "feat: $(printf 'x%.0s' {1..80})"

run_stdin 0 "scoped and unscoped types both accepted" \
  "ci(codeql): Analyze only the languages a PR touches" \
  "docs: Clarify Game Center setup steps" \
  "revert: Undo the block generator change"

echo
echo "empty range"

out=$(printf '' | "$LINT" --stdin 2>&1); code=$?
if [ "$code" -eq 0 ]; then ok "empty input exits 0"; else bad "empty input exits 0" "got $code"; fi
if grep -q "No non-merge commits to lint." <<<"$out"; then
  ok "empty input explains itself"
else
  bad "empty input explains itself" "missing the explanatory line"
fi

# Blank lines are skipped rather than linted as empty subjects, so a trailing
# newline from git log cannot manufacture a spurious failure.
out=$(printf 'feat: Something\n\n\n' | "$LINT" --stdin 2>&1); code=$?
if [ "$code" -eq 0 ]; then ok "blank lines are skipped"; else bad "blank lines are skipped" "got $code"; fi

echo
echo "failure output"

out=$(printf '%s\n' "Bad subject" | "$LINT" --stdin 2>&1)
for needle in "git rebase -i" "force-with-lease" "core.hooksPath"; do
  if grep -qF "$needle" <<<"$out"; then
    ok "remediation mentions $needle"
  else
    bad "remediation mentions $needle" "absent from failure output"
  fi
done

out=$(printf '%s\n' "feat: Fine" "Not fine" | "$LINT" --stdin 2>&1)
if grep -q "✓ ok" <<<"$out"; then ok "passing subjects are marked"; else bad "passing subjects are marked" "no ✓ marker"; fi
if grep -q "→ Not fine" <<<"$out"; then ok "each subject is echoed"; else bad "each subject is echoed" "subject not echoed"; fi

echo
echo "argument handling"

"$LINT" >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then ok "no arguments is a usage error"; else bad "no arguments is a usage error" "want exit 2, got $code"; fi

"$LINT" only-one-ref >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then ok "one ref is a usage error"; else bad "one ref is a usage error" "want exit 2, got $code"; fi

echo
echo "git range mode"

# Against real history: HEAD..HEAD is empty, and the last commit on this
# branch was written under the rules, so it must pass.
out=$("$LINT" HEAD HEAD 2>&1); code=$?
if [ "$code" -eq 0 ]; then ok "empty git range passes"; else bad "empty git range passes" "got $code"; fi

out=$("$LINT" HEAD~1 HEAD 2>&1); code=$?
if [ "$code" -eq 0 ]; then ok "HEAD~1..HEAD passes on this repo"; else bad "HEAD~1..HEAD passes" "got $code: $out"; fi

echo
if [ "$fail" -eq 0 ]; then
  echo "All $pass checks passed."
  exit 0
fi
echo "$fail failed, $pass passed."
exit 1

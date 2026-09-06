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

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

# Fixed-string searches use `grep -qF` throughout: these needles carry regex
# metacharacters (the "." in "No non-merge commits to lint.") that would
# otherwise match text the assertion did not intend to accept.
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
if grep -qF "No non-merge commits to lint." <<<"$out"; then
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
if grep -qF "✓ ok" <<<"$out"; then ok "passing subjects are marked"; else bad "passing subjects are marked" "no ✓ marker"; fi
if grep -qF "→ Not fine" <<<"$out"; then ok "each subject is echoed"; else bad "each subject is echoed" "subject not echoed"; fi

echo
echo "argument handling"

"$LINT" >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then ok "no arguments is a usage error"; else bad "no arguments is a usage error" "want exit 2, got $code"; fi

"$LINT" only-one-ref >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then ok "one ref is a usage error"; else bad "one ref is a usage error" "want exit 2, got $code"; fi

echo
echo "git range mode"

# Against a purpose-built repository rather than this one's history. An earlier
# version asserted that HEAD~1..HEAD passes here, which coupled the suite to
# whatever happened to be merged last -- and duly broke when a squash merge put
# a non-conventional PR title on main. Test the range logic, not the history.
REPO="$TMP/repo"
git init -q "$REPO"
git -C "$REPO" config user.email "test@example.com"
git -C "$REPO" config user.name "Test"

commit() { git -C "$REPO" commit -q --allow-empty -m "$1"; }

commit "feat: Base commit"
BASE=$(git -C "$REPO" rev-parse HEAD)
commit "fix(grid): Correct placement"
commit "docs: Explain the thing"
GOOD_HEAD=$(git -C "$REPO" rev-parse HEAD)

run_in_repo() { (cd "$REPO" && "$LINT" "$@" 2>&1); }

run_in_repo "$BASE" "$GOOD_HEAD" >/dev/null; code=$?
if [ "$code" -eq 0 ]; then ok "a range of valid commits passes"; else bad "range of valid commits passes" "got $code"; fi

run_in_repo "$GOOD_HEAD" "$GOOD_HEAD" >/dev/null; code=$?
if [ "$code" -eq 0 ]; then ok "an empty range passes"; else bad "empty range passes" "got $code"; fi

commit "Not a conventional subject"
BAD_HEAD=$(git -C "$REPO" rev-parse HEAD)
run_in_repo "$BASE" "$BAD_HEAD" >/dev/null; code=$?
if [ "$code" -eq 1 ]; then ok "one bad commit fails the range"; else bad "one bad commit fails the range" "got $code"; fi

# Merge commit subjects are generated by git, not authored, so --no-merges must
# keep them out of scope -- otherwise every PR with a merge in it would fail.
git -C "$REPO" checkout -q -b side "$BASE"
commit "feat: Side work"
git -C "$REPO" checkout -q -
git -C "$REPO" merge -q --no-ff -m "Merge branch '"'"'side'"'"'" side
MERGE_HEAD=$(git -C "$REPO" rev-parse HEAD)
run_in_repo "$BAD_HEAD" "$MERGE_HEAD" >/dev/null; code=$?
if [ "$code" -eq 0 ]; then ok "merge commit subjects are skipped"; else bad "merge commit subjects are skipped" "got $code"; fi

echo
if [ "$fail" -eq 0 ]; then
  echo "All $pass checks passed."
  exit 0
fi
echo "$fail failed, $pass passed."
exit 1

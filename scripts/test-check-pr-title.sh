#!/bin/bash
#
# test-check-pr-title.sh - Exercise scripts/check-pr-title.sh.
#
#   ./scripts/test-check-pr-title.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$SCRIPT_DIR/check-pr-title.sh"
LIMIT=72   # must match MAX_SUBJECT_WIDTH in check-commit-subject.sh

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
ok()  { pass=$((pass + 1)); printf '  ok    %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf '  FAIL  %s\n        %s\n' "$1" "$2"; }

# expect <exit> <description> <title> <number>
expect() {
  local want="$1" desc="$2" title="$3" number="$4"
  "$CHECK" "$title" "$number" >/dev/null 2>&1
  local code=$?
  if [ "$code" -eq "$want" ]; then ok "$desc"; else bad "$desc" "want exit $want, got $code"; fi
}

echo "format"

expect 0 "conventional title passes"          "fix(grid): Resolve placement bug" 77
expect 0 "unscoped type passes"               "docs: Clarify Game Center setup" 77
expect 1 "no type prefix fails"               "Resolve placement bug" 77

# The two that actually reached main unlinted.
expect 1 "the real #74 title fails"           "Require a minimum Xcode version, not an exact pin" 74
expect 1 "the real #72 title fails"           "Extract commit-lint scripting and start a conventions/ folder" 72

echo
echo "width, including the appended number"

# GitHub appends " (#N)". A title that fits on its own can still overflow once
# the number is added -- the case a naive title-only check would wave through.
suffix=" (#77)"
fits=$(printf 'feat: %s' "$(printf 'x%.0s' $(seq 1 $((LIMIT - 6 - ${#suffix})) ))")
over=$(printf 'feat: %s' "$(printf 'x%.0s' $(seq 1 $((LIMIT - 6 - ${#suffix} + 1)) ))")

# The two cases below are only meaningful if the fixtures really do land on
# the boundary. Assert that, so a change to LIMIT or to the arithmetic fails
# here rather than leaving the assertions passing against the wrong lengths
# while their descriptions claim otherwise.
if [ $(( ${#fits} + ${#suffix} )) -eq "$LIMIT" ]; then
  ok "fixture 'fits' lands exactly on the limit"
else
  bad "fixture 'fits' lands exactly on the limit" "got $(( ${#fits} + ${#suffix} )), want $LIMIT"
fi
if [ $(( ${#over} + ${#suffix} )) -eq $(( LIMIT + 1 )) ]; then
  ok "fixture 'over' lands one past the limit"
else
  bad "fixture 'over' lands one past the limit" "got $(( ${#over} + ${#suffix} )), want $(( LIMIT + 1 ))"
fi

expect 0 "title that fits exactly with the suffix passes ($(( ${#fits} + ${#suffix} )) chars)" "$fits" 77
expect 1 "title one char too long once suffixed fails ($(( ${#over} + ${#suffix} )) chars)"   "$over" 77

# A four-digit PR number eats more of the budget than a two-digit one.
expect 1 "same title fails against a wider PR number" "$fits" 1234

echo
echo "argument handling"

expect 1 "empty title fails"                  "" 77
expect 2 "non-numeric PR number is a usage error" "feat: Something" "abc"
expect 2 "PR number with a hash is a usage error" "feat: Something" "#77"

"$CHECK" "feat: Only one arg" >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then ok "one argument is a usage error"; else bad "one arg exits 2" "got $code"; fi

"$CHECK" >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then ok "no arguments is a usage error"; else bad "no args exits 2" "got $code"; fi

echo
echo "titles are data, not code"

# PR titles are attacker-controlled: anyone who can open a PR chooses this
# string. It must never reach a shell as code.
CANARY="$TMP/canary"
"$CHECK" 'feat: x"; touch '"$CANARY"'; echo "' 77 >/dev/null 2>&1
if [ ! -e "$CANARY" ]; then ok "a title containing shell syntax does not execute"; else bad "title executed" "canary file was created"; fi

"$CHECK" 'feat: $(touch '"$CANARY"')' 77 >/dev/null 2>&1
if [ ! -e "$CANARY" ]; then ok "command substitution in a title does not execute"; else bad "substitution executed" "canary created"; fi

out=$("$CHECK" 'feat: Handle $HOME and `backticks` literally' 77 2>&1)
if grep -qF 'feat: Handle $HOME and `backticks` literally (#77)' <<<"$out"; then
  ok "metacharacters are echoed literally"
else
  bad "metacharacters echoed literally" "got: $out"
fi

echo
if [ "$fail" -eq 0 ]; then echo "All $pass checks passed."; exit 0; fi
echo "$fail failed, $pass passed."
exit 1

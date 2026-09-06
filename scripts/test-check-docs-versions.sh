#!/bin/bash
#
# test-check-docs-versions.sh - Exercise scripts/check-docs-versions.sh.
#
#   ./scripts/test-check-docs-versions.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$SCRIPT_DIR/check-docs-versions.sh"

pass=0
fail=0
ok()  { pass=$((pass + 1)); printf '  ok    %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf '  FAIL  %s\n        %s\n' "$1" "$2"; }

echo "against the real repository"

"$CHECK" >/dev/null 2>&1; code=$?
if [ "$code" -eq 0 ]; then ok "the checked-in docs agree with the project"; else bad "docs agree with project" "$("$CHECK" 2>&1 | head -2)"; fi

# --target drives the comparison, so drift can be simulated without editing
# any document: asserting against a floor the docs do not state must fail.
"$CHECK" --target 19.9 >/dev/null 2>&1; code=$?
if [ "$code" -eq 1 ]; then ok "a mismatched target is reported"; else bad "mismatched target reported" "want exit 1, got $code"; fi

err=$("$CHECK" --target 19.9 2>&1 >/dev/null)
if grep -qF "README.md" <<<"$err"; then ok "the offending file is named"; else bad "offending file named" "not in output"; fi
if grep -qF "IPHONEOS_DEPLOYMENT_TARGET" <<<"$err"; then ok "the source of truth is named"; else bad "source of truth named" "absent"; fi

# The README states the floor in a shields.io URL where the space is
# percent-encoded. That is the most visible claim in the repo and the one a
# naive "iOS <space> <version>" matcher silently skips.
if grep -qE "iOS%20" <<<"$err"; then
  ok "the percent-encoded badge is checked, not skipped"
else
  bad "badge is checked" "no %20 match in: $(head -2 <<<"$err")"
fi

echo
echo "argument handling"

"$CHECK" --target >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then ok "--target without a value is a usage error"; else bad "--target without value exits 2" "got $code"; fi

"$CHECK" --bogus >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then ok "an unknown flag is a usage error"; else bad "unknown flag exits 2" "got $code"; fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
DOCS_CHECK_PBXPROJ="$TMP/missing" "$CHECK" >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then ok "an unreadable project file is a setup error"; else bad "unreadable project exits 2" "got $code"; fi

printf 'no target here\n' > "$TMP/pbxproj"
DOCS_CHECK_PBXPROJ="$TMP/pbxproj" "$CHECK" >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then ok "an unparseable project file is a setup error"; else bad "unparseable project exits 2" "got $code"; fi

printf '\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 18.0;\n' > "$TMP/pbxproj"
DOCS_CHECK_PBXPROJ="$TMP/pbxproj" "$CHECK" >/dev/null 2>&1; code=$?
if [ "$code" -eq 0 ]; then ok "the floor is read from the project file"; else bad "floor read from project" "got $code"; fi

echo
if [ "$fail" -eq 0 ]; then echo "All $pass checks passed."; exit 0; fi
echo "$fail failed, $pass passed."
exit 1

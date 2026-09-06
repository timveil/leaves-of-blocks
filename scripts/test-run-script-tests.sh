#!/bin/bash
#
# test-run-script-tests.sh - Exercise scripts/run-script-tests.sh.
#
# The runner is what CI trusts, so its only real job is propagating failure. A
# runner that swallows a non-zero suite turns every red suite into a green
# build -- strictly worse than no runner, because it manufactures confidence.
# These cases pin the exit codes.
#
#   ./scripts/test-run-script-tests.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER="$SCRIPT_DIR/run-script-tests.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
# Always capture the exit status into a variable before testing it. Using `$?`
# directly in `if [ $? -eq N ]` makes it unrecoverable in the else branch --
# there `$?` is the status of `[` itself, so a failure message reports 1 no
# matter what the command actually returned.
ok()  { pass=$((pass + 1)); printf '  ok    %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf '  FAIL  %s\n        %s\n' "$1" "$2"; }

# make_suite <dir> <name> <exit-code>
make_suite() {
  mkdir -p "$1"
  printf '#!/bin/bash\necho "  (fixture %s)"\nexit %s\n' "$2" "$3" > "$1/test-$2.sh"
  chmod +x "$1/test-$2.sh"
}

# expect <dir> <expected-exit> <description>
expect() {
  "$RUNNER" --dir "$1" >/dev/null 2>&1
  local code=$?
  if [ "$code" -eq "$2" ]; then ok "$3"; else bad "$3" "want exit $2, got $code"; fi
}

echo "failure propagation"

D="$TMP/all-pass"; make_suite "$D" alpha 0; make_suite "$D" beta 0
expect "$D" 0 "all suites passing exits 0"

D="$TMP/one-fail"; make_suite "$D" alpha 0; make_suite "$D" beta 1
expect "$D" 1 "one failing suite exits 1"

D="$TMP/all-fail"; make_suite "$D" alpha 1; make_suite "$D" beta 1
expect "$D" 1 "every suite failing exits 1"

# A failure in the first suite must not stop later ones from running: seeing
# every failure at once beats fixing them one CI round trip at a time.
D="$TMP/first-fails"; make_suite "$D" alpha 1; make_suite "$D" beta 0
out=$("$RUNNER" --dir "$D" 2>&1)
if grep -qF "(fixture beta)" <<<"$out"; then
  ok "a later suite still runs after an earlier failure"
else
  bad "later suite runs after earlier failure" "beta did not run"
fi
if grep -qF "FAILED: test-alpha.sh" <<<"$out"; then
  ok "the failing suite is named in the summary"
else
  bad "failing suite named in summary" "not listed"
fi

echo
echo "edge cases"

D="$TMP/empty"; mkdir -p "$D"
expect "$D" 1 "a directory with no suites is a failure, not a pass"

D="$TMP/not-exec"; mkdir -p "$D"
printf '#!/bin/bash\nexit 0\n' > "$D/test-gamma.sh"   # deliberately not chmod +x
expect "$D" 1 "a non-executable suite is a failure"

"$RUNNER" --dir >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then ok "--dir without a value is a usage error"; else bad "--dir without value exits 2" "want exit 2, got $code"; fi

"$RUNNER" --nonsense >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then ok "an unknown flag is a usage error"; else bad "unknown flag exits 2" "want exit 2, got $code"; fi

echo
if [ "$fail" -eq 0 ]; then echo "All $pass checks passed."; exit 0; fi
echo "$fail failed, $pass passed."
exit 1

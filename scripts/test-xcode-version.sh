#!/bin/bash
#
# test-xcode-version.sh - Exercise scripts/xcode-version.sh.
#
# The comparison is the part worth testing. A lexical string compare accepts
# an Xcode older than the floor as soon as minor versions reach double digits
# ("26.9" > "26.10" as strings), and that failure is silent -- the build just
# runs on the wrong toolchain. These cases pin the ordering.
#
#   ./scripts/test-xcode-version.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XV="$SCRIPT_DIR/xcode-version.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
ok()  { pass=$((pass + 1)); printf '  ok    %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf '  FAIL  %s\n        %s\n' "$1" "$2"; }

floor() { printf '%s\n' "$1" > "$TMP/floor"; export XCODE_VERSION_FILE="$TMP/floor"; }

# check <floor> <candidate> <expected-exit> <description>
check() {
  local min="$1" candidate="$2" want="$3" desc="$4"
  floor "$min"
  "$XV" --check "$candidate" >/dev/null 2>&1
  local code=$?
  if [ "$code" -eq "$want" ]; then ok "$desc"; else bad "$desc" "want exit $want, got $code"; fi
}

echo "minimum comparison"

check 26.5 26.5  0 "equal to the floor passes"
check 26.5 26.6  0 "newer patch passes"
check 26.5 27.0  0 "newer major passes"
check 26.5 26.4  1 "older minor fails"
check 26.5 25.9  1 "older major fails"

# The cases a lexical compare gets wrong.
check 26.9  26.10 0 "26.10 satisfies a 26.9 floor"
check 26.10 26.9  1 "26.9 does not satisfy a 26.10 floor"
check 26.5  26.10 0 "26.10 satisfies a 26.5 floor"

# Three-component versions, since Xcode reports them (e.g. 26.0.1).
check 26.5   26.5.1 0 "26.5.1 satisfies a 26.5 floor"
check 26.5.1 26.5   1 "26.5 does not satisfy a 26.5.1 floor"

echo
echo "selection"

# select_from <floor> <expected-path> <description> <candidate lines...>
select_from() {
  local min="$1" want="$2" desc="$3"; shift 3
  floor "$min"
  local got
  got=$(printf '%s\n' "$@" | "$XV" --select-from 2>/dev/null)
  if [ "$got" = "$want" ]; then ok "$desc"; else bad "$desc" "want [$want] got [$got]"; fi
}

select_from 26.5 "/Applications/Xcode_26.6.app/Contents/Developer" \
  "picks the newest meeting the floor" \
  "$(printf '26.4\t/Applications/Xcode_26.4.app/Contents/Developer')" \
  "$(printf '26.6\t/Applications/Xcode_26.6.app/Contents/Developer')" \
  "$(printf '26.5\t/Applications/Xcode_26.5.app/Contents/Developer')"

select_from 26.5 "/Applications/Xcode_26.10.app/Contents/Developer" \
  "newest is chosen numerically, not lexically" \
  "$(printf '26.9\t/Applications/Xcode_26.9.app/Contents/Developer')" \
  "$(printf '26.10\t/Applications/Xcode_26.10.app/Contents/Developer')"

select_from 26.5 "/Applications/Xcode_26.5.app/Contents/Developer" \
  "candidates below the floor are ignored" \
  "$(printf '26.1\t/Applications/Xcode_26.1.app/Contents/Developer')" \
  "$(printf '26.5\t/Applications/Xcode_26.5.app/Contents/Developer')"

floor 26.5
printf '26.1\t/Applications/Xcode_26.1.app/Contents/Developer\n' | "$XV" --select-from >/dev/null 2>&1
code=$?
if [ "$code" -eq 1 ]; then ok "nothing meeting the floor exits 1"; else bad "nothing meeting the floor exits 1" "got $code"; fi

echo
echo "reading the floor"

floor 26.5
got=$("$XV" --min)
if [ "$got" = "26.5" ]; then ok "--min prints the floor"; else bad "--min prints the floor" "got [$got]"; fi

printf '  26.5  \n' > "$TMP/floor"
got=$("$XV" --min)
if [ "$got" = "26.5" ]; then ok "surrounding whitespace is stripped"; else bad "whitespace stripped" "got [$got]"; fi

export XCODE_VERSION_FILE="$TMP/does-not-exist"
"$XV" --min >/dev/null 2>&1
code=$?
if [ "$code" -eq 2 ]; then ok "missing floor file is a setup error"; else bad "missing floor file exits 2" "got $code"; fi

"$XV" --bogus >/dev/null 2>&1
code=$?
if [ "$code" -eq 2 ]; then ok "unknown mode is a usage error"; else bad "unknown mode exits 2" "got $code"; fi

echo
echo "no usable xcodebuild"

# Regression: selected_xcode_version must be non-fatal. With `set -euo
# pipefail`, a failing xcodebuild inside --check's command substitution aborts
# the script before it can report anything -- so the machine that most needs
# the explanation (no Xcode selected) is the one that gets a bare exit code.
STUB="$TMP/stub"
mkdir -p "$STUB"

floor 26.5

printf '#!/bin/bash\nexit 1\n' > "$STUB/xcodebuild"
chmod +x "$STUB/xcodebuild"
out=$(PATH="$STUB:$PATH" "$XV" --check 2>&1); code=$?
if [ "$code" -eq 2 ]; then
  ok "failing xcodebuild exits 2, not a bare set -e abort"
else
  bad "failing xcodebuild exits 2" "got $code"
fi
if grep -qF "could not determine the selected Xcode version" <<<"$out"; then
  ok "failing xcodebuild explains itself"
else
  bad "failing xcodebuild explains itself" "message missing; got: $out"
fi

# A stub that reports a version is still read correctly.
printf '#!/bin/bash\necho "Xcode 26.7"\necho "Build version 17X1"\n' > "$STUB/xcodebuild"
chmod +x "$STUB/xcodebuild"
out=$(PATH="$STUB:$PATH" "$XV" --check 2>&1); code=$?
if [ "$code" -eq 0 ] && grep -qF "Xcode 26.7 meets the minimum" <<<"$out"; then
  ok "version is parsed from xcodebuild output"
else
  bad "version parsed from xcodebuild" "exit $code: $out"
fi

printf '#!/bin/bash\necho "Xcode 26.1"\n' > "$STUB/xcodebuild"
chmod +x "$STUB/xcodebuild"
PATH="$STUB:$PATH" "$XV" --check >/dev/null 2>&1; code=$?
if [ "$code" -eq 1 ]; then
  ok "a too-old selected Xcode exits 1"
else
  bad "too-old selected Xcode exits 1" "got $code"
fi

echo
echo "against the real checked-in floor"

unset XCODE_VERSION_FILE
real_min=$("$XV" --min)
if [ -n "$real_min" ]; then ok ".xcode-version is readable (floor: $real_min)"; else bad ".xcode-version readable" "empty"; fi
if "$XV" --check >/dev/null 2>&1; then
  ok "this machine's Xcode meets the checked-in floor"
else
  bad "this machine's Xcode meets the floor" "$("$XV" --check 2>&1 | head -1)"
fi

echo
if [ "$fail" -eq 0 ]; then echo "All $pass checks passed."; exit 0; fi
echo "$fail failed, $pass passed."
exit 1

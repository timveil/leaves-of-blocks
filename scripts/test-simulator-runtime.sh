#!/bin/bash
#
# test-simulator-runtime.sh - Exercise scripts/simulator-runtime.sh.
#
# The label-versus-point distinction is the point of these tests. simctl lists
# `iOS 26.4 (26.4.1 - ...)`, and picking the wrong one of those two strings
# produces an xcodebuild -destination that matches no simulator -- a failure
# that lands in the middle of `deploy`, after screenshots have already started.
#
#   ./scripts/test-simulator-runtime.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SR="$SCRIPT_DIR/simulator-runtime.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
ok()  { pass=$((pass + 1)); printf '  ok    %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf '  FAIL  %s\n        %s\n' "$1" "$2"; }

# Stand in for project.pbxproj so the floor can be varied.
floor() {
  printf '\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = %s;\n' "$1" > "$TMP/pbxproj"
  export SIMULATOR_RUNTIME_PBXPROJ="$TMP/pbxproj"
}

# expect <floor> <expected> <description> [--label] <"point<TAB>label" lines...>
expect() {
  local min="$1" want="$2" desc="$3"; shift 3
  local label_flag=""
  if [ "${1:-}" = "--label" ]; then label_flag="--label"; shift; fi

  floor "$min"
  local got
  got=$(printf '%s\n' "$@" | "$SR" --from $label_flag 2>/dev/null)
  if [ "$got" = "$want" ]; then ok "$desc"; else bad "$desc" "want [$want] got [$got]"; fi
}

echo "selection"

expect 18.5 "26.5" "picks the newest runtime" \
  "$(printf '26.4.1\t26.4')" "$(printf '26.5\t26.5')"

expect 18.5 "26.5" "order of input does not matter" \
  "$(printf '26.5\t26.5')" "$(printf '26.4.1\t26.4')"

expect 26.5 "26.5" "a runtime exactly at the floor qualifies" \
  "$(printf '26.4.1\t26.4')" "$(printf '26.5\t26.5')"

expect 18.5 "26.10" "newest is chosen numerically, not lexically" \
  "$(printf '26.9\t26.9')" "$(printf '26.10\t26.10')"

expect 26.6 "27.0" "runtimes below the floor are ignored" \
  "$(printf '26.4.1\t26.4')" "$(printf '27.0\t27.0')"

echo
echo "label versus point version"

# The whole reason both forms are carried: for 26.4 they differ.
expect 18.5 "26.4.1" "the point version is the default output" \
  "$(printf '26.4.1\t26.4')"
expect 18.5 "26.4" "--label returns the label of the same runtime" --label \
  "$(printf '26.4.1\t26.4')"

# And for 26.5 they happen to be identical, which is why a bug here hides.
expect 18.5 "26.5" "point and label agree when the runtime has no patch" \
  "$(printf '26.5\t26.5')"
expect 18.5 "26.5" "--label agrees too in that case" --label \
  "$(printf '26.5\t26.5')"

# --label must follow the selected runtime, not the highest label.
expect 18.5 "26.10" "--label follows the chosen runtime" --label \
  "$(printf '26.9.3\t26.9')" "$(printf '26.10\t26.10')"

echo
echo "nothing qualifies"

floor 30.0
printf '26.5\t26.5\n' | "$SR" --from >/dev/null 2>&1; code=$?
if [ "$code" -eq 1 ]; then ok "no qualifying runtime exits 1"; else bad "no qualifying runtime exits 1" "got $code"; fi

out=$(printf '26.5\t26.5\n' | "$SR" --from 2>&1 >/dev/null)
if grep -qF "no installed iOS runtime is at or above" <<<"$out"; then
  ok "and explains what is missing"
else
  bad "explains what is missing" "got: $out"
fi
if grep -qF "IPHONEOS_DEPLOYMENT_TARGET" <<<"$out"; then
  ok "and names both ways out"
else
  bad "names both ways out" "no remediation"
fi

floor 18.5
printf '' | "$SR" --from >/dev/null 2>&1; code=$?
if [ "$code" -eq 1 ]; then ok "no runtimes at all exits 1"; else bad "no runtimes at all exits 1" "got $code"; fi

echo
echo "reading the floor"

floor 18.5
got=$("$SR" --min)
if [ "$got" = "18.5" ]; then ok "--min reads the deployment target"; else bad "--min reads deployment target" "got [$got]"; fi

# The real pbxproj lists the target many times; the first must be taken cleanly.
unset SIMULATOR_RUNTIME_PBXPROJ
real=$("$SR" --min)
if [[ "$real" =~ ^[0-9]+\.[0-9]+$ ]]; then
  ok "--min parses the real project file (floor: $real)"
else
  bad "--min parses the real project" "got [$real]"
fi

export SIMULATOR_RUNTIME_PBXPROJ="$TMP/missing"
"$SR" --min >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then ok "a missing project file is a setup error"; else bad "missing project exits 2" "got $code"; fi

printf 'nothing useful here\n' > "$TMP/pbxproj"
export SIMULATOR_RUNTIME_PBXPROJ="$TMP/pbxproj"
"$SR" --min >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then ok "an unparseable project file is a setup error"; else bad "unparseable project exits 2" "got $code"; fi

"$SR" --bogus >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then ok "an unknown flag is a usage error"; else bad "unknown flag exits 2" "got $code"; fi

echo
echo "xcrun failures"

# When Xcode is not selected, or only the Command Line Tools are, xcrun fails.
# That is a setup error (exit 2), not "no runtime qualifies" (exit 1) -- and
# the two need different responses from whoever reads the log.
STUB="$TMP/stub"
mkdir -p "$STUB"
printf '#!/bin/bash\necho "xcrun: error: unable to find utility" >&2\nexit 72\n' > "$STUB/xcrun"
chmod +x "$STUB/xcrun"

unset SIMULATOR_RUNTIME_PBXPROJ

PATH="$STUB:$PATH" "$SR" >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then ok "a failing xcrun exits 2, not 1"; else bad "failing xcrun exits 2" "got $code"; fi

PATH="$STUB:$PATH" "$SR" --list >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then ok "--list reports the same setup error"; else bad "--list exits 2" "got $code"; fi

err=$(PATH="$STUB:$PATH" "$SR" 2>&1 >/dev/null)
if grep -qF "xcode-select -p" <<<"$err"; then
  ok "the message says how to check the toolchain"
else
  bad "message names xcode-select" "got: $err"
fi
if grep -qF "unable to find utility" <<<"$err"; then
  ok "xcrun's own error is preserved, not swallowed"
else
  bad "xcrun error preserved" "the underlying cause was hidden"
fi
# A pipeline would have let the second stage report an unrelated failure too.
if grep -qF "no installed iOS runtime" <<<"$err"; then
  bad "no misleading second error" "the 'no runtime' message also fired"
else
  ok "no misleading second error is stacked under it"
fi

echo
echo "against the real machine"

unset SIMULATOR_RUNTIME_PBXPROJ
if "$SR" >/dev/null 2>&1; then
  ok "a runtime is selectable here ($("$SR"), label $("$SR" --label))"
else
  bad "a runtime is selectable here" "$("$SR" 2>&1 | head -1)"
fi

lines=$("$SR" --list | wc -l | tr -d ' ')
if [ "$lines" -gt 0 ]; then ok "--list finds $lines installed runtime(s)"; else bad "--list finds runtimes" "none"; fi

echo
if [ "$fail" -eq 0 ]; then echo "All $pass checks passed."; exit 0; fi
echo "$fail failed, $pass passed."
exit 1

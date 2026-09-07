#!/bin/bash
#
# test-check-changelog.sh - Exercise scripts/check-changelog.sh.
#
#   ./scripts/test-check-changelog.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$SCRIPT_DIR/check-changelog.sh"

pass=0
fail=0
ok()  { pass=$((pass + 1)); printf '  ok    %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf '  FAIL  %s\n        %s\n' "$1" "$2"; }

# The whole check is a decision about path strings, so it needs no repository
# and no changelog on disk -- every case is a list of paths in, an exit code
# out.
run() { printf '%s\n' "$@" | "$CHECK" >/dev/null 2>&1; }
run_err() { printf '%s\n' "$@" | "$CHECK" 2>&1 >/dev/null; }

echo "changes players cannot see need no entry"

run ""; code=$?
if [ "$code" -eq 0 ]; then ok "an empty diff passes"; else bad "empty diff passes" "got $code"; fi

run "scripts/build.sh" "scripts/test-build.sh"; code=$?
if [ "$code" -eq 0 ]; then ok "a scripts-only change passes"; else bad "scripts-only passes" "got $code"; fi

run "fastlane/Fastfile" "fastlane/test/release_helpers_test.rb"; code=$?
if [ "$code" -eq 0 ]; then ok "a fastlane-only change passes"; else bad "fastlane-only passes" "got $code"; fi

run ".github/workflows/ios.yml" "conventions/tdd.md" "README.md"; code=$?
if [ "$code" -eq 0 ]; then ok "workflows, conventions and docs pass"; else bad "docs pass" "got $code"; fi

# The near-miss that a naive prefix match gets wrong. "LeavesOfBlocksTests/"
# does not start with "LeavesOfBlocks/", and a test-only change is not
# something a player can observe.
run "LeavesOfBlocksTests/GameLogicTests.swift"; code=$?
if [ "$code" -eq 0 ]; then ok "the test target is not mistaken for the app target"; else bad "tests pass" "got $code"; fi

run "LeavesOfBlocksUITests/BoardUITests.swift"; code=$?
if [ "$code" -eq 0 ]; then ok "UI tests are not the app target either"; else bad "UI tests pass" "got $code"; fi

# CodingStandards.md lives inside the app directory but is not shipped to
# anyone.
run "LeavesOfBlocks/Documentation/CodingStandards.md"; code=$?
if [ "$code" -eq 0 ]; then ok "documentation inside the app target is excluded"; else bad "app docs pass" "got $code"; fi

echo
echo "changes players can see need one"

run "LeavesOfBlocks/Views/Game/BoardView.swift"; code=$?
if [ "$code" -eq 1 ]; then ok "app source without a changelog entry fails"; else bad "app source fails" "want 1, got $code"; fi

run "LeavesOfBlocks/Views/Game/BoardView.swift" "CHANGELOG.md"; code=$?
if [ "$code" -eq 0 ]; then ok "app source with a changelog entry passes"; else bad "app source + changelog passes" "got $code"; fi

# The case this convention was written for: six feat(i18n) pull requests added
# six languages and none of them said so in CHANGELOG.md.
run "LeavesOfBlocks/Resources/Localizable.xcstrings"; code=$?
if [ "$code" -eq 1 ]; then ok "a string catalog change without an entry fails"; else bad "catalog fails" "want 1, got $code"; fi

# #89 lowered IPHONEOS_DEPLOYMENT_TARGET and changed who could install the app,
# touching no Swift at all.
run "LeavesOfBlocks.xcodeproj/project.pbxproj"; code=$?
if [ "$code" -eq 1 ]; then ok "a project-settings change without an entry fails"; else bad "pbxproj fails" "want 1, got $code"; fi

run "LeavesOfBlocks.xcodeproj/project.pbxproj" "CHANGELOG.md"; code=$?
if [ "$code" -eq 0 ]; then ok "and passes once the entry is there"; else bad "pbxproj + changelog passes" "got $code"; fi

# A mixed diff is decided by the player-visible half, not by how much of it
# is tooling.
run "scripts/build.sh" "LeavesOfBlocks/Models/Game/GameState.swift" "fastlane/Fastfile"; code=$?
if [ "$code" -eq 1 ]; then ok "one player-visible path in a large diff is enough"; else bad "mixed diff fails" "want 1, got $code"; fi

echo
echo "the failure explains itself"

err=$(run_err "LeavesOfBlocks/Views/Game/BoardView.swift" "scripts/build.sh")
if grep -qF "LeavesOfBlocks/Views/Game/BoardView.swift" <<<"$err"; then ok "the offending path is named"; else bad "path named" "got: $err"; fi
if grep -qF "scripts/build.sh" <<<"$err"; then bad "only player-visible paths listed" "tooling path was listed"; else ok "paths that did not trigger it are not listed"; fi
if grep -qF "CHANGELOG.md" <<<"$err"; then ok "the file to edit is named"; else bad "changelog named" "got: $err"; fi
if grep -qF "Unreleased" <<<"$err"; then ok "the section to edit is named"; else bad "section named" "got: $err"; fi
# Someone hitting this on a change no player can observe needs to know the way
# out, or they will write a junk entry to get green.
if grep -qF "no-changelog" <<<"$err"; then ok "the escape hatch is named"; else bad "escape hatch named" "got: $err"; fi

echo
echo "argument handling"

"$CHECK" --bogus </dev/null >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then ok "an unknown flag is a usage error"; else bad "unknown flag exits 2" "got $code"; fi

# Paths are data. A filename containing a space must not become two paths.
run "LeavesOfBlocks/Views/A File.swift"; code=$?
if [ "$code" -eq 1 ]; then ok "a path containing a space is one path"; else bad "spaced path" "want 1, got $code"; fi

echo
if [ "$fail" -eq 0 ]; then echo "All $pass checks passed."; exit 0; fi
echo "$fail failed, $pass passed."
exit 1

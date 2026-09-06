#!/bin/bash
#
# test-codeql-languages.sh - Exercise scripts/codeql-languages.sh against the
# path shapes this repository actually produces.
#
# The mapping is easy to get subtly wrong in a way CI will not surface: a
# missed pattern silently over-runs (wasting ~20 min of macOS Swift analysis)
# or under-runs (skipping analysis that should have happened). Both failures
# look like a green build. Run this after touching the mapping:
#
#   ./scripts/test-codeql-languages.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAPPER="$SCRIPT_DIR/codeql-languages.sh"

pass=0
fail=0

# expect <description> <expected "swift ruby actions"> <changed paths...>
expect() {
  local desc="$1" want="$2"; shift 2
  local out got
  out=$(printf '%s\n' "$@" | "$MAPPER")
  got="$(sed -n 's/^swift=//p' <<<"$out") $(sed -n 's/^ruby=//p' <<<"$out") $(sed -n 's/^actions=//p' <<<"$out")"

  if [ "$got" = "$want" ]; then
    pass=$((pass + 1))
    printf '  ok    %s\n' "$desc"
  else
    fail=$((fail + 1))
    printf '  FAIL  %s\n        want [%s] got [%s]\n' "$desc" "$want" "$got"
  fi
}

echo "path -> language mapping"

# The two real cases that motivated this: both ran a full Swift analysis.
expect "Deliverfile only (PR #67)"        "false true false"  "fastlane/Deliverfile"
expect "Fastfile + generated README (#68)" "false true false" "fastlane/Fastfile" "fastlane/README.md"

# Extensionless fastlane configs are Ruby despite matching no *.rb glob.
expect "Snapfile"                          "false true false" "fastlane/Snapfile"
expect "Appfile"                           "false true false" "fastlane/Appfile"
expect "helper .rb"                        "false true false" "fastlane/release_helpers.rb"
expect "Gemfile.lock (dependabot)"         "false true false" "Gemfile.lock"

# Swift-affecting inputs, including the non-.swift build inputs.
expect "swift source"                      "true false false" "LeavesOfBlocks/Logic/Game/GameLogic.swift"
expect "project.pbxproj"                   "true false false" "LeavesOfBlocks.xcodeproj/project.pbxproj"
expect "string catalog"                    "true false false" "LeavesOfBlocks/Resources/Localizable.xcstrings"
expect "entitlements"                      "true false false" "LeavesOfBlocks/LeavesOfBlocks.entitlements"
expect "test plan"                         "true false false" "TestPlan.xctestplan"

expect "workflow"                          "false false true" ".github/workflows/ios.yml"

# Nothing analyzable: the workflow still starts (paths-ignore lets these
# through) but no matrix entry should be produced.
expect "docs only"                         "false false false" "CHANGELOG.md" "CLAUDE.md"
expect "gitignore only"                    "false false false" ".gitignore"
expect "issue template"                    "false false false" ".github/ISSUE_TEMPLATE/bug_report.md"

# Overlap: a change set can legitimately need more than one language.
expect "swift + ruby"                      "true true false"  "App.swift" "fastlane/Fastfile"
expect "all three"                         "true true true"   "App.swift" "Gemfile" ".github/workflows/codeql.yml"

echo
echo "matrix payload"

check_matrix() {
  local desc="$1" want="$2"; shift 2
  local got
  got=$(printf '%s\n' "$@" | "$MAPPER" | sed -n 's/^matrix=//p')
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf '  ok    %s\n' "$desc"
  else
    fail=$((fail + 1)); printf '  FAIL  %s\n        want %s\n        got  %s\n' "$desc" "$want" "$got"
  fi
}

check_matrix "ruby-only matrix" \
  '{"include":[{"language":"ruby","runner":"ubuntu-latest","build-mode":"none"}]}' \
  "fastlane/Deliverfile"

check_matrix "empty matrix on docs-only" '{"include":[]}' "CHANGELOG.md"

got_all=$("$MAPPER" --all | sed -n 's/^matrix=//p')
want_all='{"include":[{"language":"swift","runner":"macos-latest","build-mode":"manual"},{"language":"ruby","runner":"ubuntu-latest","build-mode":"none"},{"language":"actions","runner":"ubuntu-latest","build-mode":"none"}]}'
if [ "$got_all" = "$want_all" ]; then
  pass=$((pass + 1)); echo "  ok    --all emits the full matrix (schedule runs)"
else
  fail=$((fail + 1)); printf '  FAIL  --all matrix\n        want %s\n        got  %s\n' "$want_all" "$got_all"
fi

# any= must agree with the matrix being non-empty, since the workflow gates on it.
for probe in "fastlane/Deliverfile:true" "CHANGELOG.md:false"; do
  path="${probe%:*}"; want="${probe#*:}"
  got=$(printf '%s\n' "$path" | "$MAPPER" | sed -n 's/^any=//p')
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); echo "  ok    any=$want for $path"
  else
    fail=$((fail + 1)); echo "  FAIL  any for $path: want $want got $got"
  fi
done

echo
if [ "$fail" -eq 0 ]; then
  echo "All $pass checks passed."
  exit 0
fi
echo "$fail failed, $pass passed."
exit 1

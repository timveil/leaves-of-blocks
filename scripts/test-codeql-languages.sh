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
echo "which languages an event is allowed to analyze"

# expect_event <description> <event> <expected "swift ruby actions"> <paths...>
expect_event() {
  local desc="$1" event="$2" want="$3"; shift 3
  local out got
  out=$(printf '%s\n' "$@" | "$MAPPER" --event "$event")
  got="$(sed -n 's/^swift=//p' <<<"$out") $(sed -n 's/^ruby=//p' <<<"$out") $(sed -n 's/^actions=//p' <<<"$out")"
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf '  ok    %s\n' "$desc"
  else
    fail=$((fail + 1)); printf '  FAIL  %s\n        want [%s] got [%s]\n' "$desc" "$want" "$got"
  fi
}

# Swift analysis costs ~18 min of traced build on a macOS runner and has never
# produced a finding here -- 30 analyses, 0 results, while every alert this
# project has had came from Ruby and Actions on Ubuntu in under a minute. So a
# pull request analyzes the languages that actually find things, and Swift moves
# to the merge commit, where it gates main without gating review.
expect_event "a PR withholds Swift"            pull_request "false false false" "App.swift"
expect_event "a PR still analyzes Ruby"        pull_request "false true false"  "fastlane/Fastfile"
expect_event "a PR still analyzes Actions"     pull_request "false false true"  ".github/workflows/ios.yml"
expect_event "a PR with both keeps both"       pull_request "false true true"   "App.swift" "Gemfile" ".github/workflows/ci.yml"

# The merge commit is where Swift is analyzed -- and only Swift: Ruby and
# Actions were already analyzed on the pull request that produced it.
expect_event "a push analyzes Swift"           push "true false false"  "App.swift"
expect_event "a push ignores Ruby"             push "false false false" "Gemfile"
expect_event "a push ignores Actions"          push "false false false" ".github/workflows/ios.yml"
expect_event "a push with a mixed diff"        push "true false false"  "App.swift" "Gemfile"

# any= gates the analyze job, so it has to follow the event filter rather than
# the raw diff, or the job starts with an empty matrix.
got=$(printf '%s\n' "App.swift" | "$MAPPER" --event pull_request | sed -n 's/^any=//p')
if [ "$got" = "false" ]; then
  pass=$((pass + 1)); echo "  ok    a Swift-only PR reports nothing to analyze"
else
  fail=$((fail + 1)); echo "  FAIL  Swift-only PR any=: want false got $got"
fi

got=$(printf '%s\n' "App.swift" | "$MAPPER" --event push | sed -n 's/^matrix=//p')
want='{"include":[{"language":"swift","runner":"macos-latest","build-mode":"manual"}]}'
if [ "$got" = "$want" ]; then
  pass=$((pass + 1)); echo "  ok    a push emits the Swift-only matrix"
else
  fail=$((fail + 1)); printf '  FAIL  push matrix\n        want %s\n        got  %s\n' "$want" "$got"
fi

# The scheduled run is the one that must not be narrowed: it exists to catch
# drift against unchanged code when a query suite updates.
got=$("$MAPPER" --all | sed -n 's/^swift=//p')
if [ "$got" = "true" ]; then
  pass=$((pass + 1)); echo "  ok    --all still analyzes Swift, whatever the event policy says"
else
  fail=$((fail + 1)); echo "  FAIL  --all swift=: want true got $got"
fi

# The push path falls back to --all when the diff base is unusable (a
# force-push, or the first push to a branch). Combined with the event filter
# that has to mean "Swift, whatever the diff said" -- not "everything", and
# certainly not "nothing".
got=$("$MAPPER" --event push --all </dev/null | sed -n 's/^swift=//p')
if [ "$got" = "true" ]; then
  pass=$((pass + 1)); echo "  ok    --event push --all falls back to analyzing Swift"
else
  fail=$((fail + 1)); echo "  FAIL  --event push --all swift=: want true got $got"
fi

got=$("$MAPPER" --event push --all </dev/null | sed -n 's/^ruby=//p')
if [ "$got" = "false" ]; then
  pass=$((pass + 1)); echo "  ok    the fallback still withholds Ruby from a push"
else
  fail=$((fail + 1)); echo "  FAIL  --event push --all ruby=: want false got $got"
fi

got=$("$MAPPER" --all --event pull_request </dev/null | sed -n 's/^swift=//p')
if [ "$got" = "false" ]; then
  pass=$((pass + 1)); echo "  ok    flag order does not matter"
else
  fail=$((fail + 1)); echo "  FAIL  --all --event pull_request swift=: want false got $got"
fi

"$MAPPER" --event nonsense </dev/null >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then
  pass=$((pass + 1)); echo "  ok    an unknown event is a usage error"
else
  fail=$((fail + 1)); echo "  FAIL  unknown event: want exit 2 got $code"
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "All $pass checks passed."
  exit 0
fi
echo "$fail failed, $pass passed."
exit 1

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
echo "divergent build configurations"

# Taking the first target and moving on would hide the exact failure that
# started this: #87 found 18.5 in the project because a *test* target had been
# set independently of the app. With no single floor there is nothing to check
# the docs against, and saying so beats silently picking one.
printf '\tIPHONEOS_DEPLOYMENT_TARGET = 18.0;\n\tIPHONEOS_DEPLOYMENT_TARGET = 18.5;\n' > "$TMP/split"
DOCS_CHECK_PBXPROJ="$TMP/split" "$CHECK" >/dev/null 2>&1; code=$?
if [ "$code" -eq 2 ]; then ok "disagreeing configurations are a setup error"; else bad "disagreeing configurations exit 2" "got $code"; fi

err=$(DOCS_CHECK_PBXPROJ="$TMP/split" "$CHECK" 2>&1 >/dev/null)
if grep -qF "18.0" <<<"$err" && grep -qF "18.5" <<<"$err"; then
  ok "both conflicting values are shown"
else
  bad "both values shown" "got: $err"
fi

printf '\tIPHONEOS_DEPLOYMENT_TARGET = 18.0;\n\tIPHONEOS_DEPLOYMENT_TARGET = 18.0;\n' > "$TMP/same"
DOCS_CHECK_PBXPROJ="$TMP/same" "$CHECK" >/dev/null 2>&1; code=$?
if [ "$code" -eq 0 ]; then ok "repeated identical values are fine"; else bad "identical values accepted" "got $code"; fi

echo
echo "the string catalog is in scope"

# The defect this closes: #89 lowered the target and five documents kept the old
# floor. The guard was written for that and found them -- but it read Markdown,
# and technical_description on the About screen said "iOS 18.5+" for months
# afterwards, in two languages. The copy users actually read in the app was the
# one copy nothing checked.
catalog_fixture() {
  cat > "$1" <<'EOF'
{
  "sourceLanguage" : "en",
  "strings" : {
    "technical_description" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Built with SwiftUI for iOS %EN%." } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Mit SwiftUI für iOS %DE% entwickelt." } }
      }
    }
  },
  "version" : "1.1"
}
EOF
  sed -i '' "s/%EN%/$2/; s/%DE%/$3/" "$1"
}

catalog_fixture "$TMP/catalog.xcstrings" "18.0" "18.0"
DOCS_CHECK_CATALOG="$TMP/catalog.xcstrings" "$CHECK" >/dev/null 2>&1; code=$?
if [ "$code" -eq 0 ]; then ok "a catalog agreeing with the project passes"; else bad "agreeing catalog passes" "got $code"; fi

catalog_fixture "$TMP/catalog.xcstrings" "18.5" "18.0"
DOCS_CHECK_CATALOG="$TMP/catalog.xcstrings" "$CHECK" >/dev/null 2>&1; code=$?
if [ "$code" -eq 1 ]; then ok "a stale floor in the catalog is caught"; else bad "stale catalog floor caught" "want exit 1, got $code"; fi

err=$(DOCS_CHECK_CATALOG="$TMP/catalog.xcstrings" "$CHECK" 2>&1 >/dev/null)
if grep -qF "xcstrings" <<<"$err"; then ok "the catalog is named in the failure"; else bad "catalog named" "got: $(head -2 <<<"$err")"; fi

# Every locale carries its own copy of the claim, so checking only the source
# language would pass while a translation still advertised the old floor --
# which is exactly the state Spanish was in.
catalog_fixture "$TMP/catalog.xcstrings" "18.0" "18.5"
DOCS_CHECK_CATALOG="$TMP/catalog.xcstrings" "$CHECK" >/dev/null 2>&1; code=$?
if [ "$code" -eq 1 ]; then ok "a stale floor in a translation is caught too"; else bad "translation floor caught" "want exit 1, got $code"; fi

# Keys and Xcode's auto-generated comments are not user-visible copy, and a
# key like "ios_18_5_note" should not fail a check about what users read.
cat > "$TMP/catalog.xcstrings" <<'EOF'
{
  "sourceLanguage" : "en",
  "strings" : {
    "note_about_ios_18_5" : {
      "comment" : "Shown on iOS 18.5 and later.",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "All good here." } }
      }
    }
  },
  "version" : "1.1"
}
EOF
DOCS_CHECK_CATALOG="$TMP/catalog.xcstrings" "$CHECK" >/dev/null 2>&1; code=$?
if [ "$code" -eq 0 ]; then ok "keys and comments are not mistaken for user-visible copy"; else bad "keys and comments ignored" "want exit 0, got $code"; fi

echo
echo "App Store copy is in scope"

# The listing states the floor to a reader who has not installed the app yet,
# and CLAUDE.md already requires the description to stay consistent with
# technical_description. Release notes are deliberately not scanned: they
# describe a moment in time and may name older versions truthfully.
probe_dir="fastlane/metadata/zz-probe"
mkdir -p "$probe_dir"
printf 'Requires iOS 12.9 or later.\n' > "$probe_dir/description.txt"
"$CHECK" >/dev/null 2>&1; code=$?
rm -rf "$probe_dir"
if [ "$code" -eq 1 ]; then ok "a stale floor in an App Store description is caught"; else bad "description scanned" "want exit 1, got $code"; fi

echo
echo "convention docs are in scope"

# tooling.yml triggers on conventions/**, so the guard has to actually read
# them -- running over a directory it ignores would be worse than not running.
printf '# Test\n\nRequires iOS 12.9 or later.\n' > conventions/_tmp_probe.md
"$CHECK" >/dev/null 2>&1; code=$?
rm -f conventions/_tmp_probe.md
if [ "$code" -eq 1 ]; then ok "a convention doc naming a wrong version is caught"; else bad "convention docs scanned" "want exit 1, got $code"; fi

echo
if [ "$fail" -eq 0 ]; then echo "All $pass checks passed."; exit 0; fi
echo "$fail failed, $pass passed."
exit 1

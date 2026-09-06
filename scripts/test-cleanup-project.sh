#!/bin/bash
#
# test-cleanup-project.sh - Exercise scripts/cleanup-project.sh.
#
# SAFETY: every invocation here passes --dry-run. Without it the script deletes
# ignored files, wipes ~/Library/Developer/Xcode/DerivedData, and prompts
# interactively -- none of which belongs in a test run. Each case builds a
# throwaway git repository under mktemp and runs the script inside it, so
# nothing touches the real project either way.
#
#   ./scripts/test-cleanup-project.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLEANUP="$SCRIPT_DIR/cleanup-project.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
ok()  { pass=$((pass + 1)); printf '  ok    %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf '  FAIL  %s\n        %s\n' "$1" "$2"; }

# make_repo <name> -> prints the path to a fresh git repo
make_repo() {
  local dir="$TMP/$1"
  mkdir -p "$dir"
  git init -q "$dir"
  git -C "$dir" config user.email "test@example.com"
  git -C "$dir" config user.name "Test"
  printf 'placeholder\n' > "$dir/README.md"
  git -C "$dir" add README.md
  git -C "$dir" commit -q -m "chore: Init"
  echo "$dir"
}

# run_dry <repo> -> sets RUN_OUT and RUN_CODE.
#
# Output goes through a file rather than command substitution: `x=$(f)` runs f
# in a subshell, so an exit code assigned inside it never reaches the caller.
# The cd is scoped to its own subshell so the harness stays put.
RUN_OUT=""
RUN_CODE=0
run_dry() {
  ( cd "$1" && "$CLEANUP" --dry-run ) > "$TMP/last-run.txt" 2>&1
  RUN_CODE=$?
  RUN_OUT="$(cat "$TMP/last-run.txt")"
}

echo "nothing to clean"

# A broken symlink is the case that used to abort the script: git lists it as
# an ignored untracked path, but `[ -e ]` follows the link and finds nothing,
# so the delete list ended up empty while $all_ignored was not -- and expanding
# that empty array under bash 3.2 with `set -u` is a hard error.
REPO="$(make_repo broken-symlink)"
printf 'broken-link\n' > "$REPO/.gitignore"
ln -s /nonexistent/target "$REPO/broken-link"
git -C "$REPO" add .gitignore && git -C "$REPO" commit -q -m "chore: Ignore"

run_dry "$REPO"; out="$RUN_OUT"
if [ "$RUN_CODE" -eq 0 ]; then
  ok "a listed-but-absent path exits 0"
else
  bad "listed-but-absent path exits 0" "got $RUN_CODE"
fi
if grep -qF "Nothing to clean" <<<"$out"; then
  ok "and says so"
else
  bad "and says so" "message missing"
fi
if grep -qF "unbound variable" <<<"$out"; then
  bad "no bash error leaks to the user" "unbound variable in output"
else
  ok "no bash error leaks to the user"
fi
if [ -L "$REPO/broken-link" ]; then
  ok "dry run left the symlink alone"
else
  bad "dry run left the symlink alone" "it was removed"
fi

# The already-clean case takes a different path -- an earlier return, before
# the delete list is built at all.
REPO="$(make_repo clean)"
run_dry "$REPO"; out="$RUN_OUT"
if [ "$RUN_CODE" -eq 0 ]; then ok "a clean repo exits 0"; else bad "clean repo exits 0" "got $RUN_CODE"; fi
if grep -qF "Project is clean" <<<"$out"; then
  ok "a clean repo says it is clean"
else
  bad "clean repo says so" "message missing"
fi

echo
echo "items present"

REPO="$(make_repo with-junk)"
printf 'junk.log\n' > "$REPO/.gitignore"
printf 'some output\n' > "$REPO/junk.log"
git -C "$REPO" add .gitignore && git -C "$REPO" commit -q -m "chore: Ignore"

run_dry "$REPO"; out="$RUN_OUT"
if [ "$RUN_CODE" -eq 0 ]; then ok "a repo with junk exits 0 under --dry-run"; else bad "junk repo exits 0" "got $RUN_CODE"; fi
if grep -qF "junk.log" <<<"$out"; then ok "the ignored file is listed"; else bad "ignored file listed" "not in output"; fi
if grep -qF "Dry run complete" <<<"$out"; then ok "dry run announces itself"; else bad "dry run announces itself" "missing"; fi
if [ -f "$REPO/junk.log" ]; then
  ok "dry run did not delete the file"
else
  bad "dry run did not delete the file" "junk.log is gone — dry run deleted something"
fi
if [ -f "$REPO/README.md" ]; then ok "tracked files untouched"; else bad "tracked files untouched" "README.md gone"; fi

echo
echo "arguments"

REPO="$(make_repo args)"
(cd "$REPO" && "$CLEANUP" --help >/dev/null 2>&1); code=$?
if [ "$code" -eq 0 ]; then ok "--help exits 0"; else bad "--help exits 0" "got $code"; fi

(cd "$REPO" && "$CLEANUP" --bogus >/dev/null 2>&1); code=$?
if [ "$code" -eq 1 ]; then ok "an unknown flag is rejected"; else bad "unknown flag rejected" "got $code"; fi

# Outside a git repository it must refuse rather than scan the filesystem.
mkdir -p "$TMP/not-a-repo"
(cd "$TMP/not-a-repo" && "$CLEANUP" --dry-run >/dev/null 2>&1); code=$?
if [ "$code" -eq 1 ]; then ok "refuses to run outside a git repository"; else bad "refuses outside a repo" "got $code"; fi

echo
if [ "$fail" -eq 0 ]; then echo "All $pass checks passed."; exit 0; fi
echo "$fail failed, $pass passed."
exit 1

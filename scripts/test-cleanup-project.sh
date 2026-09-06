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

# The bash 3.2 crash from #78 was reached by a broken symlink: git listed it,
# `[ -e ]` denied it, and the delete list ended up empty while $all_ignored was
# not. That path no longer produces an empty list -- broken symlinks are now
# collected -- so this asserts the crash stays gone rather than re-testing the
# route to it. The empty-list guard remains as defence against a path that
# disappears between git listing it and the loop reading it, which cannot be
# staged deterministically.
REPO="$(make_repo broken-symlink)"
printf 'broken-link\n' > "$REPO/.gitignore"
ln -s /nonexistent/target "$REPO/broken-link"
git -C "$REPO" add .gitignore && git -C "$REPO" commit -q -m "chore: Ignore"

run_dry "$REPO"; out="$RUN_OUT"
if [ "$RUN_CODE" -eq 0 ]; then
  ok "a repo whose only ignored item is a broken symlink exits 0"
else
  bad "broken-symlink repo exits 0" "got $RUN_CODE"
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
echo "symlinks"

REPO="$(make_repo symlinks)"
printf 'broken-link\ngood-link\ndir-link\n' > "$REPO/.gitignore"
printf 'precious\n' > "$REPO/target.txt"
mkdir -p "$REPO/target-dir" && printf 'precious\n' > "$REPO/target-dir/inside.txt"
git -C "$REPO" add .gitignore target.txt target-dir/inside.txt
git -C "$REPO" commit -q -m "chore: Add targets"
ln -s /nonexistent/target "$REPO/broken-link"
ln -s target.txt "$REPO/good-link"
ln -s target-dir "$REPO/dir-link"

run_dry "$REPO"; out="$RUN_OUT"
if grep -qF "broken-link" <<<"$out"; then
  ok "a broken symlink is listed rather than skipped"
else
  bad "broken symlink is listed" "not in output"
fi
if grep -qF "🔗 Symlink" <<<"$out"; then ok "symlinks are labelled as symlinks"; else bad "symlinks labelled" "no marker"; fi
if grep -qF "(broken)" <<<"$out"; then ok "a broken one says so"; else bad "broken one says so" "not marked"; fi
# -d follows the link, so dir-link would read as a directory without the -L test.
if grep -qE "📁 Directory:.*dir-link" <<<"$out"; then
  bad "a symlink to a directory is not called a directory" "labelled Directory"
else
  ok "a symlink to a directory is not called a directory"
fi

# get_size returned its value twice, so every size failed the caller's numeric
# check and became 0. The total was always 0B.
if grep -qE "Total size: [1-9]" <<<"$out"; then
  ok "sizes are reported rather than always zero"
else
  bad "sizes are reported" "total still reads zero: $(grep 'Total size' <<<"$out")"
fi

echo
echo "actual deletion"

# SAFETY: this is the only place the script runs for real. Un-isolated it would
# wipe ~/Library/Developer/Xcode/DerivedData, clear CoreSimulator logs and run
# `xcrun simctl delete unavailable` against the developer's machine. HOME is
# redirected to a throwaway directory and a no-op xcrun is put on PATH, so
# every one of those lands in $TMP or does nothing. The prompt is answered on
# stdin because a real run asks for confirmation.
STUB="$TMP/bin"
mkdir -p "$STUB" "$TMP/home"
printf '#!/bin/bash\nexit 0\n' > "$STUB/xcrun"
chmod +x "$STUB/xcrun"

REPO="$(make_repo deletion)"
printf 'junk.log\nbroken-link\ndir-link\n' > "$REPO/.gitignore"
mkdir -p "$REPO/target-dir" && printf 'precious\n' > "$REPO/target-dir/inside.txt"
git -C "$REPO" add .gitignore target-dir/inside.txt
git -C "$REPO" commit -q -m "chore: Add target"
printf 'output\n' > "$REPO/junk.log"
ln -s /nonexistent/target "$REPO/broken-link"
ln -s target-dir "$REPO/dir-link"

( cd "$REPO" && printf 'y\n' | env HOME="$TMP/home" PATH="$STUB:$PATH" "$CLEANUP" ) > "$TMP/live.txt" 2>&1
live_code=$?

if [ "$live_code" -eq 0 ]; then ok "a real run exits 0"; else bad "real run exits 0" "got $live_code: $(tail -2 "$TMP/live.txt")"; fi
if [ ! -e "$REPO/junk.log" ]; then ok "the ignored file is deleted"; else bad "ignored file deleted" "junk.log survived"; fi
if [ ! -L "$REPO/broken-link" ]; then ok "the broken symlink is deleted"; else bad "broken symlink deleted" "it survived — the whole point of this change"; fi
if [ ! -L "$REPO/dir-link" ]; then ok "the symlink to a directory is deleted"; else bad "dir symlink deleted" "it survived"; fi

# The safety property: removing a link must not reach through it.
if [ -d "$REPO/target-dir" ]; then ok "the directory behind the link survives"; else bad "directory behind link survives" "target-dir was destroyed"; fi
if [ -f "$REPO/target-dir/inside.txt" ]; then ok "its contents survive"; else bad "contents survive" "inside.txt was destroyed"; fi
if [ -f "$REPO/README.md" ]; then ok "tracked files survive a real run"; else bad "tracked files survive" "README.md was destroyed"; fi

# And the isolation held.
if [ -d "$TMP/home" ]; then ok "the fake HOME absorbed the system-wide cleanup"; else bad "fake HOME intact" "it was removed"; fi

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

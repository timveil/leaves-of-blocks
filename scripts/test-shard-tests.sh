#!/bin/bash
#
# test-shard-tests.sh - Exercise scripts/shard-tests.sh.
#
#   ./scripts/test-shard-tests.sh
#
# The splitting is worth testing rather than eyeballing: a shard that silently
# drops a test still reports success, and the tests it dropped stop running
# without anything going red. Every input line must land in exactly one shard.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARD="$SCRIPT_DIR/shard-tests.sh"

pass=0
fail=0
ok()  { pass=$((pass + 1)); printf '  ok    %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf '  FAIL  %s\n        %s\n' "$1" "$2"; }

five() { printf 'a\nb\nc\nd\ne\n'; }

echo "splitting"

got=$(five | "$SHARD" 1/2 | tr '\n' ' ')
if [ -n "$got" ]; then ok "shard 1 of 2 selects something ($got)"; else bad "shard 1 selects" "empty"; fi

got=$(five | "$SHARD" 2/2 | tr '\n' ' ')
if [ -n "$got" ]; then ok "shard 2 of 2 selects something ($got)"; else bad "shard 2 selects" "empty"; fi

# The property that matters: every test runs exactly once across the shards.
union=$( { five | "$SHARD" 1/2; five | "$SHARD" 2/2; } | sort | tr -d '\n')
if [ "$union" = "abcde" ]; then ok "the shards partition the input exactly"; else bad "shards partition input" "got '$union'"; fi

overlap=$( { five | "$SHARD" 1/2; five | "$SHARD" 2/2; } | sort | uniq -d)
if [ -z "$overlap" ]; then ok "no test lands in two shards"; else bad "no overlap" "duplicated: $overlap"; fi

# Three-way, to prove nothing assumes two.
union3=$( { five | "$SHARD" 1/3; five | "$SHARD" 2/3; five | "$SHARD" 3/3; } | sort | tr -d '\n')
if [ "$union3" = "abcde" ]; then ok "three shards also partition exactly"; else bad "three-way partition" "got '$union3'"; fi

# Balance: with 5 items over 2 shards nothing may be off by more than one.
n1=$(five | "$SHARD" 1/2 | wc -l | tr -d ' ')
n2=$(five | "$SHARD" 2/2 | wc -l | tr -d ' ')
if [ "$((n1 > n2 ? n1 - n2 : n2 - n1))" -le 1 ]; then ok "shards differ by at most one ($n1 vs $n2)"; else bad "balanced" "$n1 vs $n2"; fi

# Deterministic: CI runs the shards on separate machines, so the same input
# must split identically in both jobs or a test is dropped or doubled.
a=$(five | "$SHARD" 1/2); b=$(five | "$SHARD" 1/2)
if [ "$a" = "$b" ]; then ok "the split is deterministic"; else bad "deterministic" "two runs disagreed"; fi

# Order independence: xcodebuild's enumeration order is not contractual.
shuffled=$(printf 'e\nc\na\nd\nb\n' | "$SHARD" 1/2 | sort | tr -d '\n')
ordered=$(five | "$SHARD" 1/2 | sort | tr -d '\n')
if [ "$shuffled" = "$ordered" ]; then ok "input order does not change the split"; else bad "order independent" "'$shuffled' vs '$ordered'"; fi

echo
echo "edges"

got=$(printf 'only\n' | "$SHARD" 2/2 | wc -l | tr -d ' ')
if [ "$got" = "0" ]; then ok "a shard with nothing to do emits nothing"; else bad "empty shard" "got $got lines"; fi

got=$(printf '' | "$SHARD" 1/2 | wc -l | tr -d ' ')
if [ "$got" = "0" ]; then ok "empty input yields empty output"; else bad "empty input" "got $got lines"; fi

got=$(printf 'a\n\nb\n' | "$SHARD" 1/1 | wc -l | tr -d ' ')
if [ "$got" = "2" ]; then ok "blank lines are ignored"; else bad "blank lines ignored" "got $got"; fi

echo
echo "usage"

for bad_arg in "0/2" "3/2" "1/0" "abc" "1/" "/2" ""; do
  printf 'a\n' | "$SHARD" "$bad_arg" >/dev/null 2>&1; code=$?
  if [ "$code" -eq 2 ]; then ok "rejects '$bad_arg'"; else bad "rejects '$bad_arg'" "want exit 2, got $code"; fi
done

echo
if [ "$fail" -eq 0 ]; then echo "All $pass checks passed."; exit 0; fi
echo "$fail failed, $pass passed."
exit 1

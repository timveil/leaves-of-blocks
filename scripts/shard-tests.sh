#!/bin/bash
#
# shard-tests.sh - Split a list of test identifiers into one of N shards.
#
# Reads identifiers on stdin, one per line, and writes the ones belonging to
# shard <index> of <total> to stdout.
#
# Why: the UI suite runs serially in CI -- parallel simulator clones were
# disabled in build.sh because they crash -- so its ~8 minutes is wall-clock
# the whole pull request waits on. Splitting the tests across two JOBS gets the
# parallelism from separate runners instead of from clones on one, which is the
# part that was unstable.
#
# Selection is by position after sorting, so it does not depend on xcodebuild's
# enumeration order, and it is deterministic: the shards run on different
# machines and must agree on the split, or a test is silently dropped or run
# twice. Nothing here knows any test's name -- add a test and it lands in a
# shard on its own, which a hardcoded list in the workflow would not do
# (conventions/invariants-not-counts.md).
#
# Usage:
#   ./scripts/shard-tests.sh 1/2 < identifiers
#   xcodebuild ... -enumerate-tests ... | ./scripts/shard-tests.sh 2/2
#
# Exits 2 on a malformed shard specification.

set -euo pipefail

spec="${1:-}"

usage() {
  echo "usage: $0 <index>/<total>   (1-based, index <= total)" >&2
  exit 2
}

# More than one separator is rejected before anything is parsed out of it.
# "%%/*" and "##*/" take the outermost fields, so "1/2/3" would otherwise be
# read as shard 1 of 3 with the middle segment silently discarded -- a split
# that disagrees with what the caller asked for rather than refusing it.
case "$spec" in
  */*/*) usage ;;
esac

case "$spec" in
  [1-9]*/[1-9]*) ;;
  *) usage ;;
esac

index="${spec%%/*}"
total="${spec##*/}"

case "$index$total" in
  *[!0-9]*) usage ;;
esac

[ "$index" -ge 1 ] || usage
[ "$total" -ge 1 ] || usage
[ "$index" -le "$total" ] || usage

# Sorted so the order is ours rather than the enumerator's, then dealt round
# robin: with 5 tests over 2 shards that is 3 and 2, never 5 and 0.
position=0
while IFS= read -r line || [ -n "$line" ]; do
  [ -n "$line" ] || continue
  if [ "$((position % total))" -eq "$((index - 1))" ]; then
    printf '%s\n' "$line"
  fi
  position=$((position + 1))
done < <(sort)

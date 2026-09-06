#!/bin/bash
#
# run-script-tests.sh - run every scripts/test-*.sh and summarize.
#
# The repository's CI logic lives in shell scripts (conventions/workflow-scripts.md),
# each with a companion test-*.sh. This is the one entry point that runs them
# all, used by .github/workflows/tooling.yml and useful locally:
#
#   ./scripts/run-script-tests.sh
#   ./scripts/run-script-tests.sh --dir some/other/dir   # used by its own tests
#
# Exits 0 only when every suite passes. Getting that wrong is the dangerous
# failure: a runner that swallows a non-zero suite reports a green build while
# the tests underneath it are failing, which is worse than having no runner.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="$SCRIPT_DIR"

if [ "${1:-}" = "--dir" ]; then
  if [ -z "${2:-}" ]; then
    echo "usage: $0 [--dir <directory>]" >&2
    exit 2
  fi
  DIR="$2"
elif [ "$#" -gt 0 ]; then
  echo "usage: $0 [--dir <directory>]" >&2
  exit 2
fi

shopt -s nullglob
suites=("$DIR"/test-*.sh)
shopt -u nullglob

if [ "${#suites[@]}" -eq 0 ]; then
  # Not a pass. An empty run almost always means a wrong path or a rename,
  # and reporting success for it is how a suite silently stops being run.
  echo "run-script-tests.sh: no test-*.sh suites found in $DIR" >&2
  exit 1
fi

passed=()
failed=()

for suite in "${suites[@]}"; do
  name="$(basename "$suite")"
  echo "═══════════════════════════════════════════════════"
  echo "  $name"
  echo "═══════════════════════════════════════════════════"

  if [ ! -x "$suite" ]; then
    echo "  not executable — chmod +x $suite" >&2
    failed+=("$name")
    continue
  fi

  if "$suite"; then
    passed+=("$name")
  else
    failed+=("$name")
  fi
  echo
done

echo "═══════════════════════════════════════════════════"
echo "  ${#passed[@]} suite(s) passed, ${#failed[@]} failed"
# Guarded: macOS ships bash 3.2, where expanding an empty array as
# "${failed[@]}" under `set -u` is an "unbound variable" error. Unguarded, this
# loop aborted the runner on a fully passing run -- red CI precisely when every
# suite was green.
if [ "${#failed[@]}" -gt 0 ]; then
  for name in "${failed[@]}"; do
    echo "  FAILED: $name"
  done
fi
echo "═══════════════════════════════════════════════════"

[ "${#failed[@]}" -eq 0 ]

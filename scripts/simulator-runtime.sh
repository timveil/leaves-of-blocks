#!/bin/bash
#
# simulator-runtime.sh - Pick the iOS simulator runtime to build screenshots on.
#
# fastlane's Snapfile needs an exact runtime version, and it used to be a
# hand-maintained constant in Constants.rb whose comment read "Update when the
# runtime changes". That is a maintenance task whose only reminder is a release
# failing partway through, since screenshots run inside `deploy`.
#
# This derives it instead: the newest installed runtime at or above the app's
# deployment target. Nothing to update when Xcode rotates runtimes.
#
# Two versions are in play and they are not always the same string. `simctl`
# lists a runtime as `iOS 26.4 (26.4.1 - 23E254a)`: "26.4" is the label, and
# "26.4.1" is the point version. xcodebuild's -destination needs the point
# version. Both forms are emitted so callers can pick.
#
# Usage:
#   ./scripts/simulator-runtime.sh                  # newest point version >= floor
#   ./scripts/simulator-runtime.sh --label          # its label ("iOS 26.4" -> 26.4)
#   ./scripts/simulator-runtime.sh --min            # the floor (deployment target)
#   ./scripts/simulator-runtime.sh --list           # "point<TAB>label" for each runtime
#   ./scripts/simulator-runtime.sh --from [--label] # same, reading --list lines on stdin
#
# Parsed from `simctl list runtimes available` text rather than the JSON form,
# matching scripts/build.sh: the JSON path needs an interpreter, and python3 on
# a machine with an asdf/pyenv shim and no version selected exits non-zero and
# takes the script with it.
#
# Exits 0 on success, 1 when nothing qualifies, 2 on usage/setup error.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PBXPROJ="${SIMULATOR_RUNTIME_PBXPROJ:-$ROOT/LeavesOfBlocks.xcodeproj/project.pbxproj}"

# The floor is the app's own deployment target, read from the project so there
# is no second copy of it to drift (conventions/shared-rule-single-source.md).
minimum() {
  local value
  # `|| true` is load-bearing. Under `set -euo pipefail` a failing sed (missing
  # file) makes the substitution non-zero, and `set -e` aborts here -- before
  # the check below can say which file it could not read. The caller would get
  # a bare exit code instead of the message written for exactly this case.
  value="$(sed -nE 's/^[[:space:]]*IPHONEOS_DEPLOYMENT_TARGET = ([0-9][0-9.]*);.*/\1/p' "$PBXPROJ" 2>/dev/null | head -1 || true)"

  if [ -z "$value" ]; then
    echo "simulator-runtime.sh: could not read IPHONEOS_DEPLOYMENT_TARGET from $PBXPROJ" >&2
    exit 2
  fi
  printf '%s\n' "$value"
}

# version_ge A B -> 0 when A >= B. sort -V compares components numerically, so
# 26.10 ranks above 26.9 where a lexical sort would invert them.
version_ge() {
  [ "$1" = "$2" ] && return 0
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$2" ]
}

# "<point version><TAB><label version>" for each installed iOS runtime.
# `available` drops runtimes that are present but unusable.
list_runtimes() {
  xcrun simctl list runtimes available \
    | sed -nE 's/^iOS ([0-9][0-9.]*) \(([0-9][0-9.]*) - [^)]*\).*/\2\t\1/p'
}

# Newest candidate meeting the floor. Reads list lines on stdin so the choice
# can be tested without installing runtimes.
select_from() {
  local min="$1" want_label="$2" point label best_point="" best_label=""

  while IFS=$'\t' read -r point label; do
    [ -n "$point" ] || continue
    version_ge "$point" "$min" || continue
    if [ -z "$best_point" ] || version_ge "$point" "$best_point"; then
      best_point="$point"
      best_label="$label"
    fi
  done

  if [ -z "$best_point" ]; then
    echo "simulator-runtime.sh: no installed iOS runtime is at or above $min" >&2
    echo "Install one via Xcode > Settings > Components, or lower IPHONEOS_DEPLOYMENT_TARGET." >&2
    return 1
  fi

  if [ "$want_label" = true ]; then
    printf '%s\n' "$best_label"
  else
    printf '%s\n' "$best_point"
  fi
}

want_label=false
mode="version"

for arg in "$@"; do
  case "$arg" in
    --label)   want_label=true ;;
    --min)     mode="min" ;;
    --list)    mode="list" ;;
    --from)    mode="from" ;;
    --version) mode="version" ;;
    *)
      echo "usage: $0 [--label] [--min | --list | --from]" >&2
      exit 2
      ;;
  esac
done

case "$mode" in
  min)     minimum ;;
  list)    list_runtimes ;;
  from)    select_from "$(minimum)" "$want_label" ;;
  version) list_runtimes | select_from "$(minimum)" "$want_label" ;;
esac

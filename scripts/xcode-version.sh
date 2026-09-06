#!/bin/bash
#
# xcode-version.sh - single source of truth for the Xcode this project needs.
#
# The floor lives in .xcode-version at the repository root and is read by
# everything that cares: fastlane's before_all, and the CI workflows. Nothing
# re-encodes it (see conventions/shared-rule-single-source.md).
#
# It is a MINIMUM, not an exact pin. An exact pin means every Xcode auto-update
# breaks every fastlane lane until someone edits a constant -- which is exactly
# what happened when the machine moved to 26.6 against a hardcoded 26.5 and
# `beta`, `deploy` and `screenshots` all began failing in before_all.
#
# Note for tooling: .xcode-version is a de-facto standard filename (xcodes,
# xcode-install, fastlane's own ensure_xcode_version all read it) where it
# normally means "exactly this version". This project treats it as a floor.
#
# Usage:
#   ./scripts/xcode-version.sh                     # print the minimum
#   ./scripts/xcode-version.sh --check             # verify the selected Xcode meets it
#   ./scripts/xcode-version.sh --check 26.6        # verify a specific version meets it
#   ./scripts/xcode-version.sh --select            # newest installed Xcode >= minimum, print DEVELOPER_DIR
#   ./scripts/xcode-version.sh --select-from       # same, from "version<TAB>path" lines on stdin
#
# XCODE_VERSION_FILE overrides which file the floor is read from; it exists so
# the comparison can be tested at boundaries the checked-in floor cannot reach.
#
# Exits 0 on success, 1 when the requirement is not met, 2 on usage/setup error.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="${XCODE_VERSION_FILE:-$ROOT/.xcode-version}"

minimum() {
  if [ ! -f "$VERSION_FILE" ]; then
    echo "xcode-version.sh: missing $VERSION_FILE" >&2
    exit 2
  fi
  printf '%s\n' "$(tr -d '[:space:]' < "$VERSION_FILE")"
}

# version_ge A B -> 0 when A >= B.
#
# sort -V compares version components numerically, so 26.10 sorts above 26.9.
# A plain lexical sort gets that backwards, which would silently accept an
# Xcode older than the floor once minor versions reach double digits.
version_ge() {
  [ "$1" = "$2" ] && return 0
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$2" ]
}

# Deliberately non-fatal. When no Xcode is selected -- xcode-select pointing at
# the Command Line Tools, or no Xcode installed at all -- xcodebuild exits
# non-zero, and under `set -e` with pipefail that would abort the script from
# inside the command substitution in --check, before it can say why. The caller
# needs an empty string back so it can emit its own message and exit 2, which
# is the whole reason this script exists.
selected_xcode_version() {
  xcodebuild -version 2>/dev/null | awk 'NR==1 { print $2 }' || true
}

# Emit "version<TAB>developer-dir" for every Xcode in /Applications. Reading
# version.plist is both faster and more reliable than parsing the app name --
# GitHub runners name them Xcode_26.0.1.app, a local install is just Xcode.app.
list_installed() {
  local app version
  for app in /Applications/Xcode*.app; do
    [ -d "$app" ] || continue
    version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
      "$app/Contents/version.plist" 2>/dev/null || true)"
    [ -n "$version" ] || continue
    printf '%s\t%s/Contents/Developer\n' "$version" "$app"
  done
}

# Newest candidate meeting the floor. Reads "version<TAB>path" on stdin so the
# selection can be tested without installing Xcodes.
select_from() {
  local min="$1" version path best_version="" best_path=""
  while IFS=$'\t' read -r version path; do
    [ -n "$version" ] || continue
    version_ge "$version" "$min" || continue
    if [ -z "$best_version" ] || version_ge "$version" "$best_version"; then
      best_version="$version"
      best_path="$path"
    fi
  done

  if [ -z "$best_path" ]; then
    echo "xcode-version.sh: no installed Xcode meets the minimum of $min" >&2
    return 1
  fi

  echo "$best_path"
}

case "${1:---min}" in
  --min)
    minimum
    ;;

  --check)
    min="$(minimum)"
    actual="${2:-$(selected_xcode_version)}"
    if [ -z "$actual" ]; then
      echo "xcode-version.sh: could not determine the selected Xcode version" >&2
      exit 2
    fi
    if version_ge "$actual" "$min"; then
      echo "Xcode $actual meets the minimum of $min"
    else
      cat >&2 <<EOF
xcode-version.sh: Xcode $actual is older than the minimum of $min.

Install a newer Xcode, or point at one you already have:
  sudo xcode-select -s /Applications/Xcode.app

The minimum is declared in .xcode-version. Raise it only when the project
genuinely requires a newer toolchain -- it is a floor, not a pin.
EOF
      exit 1
    fi
    ;;

  --select)
    list_installed | select_from "$(minimum)"
    ;;

  --select-from)
    select_from "$(minimum)"
    ;;

  *)
    echo "usage: $0 [--min | --check [version] | --select | --select-from]" >&2
    exit 2
    ;;
esac

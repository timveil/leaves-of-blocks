#!/bin/bash
#
# check-locales.sh - Verify every locale registry agrees with .locales.
#
# The set of shipped locales used to be declared in four independent places,
# none of which knew about the others:
#
#   knownRegions in project.pbxproj      Xcode
#   localizations in Localizable.xcstrings   Xcode
#   SCREENSHOT_LANGUAGES in Constants.rb repo
#   fastlane/metadata/<locale>/          repo
#
# They already disagreed. The app ships Spanish in-app while the App Store
# listing is English-only, so Spanish-speaking players get an English product
# page -- and nothing failed, because no single thing knew both facts.
# Adding a language multiplies four chances to get that wrong, silently:
# the locale is not broken, it is just quietly missing from the listing or the
# screenshots (conventions/shared-rule-single-source.md).
#
# .locales is the declaration; this script checks the four registries against
# it. knownRegions and the string catalog are Xcode-owned and cannot be
# generated, so this checks rather than writes -- the same shape as
# check-docs-versions.sh.
#
# It also catches a second class of defect the same pass makes cheap: a
# "key".localized lookup with no catalog entry behind it, which renders the raw
# key on screen. Three of those were live and invisible when this was written.
#
# Usage:
#   ./scripts/check-locales.sh          # check every registry
#   ./scripts/check-locales.sh --store  # print the declared App Store locales
#   ./scripts/check-locales.sh --app    # print the declared in-app languages
#
# LOCALES_ROOT and LOCALES_MANIFEST override what is read, so the failures
# worth testing can be staged in a fixture instead of the checked-in files.
#
# Exits 0 when the registries agree, 1 when one disagrees, 2 on setup error.

set -euo pipefail

ROOT="${LOCALES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MANIFEST="${LOCALES_MANIFEST:-$ROOT/.locales}"
PBXPROJ="$ROOT/LeavesOfBlocks.xcodeproj/project.pbxproj"
CATALOG="$ROOT/LeavesOfBlocks/Resources/Localizable.xcstrings"
CONSTANTS="$ROOT/fastlane/Constants.rb"
METADATA_DIR="$ROOT/fastlane/metadata"
SOURCES="$ROOT/LeavesOfBlocks"

# What deliver uploads per locale. The first six need translating; the three
# URL files are copied -- but a locale missing them ships a product page with
# no support or privacy link, so they are required all the same.
METADATA_FILES="description.txt keywords.txt name.txt promotional_text.txt \
release_notes.txt subtitle.txt marketing_url.txt privacy_url.txt support_url.txt"

status=0
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

setup_error() { echo "check-locales.sh: $*" >&2; exit 2; }
problem() { status=1; printf '  ✗ %s\n' "$*" >&2; }
good() { printf '  ✓ %s\n' "$*"; }

# Membership test over a list passed as arguments. Callers expand possibly
# empty arrays as ${arr[@]+"${arr[@]}"}: under `set -u` bash 3.2 -- which is
# what macOS ships -- expanding an empty array as "${arr[@]}" is an unbound
# variable error, and every locale list here can legitimately be empty.
contains() {
  local needle="$1" item
  shift
  for item in "$@"; do
    if [ "$item" = "$needle" ]; then return 0; fi
  done
  return 1
}

# ── the manifest ────────────────────────────────────────────────────────────

STORE_LOCALES=()
APP_LANGUAGES=()

read_manifest() {
  [ -f "$MANIFEST" ] || setup_error "missing $MANIFEST"

  local line number=0 store app
  while IFS= read -r line || [ -n "$line" ]; do
    number=$((number + 1))
    line="${line%%#*}"
    # shellcheck disable=SC2086 # deliberate: word splitting is the parse
    set -- $line
    [ "$#" -gt 0 ] || continue
    if [ "$#" -ne 2 ]; then
      setup_error "$MANIFEST:$number: expected two columns (store locale, app language), got $#"
    fi
    store="$1"
    app="$2"
    if [ "$store" = "-" ] && [ "$app" = "-" ]; then
      setup_error "$MANIFEST:$number: a row must ship on at least one side"
    fi
    if [ "$store" != "-" ]; then STORE_LOCALES+=("$store"); fi
    if [ "$app" != "-" ]; then APP_LANGUAGES+=("$app"); fi
  done < "$MANIFEST"

  if [ "${#STORE_LOCALES[@]}" -eq 0 ] && [ "${#APP_LANGUAGES[@]}" -eq 0 ]; then
    setup_error "$MANIFEST declares no locales"
  fi
}

# ── knownRegions ────────────────────────────────────────────────────────────

check_known_regions() {
  [ -f "$PBXPROJ" ] || setup_error "missing $PBXPROJ"

  local before="$status" regions region language
  regions="$(sed -n '/knownRegions = (/,/);/p' "$PBXPROJ" \
    | sed -nE 's/^[[:space:]]*([A-Za-z0-9_+-]+),[[:space:]]*$/\1/p' || true)"

  [ -n "$regions" ] || setup_error "could not read knownRegions from $PBXPROJ"

  for language in ${APP_LANGUAGES[@]+"${APP_LANGUAGES[@]}"}; do
    if ! grep -qxF -- "$language" <<<"$regions"; then
      problem "knownRegions in project.pbxproj is missing '$language' (Xcode: project → Info → Localizations)"
    fi
  done

  # "Base" is Xcode's development-region pseudo-entry, not a language.
  for region in $regions; do
    if [ "$region" = "Base" ]; then continue; fi
    if ! contains "$region" ${APP_LANGUAGES[@]+"${APP_LANGUAGES[@]}"}; then
      problem "knownRegions in project.pbxproj carries '$region', which .locales does not declare"
    fi
  done

  if [ "$status" -eq "$before" ]; then good "knownRegions matches the declared app languages"; fi
}

# ── the string catalog ──────────────────────────────────────────────────────

# Reads the catalog once into $WORK: every key, and the languages each
# translatable key carries. plutil is used rather than a JSON parser the repo
# would have to depend on -- it ships with macOS, which every build here needs
# anyway.
CATALOG_KEYS=""
CATALOG_LANGUAGES=""
TRANSLATABLE=0

read_catalog() {
  [ -f "$CATALOG" ] || setup_error "missing $CATALOG"

  CATALOG_KEYS="$(plutil -extract strings raw -o - "$CATALOG" 2>/dev/null)" \
    || setup_error "could not read the strings table from $CATALOG"

  local key languages
  : > "$WORK/languages"
  while IFS= read -r key; do
    [ -n "$key" ] || continue
    # "." separates components of a plutil keypath, so a key containing one
    # cannot be addressed and would come back empty -- indistinguishable from a
    # fragment, and silently absent from every coverage figure. No key has a dot
    # today; say so loudly rather than under-report on the day one does.
    case "$key" in
      *.*) setup_error "$CATALOG: key '$key' contains a '.', which plutil cannot address as a keypath" ;;
    esac
    # A key with no localizations object at all is an Xcode-managed format
    # fragment ("%@", "(%@)", a bullet): the source string is the value and
    # there is nothing to translate. Counting those as untranslated would put
    # full coverage permanently out of reach.
    languages="$(plutil -extract "strings.$key.localizations" raw -o - "$CATALOG" 2>/dev/null || true)"
    [ -n "$languages" ] || continue
    TRANSLATABLE=$((TRANSLATABLE + 1))
    printf '%s\n' "$languages" >> "$WORK/languages"
  done <<<"$CATALOG_KEYS"

  CATALOG_LANGUAGES="$(sort -u "$WORK/languages" || true)"
}

check_catalog() {
  local before="$status" language

  for language in ${APP_LANGUAGES[@]+"${APP_LANGUAGES[@]}"}; do
    if ! grep -qxF -- "$language" <<<"$CATALOG_LANGUAGES"; then
      problem "Localizable.xcstrings has no '$language' localization (Xcode: String Catalog editor → + language)"
    fi
  done

  for language in $CATALOG_LANGUAGES; do
    if ! contains "$language" ${APP_LANGUAGES[@]+"${APP_LANGUAGES[@]}"}; then
      problem "Localizable.xcstrings carries '$language', which .locales does not declare"
    fi
  done

  if [ "$status" -eq "$before" ]; then good "Localizable.xcstrings carries the declared app languages"; fi
}

# Coverage is reported, never failed. A language can land in the catalog before
# it is fully translated -- that is a normal intermediate state, and a gate here
# would mean no language could be added except in one all-or-nothing commit.
report_coverage() {
  local language translated missing

  [ "${#APP_LANGUAGES[@]}" -gt 0 ] || return 0

  echo
  echo "Catalog coverage (reported, never failed):"
  for language in "${APP_LANGUAGES[@]}"; do
    translated="$(grep -cxF -- "$language" "$WORK/languages" || true)"
    translated="${translated//[[:space:]]/}"
    missing=$((TRANSLATABLE - translated))
    if [ "$missing" -gt 0 ]; then
      printf '  %s: %d of %d translated (%d untranslated)\n' "$language" "$translated" "$TRANSLATABLE" "$missing"
    else
      printf '  %s: %d of %d translated\n' "$language" "$translated" "$TRANSLATABLE"
    fi
  done
}

# ── SCREENSHOT_LANGUAGES ────────────────────────────────────────────────────

check_screenshot_languages() {
  [ -f "$CONSTANTS" ] || setup_error "missing $CONSTANTS"

  local before="$status" block languages locale
  block="$(sed -n '/SCREENSHOT_LANGUAGES[[:space:]]*=[[:space:]]*\[/,/\]/p' "$CONSTANTS" || true)"
  [ -n "$block" ] || setup_error "could not find SCREENSHOT_LANGUAGES in $CONSTANTS"

  languages="$(sed -nE 's/.*"([^"]+)".*/\1/p' <<<"$block" || true)"

  for locale in ${STORE_LOCALES[@]+"${STORE_LOCALES[@]}"}; do
    if ! grep -qxF -- "$locale" <<<"$languages"; then
      problem "SCREENSHOT_LANGUAGES in fastlane/Constants.rb is missing '$locale'"
    fi
  done

  for locale in $languages; do
    if ! contains "$locale" ${STORE_LOCALES[@]+"${STORE_LOCALES[@]}"}; then
      problem "SCREENSHOT_LANGUAGES in fastlane/Constants.rb carries '$locale', which .locales does not declare as a store locale"
    fi
  done

  if [ "$status" -eq "$before" ]; then good "SCREENSHOT_LANGUAGES matches the declared store locales"; fi
}

# ── App Store metadata ──────────────────────────────────────────────────────

check_metadata() {
  local before="$status" locale file directory name

  for locale in ${STORE_LOCALES[@]+"${STORE_LOCALES[@]}"}; do
    if [ ! -d "$METADATA_DIR/$locale" ]; then
      problem "fastlane/metadata/$locale/ does not exist, so that territory gets the English listing"
      continue
    fi
    for file in $METADATA_FILES; do
      if [ ! -f "$METADATA_DIR/$locale/$file" ]; then
        problem "fastlane/metadata/$locale/$file is missing"
      elif [ ! -s "$METADATA_DIR/$locale/$file" ]; then
        # Worse than missing: deliver uploads the empty file and blanks the
        # field on the live listing.
        problem "fastlane/metadata/$locale/$file is empty"
      fi
    done
  done

  # A directory left behind by a dropped locale keeps being uploaded. Only
  # directories are locales here -- copyright.txt, the category files and
  # app_rating_config.json sit beside them and are listing-wide.
  if [ -d "$METADATA_DIR" ]; then
    for directory in "$METADATA_DIR"/*/; do
      [ -d "$directory" ] || continue
      name="$(basename "$directory")"
      if ! contains "$name" ${STORE_LOCALES[@]+"${STORE_LOCALES[@]}"}; then
        problem "fastlane/metadata/$name/ is uploaded but .locales does not declare '$name'"
      fi
    done
  fi

  if [ "$status" -eq "$before" ]; then good "fastlane/metadata carries the declared store locales"; fi
}

# ── every .localized key resolves ───────────────────────────────────────────

check_localized_keys() {
  local before="$status" hit file number content trimmed literal key

  [ -d "$SOURCES" ] || setup_error "missing $SOURCES"

  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    file="${hit%%:*}"
    content="${hit#*:}"
    number="${content%%:*}"
    content="${content#*:}"

    # A lookup inside a comment is an illustration, not a key:
    # String+Extensions.swift documents the pattern with `"Game Over".localized`
    # and no catalog entry backs it, nor should one.
    #
    # Three shapes: `//`, a block comment's opening `/*`, and the `*` its
    # continuation lines carry. Matching only the last two would leave the first
    # line of every /* ... */ block read as live code.
    #
    # Only whole-line comments are skipped -- a lookup trailing live code after
    # `//` is still checked, which has not come up and would be a strange line
    # to write.
    trimmed="${content#"${content%%[![:space:]]*}"}"
    case "$trimmed" in
      //*|/\**|\**) continue ;;
    esac

    while IFS= read -r literal; do
      [ -n "$literal" ] || continue
      key="${literal%\".localized}"
      key="${key#\"}"
      if ! grep -qxF -- "$key" <<<"$CATALOG_KEYS"; then
        problem "${file#"$ROOT/"}:$number looks up \"$key\", which has no entry in Localizable.xcstrings"
      fi
    done < <(grep -oE '"[^"]+"\.localized' <<<"$content" || true)
  done < <(grep -rn --include='*.swift' -E '"[^"]+"\.localized' "$SOURCES" || true)

  if [ "$status" -eq "$before" ]; then
    good "every \"key\".localized lookup resolves to a catalog entry"
  fi
}

# ── entry point ─────────────────────────────────────────────────────────────

case "${1:-}" in
  "") ;;
  --store)
    read_manifest
    if [ "${#STORE_LOCALES[@]}" -gt 0 ]; then printf '%s\n' "${STORE_LOCALES[@]}"; fi
    exit 0
    ;;
  --app)
    read_manifest
    if [ "${#APP_LANGUAGES[@]}" -gt 0 ]; then printf '%s\n' "${APP_LANGUAGES[@]}"; fi
    exit 0
    ;;
  *)
    echo "usage: $0 [--store | --app]" >&2
    exit 2
    ;;
esac

read_manifest
read_catalog

check_known_regions
check_catalog
check_screenshot_languages
check_metadata
check_localized_keys
report_coverage

if [ "$status" -ne 0 ]; then
  cat >&2 <<EOF

────────────────────────────────────────────────────────────────────
The registries above disagree with .locales, which is the single
declaration of what this project ships.

Either add the locale to the registry that is missing it, or -- if it
is not shipped yet -- say so in .locales with "-" in that column.

  .locales                          what ships, store side and app side
  project.pbxproj → knownRegions    Xcode: project → Info → Localizations
  Localizable.xcstrings             Xcode: String Catalog editor
  fastlane/Constants.rb             SCREENSHOT_LANGUAGES
  fastlane/metadata/<locale>/       the App Store listing
────────────────────────────────────────────────────────────────────
EOF
  exit 1
fi

exit 0

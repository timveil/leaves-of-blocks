#!/bin/bash
#
# check-deliverfile-paths.sh - Load the Deliverfile and report where its
# filesystem paths resolve.
#
# app_rating_config_path was written as "./fastlane/metadata/app_rating_config.json".
# fastlane chdirs into fastlane/ before running a lane, so deliver expanded that
# to fastlane/fastlane/metadata/... and the age rating answers would not have
# been found (#101).
#
# Loading is the check. deliver validates such options with a verify_block, so a
# bad path raises here rather than needing to be inspected:
#
#   Could not find config file at path
#   '.../fastlane/fastlane/metadata/app_rating_config.json'
#
# That covers any option deliver validates, not only the one that broke, and it
# is broader than `fastlane lanes` -- which never loads the Deliverfile at all.
#
# Not a linter for relative literals: metadata_path and screenshots_path are
# relative literals too and work fine, because deliver resolves them itself.
# Nothing in the shape of the string separates the broken one from the working
# ones; only loading does.
#
# deliver would eventually catch this during a deploy -- after screenshots were
# captured and the release commit made. The point of checking here is to find it
# before a release starts.
#
# Usage:
#   ./scripts/check-deliverfile-paths.sh
#
# Exits 0 when the Deliverfile loads, 1 when it does not, 2 on setup error.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v bundle > /dev/null 2>&1; then
  echo "check-deliverfile-paths.sh: bundler is not available" >&2
  exit 2
fi

# From fastlane/, which is where fastlane runs a lane from. Loading it anywhere
# else would test a situation that never occurs.
cd "$ROOT/fastlane"

# Findings go to stderr so deliver's configuration table can be discarded from
# stdout without a pipe, which would otherwise swallow the exit code.
exec bundle exec ruby -e '
  require "fastlane"
  require "deliver"

  options = FastlaneCore::Configuration.create(Deliver::Options.available_options, {})
  options.load_configuration_file("Deliverfile")

  [:app_rating_config_path, :metadata_path, :screenshots_path].each do |key|
    value = options[key]
    next if value.nil?
    resolved = File.expand_path(value.to_s)
    marker = File.exist?(resolved) ? "resolves" : "deliver-relative"
    warn format("  %-24s %-16s %s", key, marker, resolved.sub(Dir.home, "~"))
  end

  warn "Deliverfile loads; validated paths resolve"
' > /dev/null

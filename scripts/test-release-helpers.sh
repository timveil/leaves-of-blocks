#!/bin/bash
#
# test-release-helpers.sh - Run the Ruby suite for fastlane/release_helpers.rb.
#
# A thin wrapper so run-script-tests.sh discovers it alongside the shell suites
# and CI has one entry point. Plain `ruby`, not `bundle exec`: release_helpers.rb
# requires xcodeproj lazily inside the methods that need it, so the pure
# functions load with no gems installed.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec ruby "$ROOT/fastlane/test/release_helpers_test.rb"

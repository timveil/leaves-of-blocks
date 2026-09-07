#!/bin/bash
#
# test-ai-helper.sh - Run the Ruby suite for fastlane/AIHelper.rb.
#
# A thin wrapper so run-script-tests.sh discovers it alongside the shell suites,
# matching test-release-helpers.sh. Plain `ruby`: AIHelper.rb requires only
# stdlib and falls back to puts when FastlaneCore is absent, so the response
# handling loads with no gems installed.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec ruby "$ROOT/fastlane/test/ai_helper_test.rb"

#!/usr/bin/env ruby
#
# release_helpers_test.rb - Exercise the pure functions in release_helpers.rb.
#
# No framework: minitest is a bundled rather than default gem, and adding a
# dependency to test two regexes is a poor trade. This matches the hand-rolled
# style of the shell suites in scripts/.
#
# Only functions that touch neither the network nor a real Xcode project are
# covered here -- the regex-driven ones, where a subtle mistake is silent and
# expensive: a changelog section that swallows the link footer, or a version
# bump that resolves to the wrong number and tags a release accordingly.
#
#   ruby fastlane/test/release_helpers_test.rb

# release_helpers.rb calls FastlaneCore::UI for reporting and for aborting.
# Stub it so the error paths can be exercised outside a lane.
module FastlaneCore
  class UserError < StandardError; end

  module UI
    def self.message(_msg); end
    def self.success(_msg); end
    def self.important(_msg); end
    def self.user_error!(msg)
      raise UserError, msg
    end
  end
end

require_relative '../release_helpers'

$pass = 0
$fail = 0

def ok(desc)
  $pass += 1
  puts "  ok    #{desc}"
end

def bad(desc, detail)
  $fail += 1
  puts "  FAIL  #{desc}"
  puts "        #{detail}"
end

def assert_equal(expected, actual, desc)
  if expected == actual
    ok(desc)
  else
    bad(desc, "expected #{expected.inspect}, got #{actual.inspect}")
  end
end

def assert_raises(desc)
  yield
  bad(desc, "expected an error, none raised")
rescue FastlaneCore::UserError
  ok(desc)
rescue StandardError => e
  bad(desc, "expected FastlaneCore::UserError, got #{e.class}: #{e.message}")
end

CHANGELOG = <<~MD
  # Changelog

  ## [Unreleased]

  ### Added
  - Something pending

  ## [2.0.6] - 2026-06-20

  ### Added
  - Undo and Hint assists

  ### Fixed
  - Taper drag lift near the top of the board

  ## [2.0.5] - 2026-05-17

  ### Added
  - Background audio mixing

  ## [1.0] - 2026-01-01

  ### Added
  - First release

  [Unreleased]: https://github.com/timveil/leaves-of-blocks/compare/v2.0.6...HEAD
  [2.0.6]: https://github.com/timveil/leaves-of-blocks/compare/v2.0.5...v2.0.6
MD

puts "extract_changelog_section"

section = extract_changelog_section(CHANGELOG, '2.0.6')
assert_equal(true, section.start_with?('### Added'), "starts at the first subsection")
assert_equal(true, section.include?('Undo and Hint assists'), "includes its own items")
assert_equal(false, section.include?('Background audio'), "stops before the next version")
assert_equal(false, section.include?('## ['), "does not include the next heading")

# The last section is the one that can run away to end of file. Without the
# link-footer terminator it swallows the whole compare-link block, which would
# then appear verbatim in the GitHub Release body.
last = extract_changelog_section(CHANGELOG, '1.0')
assert_equal(true, last.include?('First release'), "the final section is extracted")
assert_equal(false, last.include?('[Unreleased]:'), "the final section stops at the link footer")
assert_equal(false, last.include?('https://'), "no compare links leak into the notes")

unreleased = extract_changelog_section(CHANGELOG, 'Unreleased')
assert_equal(true, unreleased.include?('Something pending'), "[Unreleased] is extractable")

assert_equal(nil, extract_changelog_section(CHANGELOG, '9.9.9'), "an absent version returns nil")

empty = "# Changelog\n\n## [3.0.0] - 2026-09-01\n\n## [2.0.0] - 2026-01-01\n\n### Added\n- Thing\n"
assert_equal(nil, extract_changelog_section(empty, '3.0.0'), "an empty section returns nil")

# The version is interpolated into a regex, so "1.0" must not match "1x0".
dotted = "## [1x0] - 2026-01-01\n\n### Added\n- Wrong section\n"
assert_equal(nil, extract_changelog_section(dotted, '1.0'), "the dot in a version is not a wildcard")

# Trailing whitespace would show up as blank lines at the end of the release body.
assert_equal(section, section.strip, "the result is trimmed")

puts
puts "_resolve_bump"

assert_equal('2.0.7', _resolve_bump(current: '2.0.6', bump_type: 'patch'), "patch bumps the third component")
assert_equal('2.1.0', _resolve_bump(current: '2.0.6', bump_type: 'minor'), "minor resets patch")
assert_equal('3.0.0', _resolve_bump(current: '2.0.6', bump_type: 'major'), "major resets minor and patch")
assert_equal('4.5.6', _resolve_bump(current: '2.0.6', bump_type: '4.5.6'), "an explicit semver is used as-is")

# MARKETING_VERSION is "1.0" on the test targets, so short versions are real.
assert_equal('1.0.1', _resolve_bump(current: '1.0', bump_type: 'patch'), "a two-component version is padded")
assert_equal('1.1.0', _resolve_bump(current: '1.0', bump_type: 'minor'), "a two-component version bumps minor")

assert_equal('2.0.10', _resolve_bump(current: '2.0.9', bump_type: 'patch'), "patch crosses into double digits")

# A typo must not silently downgrade the version and tag a release for it.
assert_raises("an unknown bump type is rejected")   { _resolve_bump(current: '2.0.6', bump_type: 'pathc') }
assert_raises("a non-semver string is rejected")    { _resolve_bump(current: '2.0.6', bump_type: '2.0') }
assert_raises("an empty bump type is rejected")     { _resolve_bump(current: '2.0.6', bump_type: '') }

puts
if $fail.zero?
  puts "All #{$pass} checks passed."
  exit 0
end
puts "#{$fail} failed, #{$pass} passed."
exit 1

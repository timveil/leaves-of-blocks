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

require 'tmpdir'
require 'fileutils'
require 'open3'

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
puts "_parse_unreleased_subsections"

# The template [Unreleased] block ships empty subsections, so this shape is the
# normal one rather than an edge case.
with_empty = <<~MD
  ## [Unreleased]

  ### Added

  ### Changed
  - A changed thing

  ### Fixed
  - A fixed thing

  ## [1.0] - 2020-01-01

  ### Added
  - Old thing
MD

parsed = _parse_unreleased_subsections(with_empty)
assert_equal(['Changed', 'Fixed'], parsed.keys.sort, "empty subsections are omitted, not populated")
assert_equal(['A changed thing'], parsed['Changed'], "items stay under their own heading")
assert_equal(['A fixed thing'], parsed['Fixed'], "the last subsection is parsed")
assert_equal(false, parsed.key?('Added'), "an empty subsection does not absorb the next one")

populated = <<~MD
  ## [Unreleased]

  ### Added
  - An added thing

  ### Changed
  - A changed thing

  ## [1.0] - 2020-01-01
MD
assert_equal(['Added', 'Changed'], _parse_unreleased_subsections(populated).keys.sort, "fully populated sections parse")

# Non-standard headings are preserved -- that is what stops a hand-written
# "Security" section from being dropped at release time.
custom = "## [Unreleased]\n\n### Security\n- Patched a thing\n\n## [1.0] - 2020-01-01\n"
assert_equal(['Patched a thing'], _parse_unreleased_subsections(custom)['Security'], "custom headings survive")

assert_equal({}, _parse_unreleased_subsections("# Changelog\n\n## [1.0] - 2020-01-01\n"), "no [Unreleased] yields nothing")
assert_equal({}, _parse_unreleased_subsections("## [Unreleased]\n\n### Added\n\n### Fixed\n\n## [1.0] - 2020-01-01\n"), "an entirely empty block yields nothing")

# The block must not run past its own section into the released history.
bleed = "## [Unreleased]\n\n### Added\n- Pending\n\n## [1.0] - 2020-01-01\n\n### Added\n- Shipped\n"
assert_equal(['Pending'], _parse_unreleased_subsections(bleed)['Added'], "parsing stops at the next version heading")

puts
puts "TestFlight notes"

notes = format_testflight_notes({ 'Added' => ['One', 'Two'], 'Fixed' => ['Three'] })
assert_equal("Added\n• One\n• Two\n\nFixed\n• Three", notes, "sections render as headed bullet lists")
assert_equal(nil, format_testflight_notes({}), "no sections yields nil, not an empty string")
assert_equal(nil, format_testflight_notes(nil), "nil sections yields nil")
assert_equal(nil, format_testflight_notes({ 'Added' => [] }), "a section with no items yields nil")
assert_equal("Fixed\n• Real", format_testflight_notes({ 'Added' => [], 'Fixed' => ['Real'] }), "empty sections are skipped, populated ones kept")

commits = [
  'feat(grid): Add a hint button (#12)',
  'chore: Bump a dependency',
  'fix: Stop the crash on rotate',
  'ci(codeql): Speed up analysis',
  'docs: Explain something'
]
assert_equal("• Add a hint button\n• Stop the crash on rotate", format_commit_notes(commits),
             "only tester-relevant types survive, prefixes and PR numbers stripped")
assert_equal(nil, format_commit_notes(['chore: Tooling', 'ci: More tooling']), "a tooling-only run yields nil")
assert_equal(nil, format_commit_notes([]), "no commits yields nil")
assert_equal(nil, format_commit_notes(nil), "nil commits yields nil")
assert_equal("• Something", format_commit_notes(['feat!: Something']), "a breaking-change marker is handled")
assert_equal("• Keep (#12) inside", format_commit_notes(['fix: Keep (#12) inside']), "only a trailing PR number is stripped")
assert_equal(nil, format_commit_notes(['Not conventional at all']), "an unparseable subject is skipped")

short = "Added\n• A thing"
assert_equal(short, truncate_testflight_notes(short), "text under the limit is untouched")
assert_equal(nil, truncate_testflight_notes(nil), "nil passes through")

long = 'x' * (TESTFLIGHT_NOTES_LIMIT + 500)
truncated = truncate_testflight_notes(long)
assert_equal(true, truncated.length <= TESTFLIGHT_NOTES_LIMIT, "output never exceeds the limit")
assert_equal(true, truncated.end_with?('(truncated)'), "truncation is announced")

exact = 'x' * TESTFLIGHT_NOTES_LIMIT
assert_equal(exact, truncate_testflight_notes(exact), "text exactly at the limit is untouched")
assert_equal(true, truncate_testflight_notes('x' * 20, limit: 5).length <= 5, "a limit shorter than the marker still fits")

puts
puts "commit_subjects_since_last_tag"

# Exercised against real repositories: this is where the range is built, and
# the previous version substituted a sentinel revision for the no-tag case.
Dir.mktmpdir do |dir|
  run = lambda do |*args|
    _out, _err, status = Open3.capture3('git', '-C', dir, *args)
    raise "git #{args.join(' ')} failed" unless status.success?
  end

  run.call('init', '-q', '.')
  run.call('config', 'user.email', 'test@example.com')
  run.call('config', 'user.name', 'Test')
  run.call('commit', '-q', '--allow-empty', '-m', 'feat: Before the tag')

  Dir.chdir(dir) do
    assert_equal(['feat: Before the tag'], commit_subjects_since_last_tag,
                 "with no tags, every commit is returned")
  end

  run.call('tag', 'v1.0.0')
  run.call('commit', '-q', '--allow-empty', '-m', 'fix: After the tag')
  run.call('commit', '-q', '--allow-empty', '-m', 'chore: Also after')

  Dir.chdir(dir) do
    subjects = commit_subjects_since_last_tag
    assert_equal(['fix: After the tag', 'chore: Also after'].sort, subjects.sort,
                 "with a tag, only commits after it are returned")
    assert_equal(false, subjects.include?('feat: Before the tag'),
                 "the tagged commit itself is excluded")
    assert_equal("• After the tag", format_commit_notes(subjects),
                 "the range feeds through to tester-facing notes")
  end
end

# Outside a repository entirely, git fails and the helper stays quiet.
Dir.mktmpdir do |dir|
  Dir.chdir(dir) do
    assert_equal([], commit_subjects_since_last_tag, "outside a git repository, no subjects and no raise")
  end
end

puts
puts "_preflight row classification"

rows = []
_preflight(rows, 'good') { 'a value' }
assert_equal([['good', :ok, 'a value']], rows, "a value is recorded as ok")

rows = []
_preflight(rows, 'boom') { raise 'something broke' }
assert_equal(:fail, rows[0][1], "a raise is recorded as a failure")
assert_equal('something broke', rows[0][2], "the message is kept")

# A check that raises must not abort the run: three problems should be
# reported together, not discovered one release attempt at a time.
rows = []
_preflight(rows, 'one') { raise 'first' }
_preflight(rows, 'two') { raise 'second' }
_preflight(rows, 'three') { 'fine' }
assert_equal(3, rows.length, "a failing check does not stop later ones")
assert_equal([:fail, :fail, :ok], rows.map { |r| r[1] }, "each is classified independently")

# Only the first line of a multi-line error, so one failure cannot flood the table.
rows = []
_preflight(rows, 'multi') { raise "headline\nstack frame\nmore detail" }
assert_equal('headline', rows[0][2], "only the first line of an error is shown")

rows = []
_preflight(rows, 'nothing') { nil }
assert_equal(:fail, rows[0][1], "nil is a failure by default")
assert_equal('not available', rows[0][2], "and says so")

rows = []
_preflight(rows, 'empty') { '' }
assert_equal(:fail, rows[0][1], "an empty string is a failure, not a pass")

# gh is optional because publish_github_release soft-fails; its absence must
# warn rather than read as a blocked release.
rows = []
_preflight(rows, 'optional', severity: :warn) { nil }
assert_equal(:warn, rows[0][1], "a missing optional check warns instead of failing")

rows = []
_preflight(rows, 'optional', severity: :warn) { raise 'gone' }
assert_equal(:warn, rows[0][1], "an optional check that raises also only warns")

puts
puts "executable_in_path?"

Dir.mktmpdir do |dir|
  original_path = ENV['PATH']
  begin
    tool = File.join(dir, 'faketool')
    File.write(tool, "#!/bin/sh\nexit 0\n")

    ENV['PATH'] = dir
    File.chmod(0o644, tool)
    assert_equal(false, executable_in_path?('faketool'), "a non-executable file is not found")

    File.chmod(0o755, tool)
    assert_equal(true, executable_in_path?('faketool'), "an executable on PATH is found")
    assert_equal(false, executable_in_path?('nope'), "an absent name is not found")

    # A directory sharing the name must not count as the executable.
    subdir = File.join(dir, 'adir')
    FileUtils.mkdir_p(subdir)
    assert_equal(false, executable_in_path?('adir'), "a directory is not mistaken for an executable")

    # Empty PATH entries mean "current directory" to some tools; skip them
    # rather than resolving relative to wherever the lane happens to run.
    ENV['PATH'] = "::#{dir}"
    assert_equal(true, executable_in_path?('faketool'), "empty PATH entries are skipped")

    ENV['PATH'] = ''
    assert_equal(false, executable_in_path?('faketool'), "an empty PATH finds nothing")
  ensure
    ENV['PATH'] = original_path
  end
end

# The real thing, as a sanity check that the scan agrees with reality.
assert_equal(true, executable_in_path?('ruby'), "ruby is found on the real PATH")

puts
if $fail.zero?
  puts "All #{$pass} checks passed."
  exit 0
end
puts "#{$fail} failed, #{$pass} passed."
exit 1
